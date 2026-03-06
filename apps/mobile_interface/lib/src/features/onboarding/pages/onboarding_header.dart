import 'package:flutter/material.dart';
import '../../../app/constants.dart';

/// Topbar (back button + step label + right label)
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

/// Progress bar (fills based on step/totalSteps)
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
    final progress =
        (totalSteps <= 0) ? 0.0 : (step / totalSteps).clamp(0.0, 1.0);

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

/// Question header
class OnboardingQuestionHeader extends StatelessWidget {
  final IconData icon;

  // 3-part header (like "What " + "accent" + " do you want?")
  final String leadingText;
  final String highlightedText;
  final String trailingText;

  final String subheader;

  // colors per part
  final Color? leadingColor;
  final Color? highlightedColor;
  final Color? trailingColor;

  // Icon box aspect ratio (width / height)
  final double iconBoxAspectRatio;
  final double gap;
  final double glowBlur;

  // Tighten icon spacing without editing every page
  final double maxIconBoxWidth;
  final double minIconBoxWidth;

  const OnboardingQuestionHeader({
    super.key,
    IconData? icon,
    required this.leadingText,
    required this.highlightedText,
    this.trailingText = '',
    required this.subheader,
    this.leadingColor,
    this.highlightedColor,
    this.trailingColor,
    this.iconBoxAspectRatio = 81.90 / 62.25,
    this.gap = AppSpacing.xs,
    this.glowBlur = 10,
    this.maxIconBoxWidth = 72,
    this.minIconBoxWidth = 44,
  }) : icon = icon ?? Icons.landscape_outlined;

  @override
  Widget build(BuildContext context) {
    final headingStyle = (Theme.of(context).textTheme.headlineLarge ??
            const TextStyle(fontSize: 40))
        .copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
    );

    final questionSpan = TextSpan(
      children: [
        TextSpan(
          text: leadingText,
          style: headingStyle.copyWith(
            color: leadingColor ?? AppColors.textPrimary,
          ),
        ),
        TextSpan(
          text: highlightedText,
          style: headingStyle.copyWith(
            color: highlightedColor ?? AppColors.accent,
          ),
        ),
        if (trailingText.isNotEmpty)
          TextSpan(
            text: trailingText,
            style: headingStyle.copyWith(
              color: trailingColor ?? AppColors.textPrimary,
            ),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // 1) Measure with capped icon width so text doesn't get squeezed too much
        final double availableForText =
            (constraints.maxWidth - maxIconBoxWidth - gap)
                .clamp(0, constraints.maxWidth);

        final textPainter = TextPainter(
          text: questionSpan,
          textDirection: Directionality.of(context),
          maxLines: 10,
        )..layout(maxWidth: availableForText);

        final double iconBoxHeight = textPainter.height;

        // 2) Icon box width based on total text height
        final double iconBoxWidth = (iconBoxHeight * iconBoxAspectRatio)
            .clamp(minIconBoxWidth, maxIconBoxWidth);

        // 3) Final text width with actual icon width
        final double finalTextWidth =
            (constraints.maxWidth - iconBoxWidth - gap)
                .clamp(0, constraints.maxWidth);

        final finalPainter = TextPainter(
          text: questionSpan,
          textDirection: Directionality.of(context),
          maxLines: 10,
        )..layout(maxWidth: finalTextWidth);

        final double iconSize = finalPainter.height * 1.15;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: finalTextWidth,
                  child: RichText(text: questionSpan),
                ),
                SizedBox(width: gap),
                SizedBox(
                  width: iconBoxWidth,
                  height: finalPainter.height,
                  child: Center(
                    child: Icon(
                      icon,
                      size: iconSize,
                      color: AppColors.accent,
                      shadows: [
                        Shadow(
                          color: AppColors.accent,
                          blurRadius: glowBlur,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              subheader,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        );
      },
    );
  }
}