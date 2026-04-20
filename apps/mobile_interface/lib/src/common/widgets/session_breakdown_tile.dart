import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/constants.dart';
import '../../features/courses/models/lesson_item.dart';
import '../models/pronunciation_feedback.dart';
import 'interactive_feedback_sentence.dart';

/// An expandable tile showing one exercise's score summary.
///
/// Tapping the tile reveals:
/// - The interactive colour-coded sentence (when word-level data is present),
///   where each word is tappable for phoneme drill-down.
/// - A "tap for phoneme feedback" hint.
/// - Three compact mini-score chips (Accuracy / Fluency / Completeness).
///
/// Used on both [PracticeResultsPage] and [GroupSessionResultsPage] so that
/// the pronunciation feedback UI is maintained in exactly one place.
class SessionBreakdownTile extends StatelessWidget {
  const SessionBreakdownTile({
    super.key,
    required this.index,
    required this.item,
    required this.feedback,
  });

  final int index;
  final LessonItem item;
  final PronunciationFeedbackMock feedback;

  double get _overallScore {
    if (feedback.pronScore != null) return feedback.pronScore!;
    return (feedback.accuracyScore +
            feedback.fluencyScore +
            feedback.completenessScore) /
        3;
  }

  Color _scoreColor(double score) {
    if (score >= 85) return AppColors.success;
    if (score >= 60) return AppColors.action;
    return AppColors.failure;
  }

  @override
  Widget build(BuildContext context) {
    final score = _overallScore;
    final color = _scoreColor(score);

    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    return Theme(
      // Remove default ExpansionTile divider lines injected by the theme.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border:
                Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '${score.round()}',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          item.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.publicSans(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Exercise ${index + 1}',
          style: bodyStyle.copyWith(fontSize: 11),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          // ----------------------------------------------------------------
          // Word-level pronunciation feedback
          // ----------------------------------------------------------------
          if (feedback.words.isNotEmpty) ...[
            InteractiveFeedbackSentence(
              referenceText: item.text,
              feedback: feedback,
              textStyle: GoogleFonts.publicSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap any word for phoneme feedback',
              style: bodyStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else ...[
            // No word-level data — show the reference sentence in neutral colour
            // so the tile still has meaningful content when expanded.
            Text(
              item.text,
              style: GoogleFonts.publicSans(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          // ----------------------------------------------------------------
          // Per-phoneme score chips — Accuracy / Fluency / Completeness
          // ----------------------------------------------------------------
          Row(
            children: [
              _MiniScoreChip(
                  label: 'Accuracy', score: feedback.accuracyScore),
              const SizedBox(width: AppSpacing.xs),
              _MiniScoreChip(label: 'Fluency', score: feedback.fluencyScore),
              const SizedBox(width: AppSpacing.xs),
              _MiniScoreChip(
                  label: 'Complete', score: feedback.completenessScore),
            ],
          ),

        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact score chip — private, only used inside SessionBreakdownTile
// ---------------------------------------------------------------------------

class _MiniScoreChip extends StatelessWidget {
  const _MiniScoreChip({required this.label, required this.score});

  final String label;
  final double score;

  Color get _color {
    if (score >= 85) return AppColors.success;
    if (score >= 60) return AppColors.action;
    return AppColors.failure;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${score.round()}',
              style: GoogleFonts.inter(
                color: _color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.publicSans(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
