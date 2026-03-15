import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pronunciation_feedback.dart';

/// API gateway base URL used for local development.
///
/// - On Android emulator the host machine is accessible via 10.0.2.2.
/// - On iOS simulator you can use localhost directly.
/// - In production this should be injected from configuration, not hard-coded.
const String _gatewayBaseUrl = 'http://localhost:8080';

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
  final base = 70.0 + (DateTime.now().millisecond % 25);
  // Split text on whitespace to approximate word tokens for the mock.
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
  // Convert cleaned tokens into mock [WordFeedback] entries (with phonemes)
  // so the UI behaves similarly to real assessments.
  final words = <WordFeedback>[];
  for (var i = 0; i < tokens.length; i++) {
    final jitter = (i * 7) % 25;
    final score = (base + jitter).clamp(40.0, 100.0);
    // Simple mock phoneme breakdown: split word into characters so the
    // phoneme dialog has something to display even without real API data.
    final phonemes = <PhonemeFeedback>[];
    final word = tokens[i];
    for (var j = 0; j < word.length; j++) {
      final pJitter = ((i + 1) * (j + 3) * 5) % 25;
      final pScore = (base + pJitter).clamp(40.0, 100.0);
      phonemes.add(PhonemeFeedback(symbol: word[j], accuracy: pScore.toDouble()));
    }
    words.add(
      WordFeedback(
        text: word,
        accuracy: score.toDouble(),
        phonemes: phonemes,
      ),
    );
  }

  // Aggregate mock scores; these are intentionally "reasonable" so the UI
  // looks believable but should not be treated as real assessment data.
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
  // Gateway route that proxies to pronunciation-feedback microservice.
  final uri = Uri.parse('$_gatewayBaseUrl/pronunciation/assess');
  final request = http.MultipartRequest('POST', uri);
  request.fields['reference_text'] = referenceText;
  request.files.add(http.MultipartFile.fromBytes(
    'audio',
    audioBytes,
    filename: 'testaudio.wav',
  ));
  if (accessToken != null && accessToken.isNotEmpty) {
    request.headers['Authorization'] = 'Bearer $accessToken';
  }

  try {
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
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
    final map = jsonDecode(body) as Map<String, dynamic>;
    final summary = map['summary'] as Map<String, dynamic>?;
    if (summary == null) return null;

    final accuracy = (summary['accuracy'] as num?)?.toDouble();
    final fluency = (summary['fluency'] as num?)?.toDouble();
    final completeness = (summary['completeness'] as num?)?.toDouble();
    final pronScore = (summary['pronScore'] as num?)?.toDouble();

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
        phonemes.add(
          PhonemeFeedback(
            symbol: symbol,
            accuracy: pAccuracy,
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

    if (accuracy == null || fluency == null || completeness == null) return null;
    return PronunciationFeedbackMock(
      accuracyScore: accuracy,
      fluencyScore: fluency,
      completenessScore: completeness,
      pronScore: pronScore,
      summary: 'Keep practicing for even clearer speech.',
      words: words,
    );
  } catch (_) {
    return null;
  }
}
