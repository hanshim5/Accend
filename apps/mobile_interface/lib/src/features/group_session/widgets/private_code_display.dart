import 'package:flutter/material.dart';
import '../../../app/constants.dart';

class PrivateCodeDisplay extends StatelessWidget {
  final String code;

  const PrivateCodeDisplay({
  super.key,
  required this.code,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final isNumeric = RegExp(r'^\d+$').hasMatch(code);
    final display = (isNumeric && code.length >= 4) ? '#$code' : code;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 110),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: AppColors.accent2,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          display,
          style: t.textTheme.headlineLarge?.copyWith(
            fontSize: 34,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}