import 'package:flutter/material.dart';
import '../../../app/constants.dart';

class OnboardingLabeledField extends StatelessWidget {
  final String label;
  final String? rightLabel;
  final Color? rightLabelColor;
  final Widget child;

  const OnboardingLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.rightLabel,
    this.rightLabelColor,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: t.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (rightLabel != null)
              Text(
                rightLabel!,
                style: t.textTheme.bodyMedium?.copyWith(
                  color: rightLabelColor ?? AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}