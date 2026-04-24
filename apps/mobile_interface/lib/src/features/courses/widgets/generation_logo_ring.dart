import 'package:flutter/material.dart';

import '../../../app/constants.dart';

/// Logo + ring used on course generation and onboarding seeding loading states.
class GenerationLogoRing extends StatelessWidget {
  const GenerationLogoRing({
    super.key,
    required this.color,
    required this.loading,
  });

  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.9),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          if (loading)
            const SizedBox(
              width: 148,
              height: 148,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                backgroundColor: Colors.transparent,
              ),
            ),
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBg,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                'assets/images/accend_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.school_rounded,
                  color: color,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
