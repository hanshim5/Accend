import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants.dart';
import '../models/pronunciation_feedback.dart';
import 'feedback_card.dart';

/// Renders [referenceText] as a color-coded, tappable sentence.
///
/// Each word is colored by its pronunciation accuracy (green / orange / red)
/// derived from [feedback.words]. Tapping a word opens the phoneme drill-down
/// dialog via [showWordPhonemeDialog].
///
/// Alignment is done sequentially: each whitespace-separated token in
/// [referenceText] is matched to the next [WordFeedback] entry by normalized
/// string comparison (case- and punctuation-insensitive). Unmatched tokens
/// are rendered in the default text color and are not tappable.
class InteractiveFeedbackSentence extends StatelessWidget {
  const InteractiveFeedbackSentence({
    super.key,
    required this.referenceText,
    required this.feedback,
    this.textStyle,
  });

  final String referenceText;
  final PronunciationFeedbackMock feedback;

  /// Base style for all words. Defaults to a 24 sp PublicSans regular weight.
  final TextStyle? textStyle;

  /// Strips everything except letters, digits, apostrophes, and hyphens so
  /// that "juice." matches the API token "juice".
  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9'''\-]"), '');

  /// Pairs each token from [referenceText] with its [WordFeedback] entry.
  ///
  /// Matching walks [feedback.words] sequentially. If the normalized token
  /// doesn't match the current word, one look-ahead is attempted to handle a
  /// single ASR insertion/deletion. Unmatched tokens receive a null entry.
  List<(String, WordFeedback?)> _alignTokens() {
    final tokens = referenceText
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();

    final words = feedback.words;
    int wi = 0;

    bool matches(String token, WordFeedback w) {
      final nt = _normalize(token);
      final nw = _normalize(w.text);
      return nt == nw || nt.contains(nw) || nw.contains(nt);
    }

    return tokens.map((token) {
      if (wi < words.length) {
        if (matches(token, words[wi])) {
          return (token, words[wi++]);
        }
        // One-step look-ahead for insertion/deletion mismatches.
        if (wi + 1 < words.length && matches(token, words[wi + 1])) {
          wi++; // skip the mismatched entry
          return (token, words[wi++]);
        }
      }
      return (token, null as WordFeedback?);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final base = textStyle ??
        GoogleFonts.publicSans(
          fontSize: 24,
          fontWeight: FontWeight.w500,
        );

    final pairs = _alignTokens();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 6,
      children: [
        for (final (token, wf) in pairs)
          GestureDetector(
            onTap: wf != null ? () => showWordPhonemeDialog(context, wf) : null,
            child: Text(
              token,
              style: base.copyWith(
                color: wf != null
                    ? strictWordColor(wf)
                    : AppColors.textPrimary,
                // Subtle underline hints that tappable words are interactive.
                decoration: wf != null
                    ? TextDecoration.underline
                    : TextDecoration.none,
                decorationColor: wf != null
                    ? strictWordColor(wf).withOpacity(0.5)
                    : null,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          ),
      ],
    );
  }
}
