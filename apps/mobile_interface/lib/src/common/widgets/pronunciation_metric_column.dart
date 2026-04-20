import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/constants.dart';

/// A flat score column used in the hero metric row on results pages.
///
/// Displays a bold numeric score and a label beneath it, coloured by
/// performance tier (≥ 85 → success, ≥ 60 → action, else failure).
class PronunciationMetricColumn extends StatelessWidget {
  const PronunciationMetricColumn({
    super.key,
    required this.label,
    required this.score,
  });

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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${score.round().clamp(0, 100)}',
              style: GoogleFonts.inter(
                color: _color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.publicSans(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
