import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/constants.dart';
import '../models/pronunciation_feedback.dart';
import 'phoneme_feedback.dart';

/// Renders [referenceText] as a colour-coded, tappable sentence.
///
/// Each word is coloured by its pronunciation accuracy (green / orange / red)
/// derived from [feedback.words]. Tapping a word opens the phoneme drill-down
/// bottom sheet via [showWordPhonemeDialog].
///
/// Alignment is done sequentially: each whitespace-separated token in
/// [referenceText] is matched to the next [WordFeedback] entry by normalised
/// string comparison (case- and punctuation-insensitive). Unmatched tokens
/// are rendered in the default text colour and are not tappable.
class InteractiveFeedbackSentence extends StatelessWidget {
  const InteractiveFeedbackSentence({
    super.key,
    required this.referenceText,
    required this.feedback,
    this.textStyle,
  });

  final String referenceText;
  final PronunciationFeedbackMock feedback;

  /// Base style for all words. Defaults to 24 sp PublicSans regular.
  final TextStyle? textStyle;

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9'''\-]"), '');

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
        if (wi + 1 < words.length && matches(token, words[wi + 1])) {
          wi++;
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
                color: wf != null ? strictWordColor(wf) : AppColors.textPrimary,
                decoration:
                    wf != null ? TextDecoration.underline : TextDecoration.none,
                decorationColor:
                    wf != null ? strictWordColor(wf).withOpacity(0.5) : null,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          ),
      ],
    );
  }
}
