/// Articulation instructions keyed by ARPAbet phoneme symbol.
///
/// Used in the phoneme-detail popup so users know how to physically
/// produce each sound. Keys are lower-case ARPAbet symbols (e.g. "iy", "p").
const Map<String, String> phonemeInstructions = {
  'iy': 'Spread your lips slightly and raise your tongue high and forward; hold a long "ee" sound like in beet.',
  'ih': 'Keep your tongue high but relaxed and slightly lower than "iy"; make a short "i" like in bit.',
  'eh': 'Lower your tongue to mid level and keep it forward; say "eh" like in bet.',
  'ae': 'Open your mouth wide and keep your tongue low and forward; say "a" like in bat.',
  'aa': 'Drop your jaw and keep your tongue low and back; produce a broad "ah" like in father.',
  'ah': 'Relax your mouth and keep your tongue low and central; say a short "uh" like in but.',
  'ao': 'Round your lips slightly and keep your tongue low and back; say "aw" like in caught.',
  'uh': 'Round your lips a little and keep your tongue high and back; say "u" like in book.',
  'uw': 'Round your lips tightly and raise your tongue high and back; hold "oo" like in boot.',
  'er': 'Curl your tongue slightly upward or bunch it in the middle; make an "er" sound like in bird.',
  'ax': 'Relax your mouth completely with a neutral tongue position; produce a quick, unstressed "uh" like in sofa.',
  'ey': 'Start with "eh" and glide up to "ee"; say "ay" like in bait.',
  'ay': 'Start with "ah" and glide up to "ee"; say "eye" like in bite.',
  'ow': 'Start with "oh" and glide to "oo"; say "oh" like in boat.',
  'aw': 'Start with "ah" and glide to "oo"; say "ow" like in bout.',
  'oy': 'Start with "aw" and glide to "ee"; say "oy" like in boy.',
  'p':  'Press your lips together, then release a small burst of air; no voice, like in pat.',
  'b':  'Press your lips together and release with voice; like in bat.',
  't':  'Touch the tip of your tongue to the ridge behind your teeth, then release; no voice, like in top.',
  'd':  'Same as "t" but with voice; like in dog.',
  'k':  'Raise the back of your tongue to the soft palate, then release; no voice, like in cat.',
  'g':  'Same as "k" but with voice; like in go.',
  'f':  'Place your top teeth on your bottom lip and blow air; no voice, like in fan.',
  'v':  'Same as "f" but with voice; like in van.',
  'th': 'Put your tongue lightly between your teeth and blow air; no voice, like in think.',
  'dh': 'Same position as "th" but with voice; like in this.',
  's':  'Keep your tongue close to the roof of your mouth and push air through; no voice, like in see.',
  'z':  'Same as "s" but with voice; like in zoo.',
  'sh': 'Round your lips slightly and push air over a raised tongue; no voice, like in she.',
  'zh': 'Same as "sh" but with voice; like the middle sound in measure.',
  'hh': 'Open your mouth and push air out gently from your throat; like in hat.',
  'ch': 'Start with a "t" stop, then release into "sh"; no voice, like in chip.',
  'jh': 'Same as "ch" but with voice; like in jump.',
  'm':  'Close your lips and let air flow through your nose; voiced, like in man.',
  'n':  'Touch your tongue to the ridge behind your teeth and let air flow through your nose; like in no.',
  'ng': 'Raise the back of your tongue to the soft palate and let air flow through your nose; like in sing.',
  'l':  'Touch the tip of your tongue to the ridge behind your teeth and let air flow around the sides; like in lip.',
  'r':  'Curl or bunch your tongue without touching the roof; produce a smooth "r" like in red.',
  'w':  'Round your lips tightly and glide into a vowel; like in we.',
  'y':  'Raise the front of your tongue close to the roof and glide into a vowel; like in yes.',
};

/// Phoneme-level assessment for a single sound within a word.
///
/// Mirrors the `phonemes` array emitted by the pronunciation-feedback
/// microservice: each entry has the expected `symbol`, its `accuracy`,
/// and `userSaid` (top detected phoneme from NBestPhonemes — what the user said).
class PhonemeFeedback {
  final String symbol;
  final double? accuracy;
  /// Phoneme that was detected (what the user said). Null if not available.
  final String? userSaid;

  const PhonemeFeedback({
    required this.symbol,
    this.accuracy,
    this.userSaid,
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
