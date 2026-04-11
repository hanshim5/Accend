import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/auth_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../controllers/login_controller.dart';
import '../widgets/login_form_card.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<LoginController>(
      create: (ctx) => LoginController(
        auth: ctx.read<AuthService>(),
        api: ctx.read<ApiClient>(),
        onboarding: ctx.read<OnboardingController>(),
        home: ctx.read<HomeController>(),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/accend_logo.png',
                    width: 120,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accend',
                    style: t.textTheme.headlineMedium?.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Elevate Language',
                    style: t.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const LoginFormCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}