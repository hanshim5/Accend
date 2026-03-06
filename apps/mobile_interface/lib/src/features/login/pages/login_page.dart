import 'package:flutter/material.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/routes.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: t.textTheme.headlineMedium,
                        children: [
                          const TextSpan(text: 'Welcome to '),
                          TextSpan(
                            text: 'Ascension',
                            style: t.textTheme.headlineMedium?.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap to start your journey',
                    style: t.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.onboardingUserInfo),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: const Text('Start Onboarding'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}