import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/constants.dart';
import '../models/pronunciation_feedback.dart';

/// Renders [referenceText] as a per-letter red/green highlighted sentence.
///
/// Alignment approach:
/// - Split [referenceText] into whitespace-separated tokens.
/// - Align each token to the next [WordFeedback] entry by a loose normalized match.
/// - For matched words:
///   - If phoneme data exists, distribute phoneme accuracies across the word's letters.
///   - Otherwise, color the whole word by the word accuracy.
///
/// Only two colors are used:
/// - green for "well pronounced" (>= [goodThreshold])
/// - red for "poorly pronounced" (< [goodThreshold])
class LetterFeedbackSentence extends StatelessWidget {
  const LetterFeedbackSentence({
    super.key,
    required this.referenceText,
    required this.feedback,
    this.textStyle,
    this.goodThreshold = 85,
  });

  final String referenceText;
  final PronunciationFeedbackMock feedback;
  final TextStyle? textStyle;
  final double goodThreshold;

  static String _normalize(String s) =>
      s.toLowerCase().replaceAll(RegExp(r"[^a-z0-9'''\-]"), '');

  static bool _isLetterOrDigit(String ch) =>
      RegExp(r'^[a-zA-Z0-9]$').hasMatch(ch);

  Color _redGreen(double? accuracy) {
    final a = accuracy ?? 0;
    return a >= goodThreshold ? AppColors.success : AppColors.failure;
  }

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

  List<TextSpan> _spansForToken(String token, WordFeedback? wf, TextStyle base) {
    if (wf == null) {
      return [TextSpan(text: token, style: base.copyWith(color: AppColors.textPrimary))];
    }

    // Build indices of "letters" in the surface token so punctuation stays default-colored.
    final letterPositions = <int>[];
    final letterPosIndexByCharIndex = <int, int>{};
    for (var i = 0; i < token.length; i++) {
      final ch = token[i];
      if (_isLetterOrDigit(ch) || ch == '\'' || ch == '-') {
        letterPosIndexByCharIndex[i] = letterPositions.length;
        letterPositions.add(i);
      }
    }

    // Fallback: color by word accuracy if no phoneme data.
    if (wf.phonemes.isEmpty || letterPositions.isEmpty) {
      final c = _redGreen(wf.accuracy);
      return [
        TextSpan(
          text: token,
          style: base.copyWith(
            color: c,
            fontWeight: FontWeight.w700,
          ),
        ),
      ];
    }

    final phonemes = wf.phonemes;
    final spans = <TextSpan>[];
    for (var i = 0; i < token.length; i++) {
      final ch = token[i];
      final isLetterish = _isLetterOrDigit(ch) || ch == '\'' || ch == '-';
      if (!isLetterish) {
        spans.add(TextSpan(text: ch, style: base.copyWith(color: AppColors.textPrimary)));
        continue;
      }

      // Distribute phonemes across the letter positions by proportion.
      final lpIndex = letterPosIndexByCharIndex[i] ?? 0;
      final pIndex = ((lpIndex * phonemes.length) / letterPositions.length)
          .floor()
          .clamp(0, phonemes.length - 1);
      spans.add(TextSpan(
        text: ch,
        style: base.copyWith(
          color: _redGreen(phonemes[pIndex].accuracy),
          fontWeight: FontWeight.w700,
        ),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final base = textStyle ??
        GoogleFonts.publicSans(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );

    final pairs = _alignTokens();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      runSpacing: 6,
      children: [
        for (final (token, wf) in pairs)
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: _spansForToken(token, wf, base),
            ),
          ),
      ],
    );
  }
}

