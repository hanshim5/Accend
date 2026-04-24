import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../../../common/models/pronunciation_feedback.dart';

/// API gateway base URL used for local development.
///
/// Prefers the shared GATEWAY_URL from assets/.env.mobile so physical devices,
/// emulators, and adb reverse can all be configured without changing code.
///
/// - Android emulator cannot reach `localhost`; the host machine is at 10.0.2.2.
/// - iOS simulator and desktop can use localhost directly.
/// - In production this should be injected from configuration, not hard-coded.
String get _gatewayBaseUrl =>
  (dotenv.env['GATEWAY_URL']?.isNotEmpty ?? false)
    ? dotenv.env['GATEWAY_URL']!
    : (Platform.isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080');

/// Returns mock feedback for the feedback card (fallback when API fails or is unused).
///
/// This keeps the solo practice flow interactive when:
/// - The gateway / pronunciation-feedback service is not running.
/// - The network request fails for any reason.
///
/// The mock uses [referenceText] to:
/// - Generate per-word "scores" with mild variation.
/// - Generate per-phoneme "scores" by splitting each word into characters.
PronunciationFeedbackMock getMockFeedback(String referenceText) {
  // --- Base score ---------------------------------------------------------
  // Seed a "base" in the range [70, 95) using the current millisecond so
  // repeated calls look slightly different without needing a real RNG.
  final base = 70.0 + (DateTime.now().millisecond % 25);

  // --- Strip punctuation --------------------------------------------------
  // Split on whitespace, then discard everything except letters, digits, and
  // apostrophes. This gives clean word tokens ("it's" stays intact, trailing
  // commas/periods are dropped) so the chip labels match what the user read.
  final rawTokens = referenceText.split(RegExp(r'\s+'));
  final tokens = <String>[];
  for (final token in rawTokens) {
    final buffer = StringBuffer();
    for (var i = 0; i < token.length; i++) {
      final ch = token[i];
      final isLetterOrDigit =
          (ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57) || // 0-9
          (ch.codeUnitAt(0) >= 65 && ch.codeUnitAt(0) <= 90) || // A-Z
          (ch.codeUnitAt(0) >= 97 && ch.codeUnitAt(0) <= 122); // a-z
      if (isLetterOrDigit || ch == '\'') {
        buffer.write(ch);
      }
    }
    final cleaned = buffer.toString();
    if (cleaned.isNotEmpty) {
      tokens.add(cleaned);
    }
  }

  // --- Build per-word (and per-character) mock feedback -------------------
  // Each word gets a score offset by a deterministic jitter so the chips
  // aren't all the same colour. Phonemes are approximated by splitting the
  // word into individual characters — real phoneme data only comes from the
  // API, but this keeps the phoneme-detail dialog functional offline.
  final words = <WordFeedback>[];
  for (var i = 0; i < tokens.length; i++) {
    final jitter = (i * 7) % 25;
    final score = (base + jitter).clamp(40.0, 100.0);
    final phonemes = <PhonemeFeedback>[];
    final word = tokens[i];
    for (var j = 0; j < word.length; j++) {
      final pJitter = ((i + 1) * (j + 3) * 5) % 25;
      final pScore = (base + pJitter).clamp(40.0, 100.0);
      final ch = word[j];
      phonemes.add(PhonemeFeedback(symbol: ch, accuracy: pScore.toDouble(), userSaid: ch));
    }
    words.add(
      WordFeedback(
        text: word,
        accuracy: score.toDouble(),
        phonemes: phonemes,
      ),
    );
  }

  // --- Assemble top-level result ------------------------------------------
  // Scores are intentionally "reasonable" so the UI looks believable, but
  // they carry no real diagnostic value — only real API data should be acted on.
  return PronunciationFeedbackMock(
    accuracyScore: base + (DateTime.now().second % 15),
    fluencyScore: (base + 5).clamp(0.0, 100.0),
    completenessScore: (base + 8).clamp(0.0, 100.0),
    pronScore: (base + 10).clamp(0.0, 100.0),
    summary: 'Keep practicing the "th" sounds for even clearer speech.',
    words: words,
  );
}

/// Calls the API gateway `POST /pronunciation/assess` with the given audio
/// bytes and reference text.
///
/// Returns:
/// - Parsed [PronunciationFeedbackMock] (using real JSON) on success.
/// - `null` on any error (network / non-200 / parsing), allowing caller to
///   fall back to [getMockFeedback].
///
/// [accessToken] is a Supabase JWT; when null and the gateway does not allow
/// anonymous access, the call will 401.
Future<PronunciationFeedbackMock?> fetchPronunciationFeedback({
  required List<int> audioBytes,
  required String referenceText,
  String? accessToken,
}) async {
  // --- Build multipart request --------------------------------------------
  // The gateway expects `reference_text` as a plain field and the WAV as a
  // file part named `audio`. The filename is arbitrary; the backend ignores it.
  final uri = Uri.parse('$_gatewayBaseUrl/pronunciation/assess');
  final request = http.MultipartRequest('POST', uri);
  request.fields['reference_text'] = referenceText;
  request.files.add(http.MultipartFile.fromBytes(
    'audio',
    audioBytes,
    filename: 'testaudio.wav',
  ));
  // Attach the Supabase JWT so the gateway can authenticate the request.
  // Omit the header entirely when no token is available rather than sending
  // an empty value, which some middleware treats as a malformed credential.
  if (accessToken != null && accessToken.isNotEmpty) {
    request.headers['Authorization'] = 'Bearer $accessToken';
  }

  // --- Send and handle response -------------------------------------------
  // Any non-200 or network error returns null; the controller will fall back
  // to getMockFeedback so the UI never blocks on a failed API call.
  try {
    final streamed = await request.send().timeout(const Duration(seconds: 15));
    final response = await http.Response.fromStream(streamed).timeout(
      const Duration(seconds: 15),
    );
    if (response.statusCode != 200) return null;
    return _feedbackFromAssessmentJson(response.body);
  } catch (_) {
    return null;
  }
}

/// Parse pronunciation-feedback JSON into [PronunciationFeedbackMock].
///
/// Expects the cleaned microservice payload:
/// {
///   "summary": { accuracy, fluency, completeness, pronScore },
///   "words": [
///     {
///       "text": "...",
///       "accuracy": ...,
///       "errorType": "...",
///       "phonemes": [{ "symbol": "th", "accuracy": ... }, ...]
///     },
///     ...
///   ]
/// }
PronunciationFeedbackMock? _feedbackFromAssessmentJson(String body) {
  try {
    // --- Top-level summary scores -----------------------------------------
    // The `summary` object is required; its three core fields (accuracy,
    // fluency, completeness) must be present or we treat the response as
    // invalid and return null so the caller falls back to mock data.
    final map = jsonDecode(body) as Map<String, dynamic>;
    final summary = map['summary'] as Map<String, dynamic>?;
    if (summary == null) return null;

    final accuracy = (summary['accuracy'] as num?)?.toDouble();
    final fluency = (summary['fluency'] as num?)?.toDouble();
    final completeness = (summary['completeness'] as num?)?.toDouble();
    final pronScore = (summary['pronScore'] as num?)?.toDouble();

    // --- Word list --------------------------------------------------------
    // Walk each word entry, skipping any that are malformed or have no text.
    // For each word, walk its nested phoneme list and store the detected
    // phoneme (`user_said`) alongside the expected symbol so the UI can show
    // "You said / Should be" comparisons.
    final wordsJson = map['words'] as List<dynamic>? ?? const [];
    final words = <WordFeedback>[];
    for (final item in wordsJson) {
      if (item is! Map<String, dynamic>) continue;
      final text = (item['text'] as String?) ?? '';
      if (text.isEmpty) continue;
      final accuracyVal = (item['accuracy'] as num?)?.toDouble();
      final errorType = item['errorType'] as String?;

      final phonemesJson = item['phonemes'] as List<dynamic>? ?? const [];
      final phonemes = <PhonemeFeedback>[];
      for (final p in phonemesJson) {
        if (p is! Map<String, dynamic>) continue;
        final symbol = (p['symbol'] as String?) ?? '';
        if (symbol.isEmpty) continue;
        final pAccuracy = (p['accuracy'] as num?)?.toDouble();
        final userSaid = p['user_said'] as String?;
        // Normalise empty strings to null so callers can use a simple null
        // check rather than also guarding against "".
        phonemes.add(
          PhonemeFeedback(
            symbol: symbol,
            accuracy: pAccuracy,
            userSaid: userSaid?.isNotEmpty == true ? userSaid : null,
          ),
        );
      }

      words.add(
        WordFeedback(
          text: text,
          accuracy: accuracyVal,
          errorType: errorType,
          phonemes: phonemes,
        ),
      );
    }

    // --- Validate and assemble result -------------------------------------
    // Guard here (after building the word list) rather than early-returning
    // above, so we can still surface partial word data in a future extension.
    if (accuracy == null || fluency == null || completeness == null) return null;

    final feedbackSessionId = map['feedback_session_id'] as String?;

    return PronunciationFeedbackMock(
      accuracyScore: accuracy,
      fluencyScore: fluency,
      completenessScore: completeness,
      pronScore: pronScore,
      summary: 'Keep practicing for even clearer speech.',
      words: words,
      feedbackSessionId: feedbackSessionId,
    );
  } catch (_) {
    return null;
  }
}

/// Calls the API gateway `POST /pronunciation/ai-feedback` with the assessment
/// data and session ID, and returns 2–3 Gemini-generated suggestion strings.
///
/// Returns null on any error so callers can handle gracefully.
Future<List<String>?> fetchAiFeedback({
  required String sessionId,
  required PronunciationFeedbackMock feedback,
  String? accessToken,
}) async {
  final uri = Uri.parse('$_gatewayBaseUrl/pronunciation/ai-feedback');

  // Build the JSON body mirroring the backend AiFeedbackRequest schema.
  final body = jsonEncode({
    'feedback_session_id': sessionId,
    'summary': {
      'accuracy': feedback.accuracyScore,
      'fluency': feedback.fluencyScore,
      'completeness': feedback.completenessScore,
      'pronScore': feedback.pronScore,
    },
    'words': [
      for (final w in feedback.words)
        {
          'text': w.text,
          'accuracy': w.accuracy,
          'errorType': w.errorType,
          'phonemes': [
            for (final p in w.phonemes)
              {
                'symbol': p.symbol,
                'accuracy': p.accuracy,
                'user_said': p.userSaid,
              },
          ],
        },
    ],
  });

  try {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) return null;

    final map = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestions = map['suggestions'] as List<dynamic>?;
    if (suggestions == null) return null;
    return suggestions.map((s) => s.toString()).toList();
  } catch (_) {
    return null;
  }
}
