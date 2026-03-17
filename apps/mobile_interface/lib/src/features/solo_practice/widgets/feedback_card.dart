import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants.dart';
import '../models/pronunciation_feedback.dart';

/// Inline feedback card shown after the user submits a recording.
/// Displays word-level and phoneme-level scores; tap a word to see phoneme breakdown.
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.onRetry,
    required this.onNext,
  });

  final PronunciationFeedbackMock feedback;
  /// Re-record and regrade the same item from scratch.
  final VoidCallback onRetry;
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
    Color wordColor(double? accuracy) {
      if (accuracy == null) return AppColors.textPrimary;
      if (accuracy >= 85) return AppColors.success; // green
      if (accuracy >= 60) return AppColors.action; // yellow / orange
      return AppColors.failure; // red
    }

    // Same thresholds as [wordColor], but used for individual phonemes so
    // users can see which sounds inside a word are strong vs weak.
    Color phonemeColor(double? accuracy) {
      if (accuracy == null) return AppColors.textPrimary;
      if (accuracy >= 85) return AppColors.success;
      if (accuracy >= 60) return AppColors.action;
      return AppColors.failure;
    }

    /// Color for "You said" phoneme: green only when the symbol matches AND
    /// accuracy is high (≥ 85). A correct symbol with a low score still shows
    /// orange/red because the user didn't produce the sound cleanly enough.
    Color userSaidPhonemeColor(PhonemeFeedback p) {
      final said = p.userSaid ?? p.symbol;
      final symbolMatches = said == p.symbol;
      if (symbolMatches && (p.accuracy ?? 0) >= 85) return AppColors.success;
      // Symbol wrong or accuracy too low — use score-based color, but never
      // promote to green (treat it as orange at best).
      final c = phonemeColor(p.accuracy);
      return c == AppColors.success ? AppColors.action : c;
    }

    /// Show a phoneme-detail popup for a single phoneme [symbol].
    /// Displays the symbol, its instruction from [phonemeInstructions], and
    /// the score chip. Opened when the user taps any phoneme chip.
    void showPhonemeDetailDialog({
      required BuildContext parentContext,
      required String symbol,
      double? accuracy,
      Color? chipColor,
    }) {
      final instruction = phonemeInstructions[symbol.toLowerCase()];
      showDialog<void>(
        context: parentContext,
        builder: (detailContext) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(AppRadii.sm),
                  ),
                  child: Text(
                    symbol,
                    style: GoogleFonts.inter(
                      color: chipColor ?? AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (accuracy != null) ...[
                  const SizedBox(width: 10),
                  Text(
                    '${accuracy.round()}',
                    style: GoogleFonts.inter(
                      color: chipColor ?? AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
            content: instruction == null
                ? Text('No instruction available for "$symbol".', style: bodyStyle)
                : Text(instruction, style: bodyStyle),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(detailContext).pop(),
                child: const Text('Got it'),
              ),
            ],
          );
        },
      );
    }

    /// Show a popup listing phonemes for a given [word]: top row = what the
    /// user said (detected), bottom row = what they should have said (reference).
    /// Tap any phoneme chip to see its full articulation instruction.
    void showPhonemeDialog(WordFeedback word) {
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
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'You said:',
                        style: bodyStyle.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in word.phonemes)
                            ActionChip(
                              onPressed: () => showPhonemeDetailDialog(
                                parentContext: dialogContext,
                                symbol: p.userSaid ?? p.symbol,
                                accuracy: p.accuracy,
                                chipColor: userSaidPhonemeColor(p),
                              ),
                              label: Text(
                                p.userSaid ?? p.symbol,
                                style: bodyStyle.copyWith(
                                  color: userSaidPhonemeColor(p),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppColors.inputFill,
                              shape: StadiumBorder(
                                side: BorderSide(color: AppColors.border),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Should be:',
                        style: bodyStyle.copyWith(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final p in word.phonemes)
                            ActionChip(
                              onPressed: () => showPhonemeDetailDialog(
                                parentContext: dialogContext,
                                symbol: p.symbol,
                                chipColor: AppColors.textPrimary,
                              ),
                              label: Text(
                                p.symbol,
                                style: bodyStyle.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              backgroundColor: AppColors.inputFill,
                              shape: StadiumBorder(
                                side: BorderSide(color: AppColors.border),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap any phoneme for how to pronounce it.',
                        style: bodyStyle.copyWith(fontSize: 11, color: AppColors.textSecondary),
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
                    onPressed: () => showPhonemeDialog(w),
                    backgroundColor: AppColors.inputFill,
                    shape: StadiumBorder(
                      side: BorderSide(color: AppColors.border),
                    ),
                    label: Text(
                      w.text,
                      style: bodyStyle.copyWith(
                        color: wordColor(w.accuracy),
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
              ScoreChip(label: 'Accuracy', score: feedback.accuracyScore, style: scoreStyle, bodyStyle: bodyStyle),
              ScoreChip(label: 'Fluency', score: feedback.fluencyScore, style: scoreStyle, bodyStyle: bodyStyle),
              ScoreChip(label: 'Complete', score: feedback.completenessScore, style: scoreStyle, bodyStyle: bodyStyle),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Text(
                    'Try Again',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary).copyWith(inherit: false),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
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
        ],
      ),
    );
  }
}

/// Small chip showing a score label and numeric value (e.g. Accuracy: 85).
class ScoreChip extends StatelessWidget {
  const ScoreChip({
    super.key,
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
