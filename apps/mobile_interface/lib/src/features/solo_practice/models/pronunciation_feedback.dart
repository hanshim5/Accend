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
