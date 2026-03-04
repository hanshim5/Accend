// onboarding_header.dart
import 'package:flutter/material.dart';
import 'package:mobile_interface/src/app/constants.dart';


/// Topbar
class OnboardingTopBar extends StatelessWidget {
  final int step;
  final int totalSteps;
  final String? rightLabel;
  final bool showBack;
  final VoidCallback? onBack;

  const OnboardingTopBar({
    super.key,
    required this.step,
    required this.totalSteps,
    this.rightLabel,
    this.showBack = true,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final right = rightLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button row
        SizedBox(
          height: 48,
          child: Align(
            alignment: Alignment.centerLeft,
            child: showBack
                ? IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                  )
                : const SizedBox.shrink(),
          ),
        ),

        // Step row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP $step OF $totalSteps',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (right != null)
              Text(
                right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Progress bar: uses step/totalSteps, no hardcoded widthFactor
class OnboardingProgressBar extends StatelessWidget {
  final int step;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.step,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (totalSteps <= 0) ? 0.0 : (step / totalSteps).clamp(0.0, 1.0);

    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
    );
  }
}

/// Header block: icon + question (optionally with highlighted part) + subheader
class OnboardingQuestionHeader extends StatelessWidget {
  final IconData icon;
  final String leadingText;
  final String highlightedText;
  final String subheader;

  const OnboardingQuestionHeader({
    super.key,
    required this.icon,
    required this.leadingText,
    required this.highlightedText,
    required this.subheader,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: AppColors.accent, size: 26),
        ),
        const SizedBox(height: AppSpacing.md),

        // Question
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: leadingText,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.textPrimary,
                    ),
              ),
              TextSpan(
                text: highlightedText,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.accent,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Subheader
        Text(
          subheader,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}