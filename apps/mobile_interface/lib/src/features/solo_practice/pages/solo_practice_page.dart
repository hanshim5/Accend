import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../app/constants.dart';

/// API gateway base URL used for local development.
///
/// - On Android emulator the host machine is accessible via 10.0.2.2.
/// - On iOS simulator you can use localhost directly.
/// - In production this should be injected from configuration, not hard-coded.
const String _gatewayBaseUrl = 'http://localhost:8080';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------
// Temporary list of practice prompts used until real lesson data is wired in.
// Each string is a phrase the user will be asked to read aloud.
// TODO: Replace with a real data source (e.g. API response or lesson model).
const List<String> _mockCards = [
  'The quick brown fox jumped over the lazy dog.',
  'She sells seashells by the seashore.',
  'How much wood would a woodchuck chuck?',
  'Peter Piper picked a peck of pickled peppers.',
  'I scream, you scream, we all scream for ice cream.',
  'Red lorry, yellow lorry.',
  'Unique New York, unique New York.',
  'Buffalo buffalo Buffalo buffalo buffalo buffalo Buffalo buffalo.',
  'The sixth sick sheikh\'s sixth sheep\'s sick.',
  'Fresh French fried fish fingers.',
  'I saw Susie sitting in a shoeshine shop.',
  'Lesser leather never weathered wetter weather better.',
  'Can you can a can as a canner can can a can?',
  'Willy\'s real rear wheel.',
  'The thirty-three thieves thought that they thrilled the throne.',
  'Six sleek swans swam swiftly southwards.',
  'How can a clam cram in a clean cream can?',
  'Fuzzy Wuzzy was a bear. Fuzzy Wuzzy had no hair.',
  'Near an ear, a nearer ear, a nearly eerie ear.',
  'You\'ve done it! Great work completing the lesson.',
];

// ---------------------------------------------------------------------------
// Pronunciation feedback model (matches pronunciation-feedback API)
// ---------------------------------------------------------------------------

/// Phoneme-level assessment for a single sound within a word.
///
/// Mirrors the `phonemes` array emitted by the pronunciation-feedback
/// microservice: each entry has the phoneme `symbol` plus its `accuracy`.
class PhonemeFeedback {
  final String symbol;
  final double? accuracy;

  const PhonemeFeedback({
    required this.symbol,
    this.accuracy,
  });
}

/// Word-level pronunciation assessment plus nested phonemes.
///
/// - [text]: surface form of the recognized word.
/// - [accuracy]: Azure-style accuracy score in [0, 100].
/// - [errorType]: Azure miscue classification (e.g. "Omission").
/// - [phonemes]: ordered sequence of [PhonemeFeedback] for drill-down UI.
class WordFeedback {
  final String text;
  final double? accuracy;
  final String? errorType;
  final List<PhonemeFeedback> phonemes;

  const WordFeedback({
    required this.text,
    this.accuracy,
    this.errorType,
    this.phonemes = const [],
  });
}

/// Top-level pronunciation feedback object consumed by the UI.
///
/// Despite the "Mock" suffix, this type is used both for:
/// - Real JSON parsed from the pronunciation-feedback microservice.
/// - Locally generated mock data when the API call fails or is unavailable.
class PronunciationFeedbackMock {
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore;
  final double? pronScore;
  final String? summary; // optional tip
  final List<WordFeedback> words;

  const PronunciationFeedbackMock({
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    this.pronScore,
    this.summary,
    this.words = const [],
  });
}

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

// ---------------------------------------------------------------------------
// Inline feedback card (shown on the page after Submit; explorable in future)
// ---------------------------------------------------------------------------
class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.feedback,
    required this.onNext,
  });

  final PronunciationFeedbackMock feedback;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final headingStyle = GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final scoreStyle = GoogleFonts.inter(
      color: AppColors.accent,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    );

    // Map a word-level accuracy score into a semantic color:
    // - >= 85 → success green (very good)
    // - >= 60 → action orange (needs some work)
    // - else  → failure red (poor)
    Color _wordColor(double? accuracy) {
      if (accuracy == null) return AppColors.textPrimary;
      if (accuracy >= 85) return AppColors.success; // green
      if (accuracy >= 60) return AppColors.action; // yellow / orange
      return AppColors.failure; // red
    }

    // Same thresholds as [_wordColor], but used for individual phonemes so
    // users can see which sounds inside a word are strong vs weak.
    Color _phonemeColor(double? accuracy) {
      if (accuracy == null) return AppColors.textPrimary;
      if (accuracy >= 85) return AppColors.success;
      if (accuracy >= 60) return AppColors.action;
      return AppColors.failure;
    }

    /// Show a popup listing phonemes for a given [word], in the order they
    /// were returned by the microservice. Each phoneme is color-coded based
    /// on its accuracy score to visually guide practice.
    void _showPhonemeDialog(WordFeedback word) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(
              word.text,
              style: headingStyle,
            ),
            content: word.phonemes.isEmpty
                ? Text(
                    'No phoneme data available for this word.',
                    style: bodyStyle,
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final p in word.phonemes)
                        Chip(
                          label: Text(
                            p.symbol,
                            style: bodyStyle.copyWith(
                              color: _phonemeColor(p.accuracy),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: AppColors.inputFill,
                        ),
                    ],
                  ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Pronunciation feedback',
            style: headingStyle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Tap any word below to see your phoneme-level feedback!",
            style: bodyStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          if (feedback.words.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final w in feedback.words)
                  ActionChip(
                    onPressed: () => _showPhonemeDialog(w),
                    backgroundColor: AppColors.inputFill,
                    shape: StadiumBorder(
                      side: BorderSide(color: AppColors.border),
                    ),
                    label: Text(
                      w.text,
                      style: bodyStyle.copyWith(
                        color: _wordColor(w.accuracy),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScoreChip(label: 'Accuracy', score: feedback.accuracyScore, style: scoreStyle, bodyStyle: bodyStyle),
              _ScoreChip(label: 'Fluency', score: feedback.fluencyScore, style: scoreStyle, bodyStyle: bodyStyle),
              _ScoreChip(label: 'Complete', score: feedback.completenessScore, style: scoreStyle, bodyStyle: bodyStyle),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action,
                foregroundColor: const Color(0xFF101828),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              ),
              child: Text(
                'Next',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF101828)).copyWith(inherit: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({
    required this.label,
    required this.score,
    required this.style,
    required this.bodyStyle,
  });

  final String label;
  final double score;
  final TextStyle style;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: bodyStyle.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          '${score.round()}',
          style: style.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
class SoloPracticePage extends StatefulWidget {
  const SoloPracticePage({super.key});

  @override
  State<SoloPracticePage> createState() => _SoloPracticePageState();
}

class _SoloPracticePageState extends State<SoloPracticePage> {
  // Index of the card currently displayed (0-based).
  int _currentCardIndex = 0;

  // Tracks the microphone button's visual/functional state:
  //   0 = idle     → shows mic icon, ready to record
  //   1 = recording → shows record icon, simulates active recording
  //   2 = playback  → shows play icon, allows playing back the "recording"
  int _micStateIndex = 0;

  // Audio player instance used to play back the sample asset in state 2.
  // Disposed in [dispose] to avoid memory leaks.
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Path to the bundled sample audio file (relative to the assets/ directory).
  // Used as a placeholder until real recorded audio is captured and stored.
  static const String _sampleAudioAsset = 'audio/testaudio.wav';

  /// When non-null, the user has submitted and we show inline feedback (explorable later).
  PronunciationFeedbackMock? _currentFeedback;

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------

  /// Total number of practice cards in the current session.
  int get _totalCards => _mockCards.length;

  /// The prompt string for the card currently on screen.
  String get _currentCard => _mockCards[_currentCardIndex];

  /// Progress value between 0.0 and 1.0 for the LinearProgressIndicator.
  /// Based on the current card position (1-indexed so the first card shows
  /// some progress rather than an empty bar).
  double get _progress => (_currentCardIndex + 1) / _totalCards;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    // Always dispose the AudioPlayer when the widget leaves the tree to free
    // the underlying platform audio resources.
    _audioPlayer.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  /// Called when the circular mic button is tapped.
  ///
  /// State machine:
  ///   0 → 1  : Start recording (UI only for now)
  ///   1 → 2  : Stop recording, enter playback-ready state
  ///   2 → 2  : Already in playback state — play the sample audio asset
  Future<void> _onMicPressed() async {
    if (_micStateIndex < 2) {
      // Advance through idle → recording → playback states.
      setState(() {
        _micStateIndex += 1;
      });
    } else {
      // In playback state: stop any currently playing audio, then play
      // the bundled sample asset as a stand-in for the user's recording.
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource(_sampleAudioAsset));
      } catch (_) {
        // Silently swallow errors for now.
        // TODO: surface playback errors to the user in a future iteration.
      }
    }
  }

  /// Resets the mic state back to idle (0) so the user can re-record
  /// without advancing to the next card.
  void _onRetryPressed() {
    setState(() {
      _micStateIndex = 0;
    });
  }

  /// On Submit: call pronunciation/assess with test audio + reference text, then show feedback card.
  Future<void> _onSubmitPressed() async {
    final audioBytes = await rootBundle.load('assets/audio/testaudio.wav');
    final bytes = audioBytes.buffer.asUint8List();
    final referenceText = _currentCard;

    final feedback = await fetchPronunciationFeedback(
      audioBytes: bytes,
      referenceText: referenceText,
      accessToken: null, // TODO: pass Supabase session access token when auth is wired
    );

    if (!mounted) return;
    setState(() {
      _currentFeedback = feedback ?? getMockFeedback(referenceText);
    });
  }

  /// After user taps Next on feedback: clear feedback, go to next card or show completion.
  void _advanceToNextCard() {
    if (_currentCardIndex < _totalCards - 1) {
      setState(() {
        _currentFeedback = null;
        _currentCardIndex += 1;
        _micStateIndex = 0;
      });
    } else {
      setState(() {
        _currentFeedback = null;
        _micStateIndex = 0;
      });
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Lesson Complete! 🎉', style: GoogleFonts.inter(color: AppColors.textPrimary)),
          content: Text(
            'You\'ve completed all $_totalCards exercises. Great work!',
            style: GoogleFonts.publicSans(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text('Finish'),
            ),
          ],
        ),
      );
    }
  }

  /// Returns the correct icon for the mic button based on [_micStateIndex].
  ///   0 → mic icon        (idle)
  ///   1 → record dot      (recording in progress)
  ///   2 → play arrow      (ready to play back)
  IconData _currentMicIcon() {
    switch (_micStateIndex) {
      case 1:
        return Icons.fiber_manual_record;
      case 2:
        return Icons.play_arrow;
      case 0:
      default:
        return Icons.mic;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Show Retry / Submit only when recording is done (state 2) and not
    // currently showing feedback (to keep the flow linear: record → submit
    // → inspect feedback → next).
    final bool showRetrySubmit = _micStateIndex == 2 && _currentFeedback == null;

    // --- Text styles (defined here to keep build readable) ---

    // Used for the lesson title and any bold UI labels.
    final headingStyle = GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );

    // Used for secondary UI text like the card counter and instruction copy.
    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    // Used for the main prompt text displayed on the practice card.
    final promptStyle = GoogleFonts.publicSans(
      color: AppColors.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [

            // -----------------------------------------------------------------
            // TOP SECTION — back button + progress bar
            // -----------------------------------------------------------------
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button: resets session progress before popping the route.
                // This is a placeholder behaviour — in production this would
                // likely prompt the user before discarding their progress.
                IconButton(
                  onPressed: () {
                    setState(() {
                      _currentCardIndex = 0;
                      _micStateIndex = 0;
                      _currentFeedback = null;
                    });
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                // Progress row + bar, constrained to a fixed width for
                // consistent alignment across different screen sizes.
                Center(
                  child: SizedBox(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // Card counter e.g. "3/20"
                            Text('${_currentCardIndex + 1}/$_totalCards', style: bodyStyle),
                            const Spacer(),
                            // Lesson name — hardcoded for now, pass via constructor later.
                            Text('Lesson Title', style: headingStyle),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Progress bar clipped to rounded corners using ClipRRect
                        // because LinearProgressIndicator doesn't natively support
                        // border radius.
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 8,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // -----------------------------------------------------------------
            // MIDDLE SECTION — prompt card or inline feedback card (explorable)
            // -----------------------------------------------------------------
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: _currentFeedback == null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Prompt card: phrase the user should read aloud.
                                  Container(
                                    width: 300,
                                    height: 200,
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(AppRadii.lg),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _currentCard,
                                        textAlign: TextAlign.center,
                                        style: promptStyle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Record yourself using the microphone button below!',
                                    textAlign: TextAlign.center,
                                    style: bodyStyle,
                                  ),
                                ],
                              )
                            : Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.md),
                                child: _FeedbackCard(
                                  feedback: _currentFeedback!,
                                  onNext: _advanceToNextCard,
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // -----------------------------------------------------------------
            // BOTTOM SECTION — Retry / mic button / Submit
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  // Retry button — only visible in playback state (2).
                  // Resets mic to idle so the user can re-record.
                  if (showRetrySubmit) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onRetryPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        ),
                        // inherit: false prevents a TextStyle lerp crash when
                        // Flutter animates the button press. See theme.dart for context.
                        child: Text(
                          'Retry',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary).copyWith(inherit: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],

                  // Mic button — the primary interaction element.
                  // A Container provides the glow shadow; ElevatedButton handles taps.
                  // Color shifts to failure red while recording (state 1).
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          // Glow shifts from accent (idle/playback) to failure (recording).
                          color: _micStateIndex == 1
                              ? AppColors.failure.withOpacity(0.4)
                              : AppColors.accent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // Background: red while recording, accent otherwise.
                        backgroundColor: _micStateIndex == 1
                            ? AppColors.surface
                            : AppColors.accent,
                        foregroundColor: AppColors.primaryBg,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.center,
                      ),
                      onPressed: _onMicPressed,
                      child: Icon(
                        _currentMicIcon(),
                        size: 56,
                        color: _micStateIndex == 1 ? AppColors.failure : AppColors.primaryBg,
                      ),
                    ),
                  ),

                  // Submit button — only visible in playback state (2).
                  // Advances to the next card or shows completion dialog on last card.
                  if (showRetrySubmit) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onSubmitPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.action,
                          foregroundColor: const Color(0xFF101828),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        ),
                        // Label changes to 'Finish' on the final card.
                        // inherit: false prevents TextStyle lerp crash on button press.
                        child: Text(
                          _currentCardIndex == _totalCards - 1 ? 'Finish' : 'Submit',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF101828)).copyWith(inherit: false),
                        ),
                      ),
                    ),
                  ],

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}