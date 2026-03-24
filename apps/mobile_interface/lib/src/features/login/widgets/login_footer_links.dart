import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class LoginFooterLinks extends StatelessWidget {
  const LoginFooterLinks({
    super.key,
    required this.isLoading,
    required this.isLoggedIn,
    required this.onCreateAccount,
    required this.onLogout,
  });

  final bool isLoading;
  final bool isLoggedIn;
  final VoidCallback onCreateAccount;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: t.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            children: [
              const TextSpan(text: "Don't have an account? "),
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: GestureDetector(
                  onTap: isLoading ? null : onCreateAccount,
                  child: Text(
                    'Create Account',
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (isLoggedIn) ...[
          const SizedBox(height: 12),
          TextButton(
            onPressed: isLoading ? null : onLogout,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.failure,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ],
    );
  }
}