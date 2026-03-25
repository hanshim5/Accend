import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../controllers/login_controller.dart';
import 'login_error_banner.dart';
import 'login_footer_links.dart';
import 'login_text_field.dart';

class LoginFormCard extends StatelessWidget {
  const LoginFormCard({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ctrl = context.watch<LoginController>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Login',
            style: t.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 18),

          if (ctrl.errorMessage != null) ...[
            LoginErrorBanner(message: ctrl.errorMessage!),
            const SizedBox(height: 14),
          ],

          LoginTextField(
            label: 'Username or Email',
            hintText: 'Enter your username or email',
            controller: ctrl.identifierController,
            enabled: !ctrl.isLoading,
            onChanged: ctrl.onIdentifierChanged,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),

          LoginTextField(
            label: 'Password',
            hintText: 'Enter your password',
            controller: ctrl.passwordController,
            enabled: !ctrl.isLoading,
            onChanged: ctrl.onPasswordChanged,
            obscureText: ctrl.obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => ctrl.isLoading ? null : ctrl.signIn(context),
            suffixIcon: IconButton(
              onPressed: ctrl.isLoading ? null : ctrl.togglePasswordVisibility,
              icon: Icon(
                ctrl.obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: ctrl.isLoading ? null : () => ctrl.signIn(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.action,
                foregroundColor: const Color(0xFF0F172A),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: t.textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: ctrl.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sign In'),
            ),
          ),

          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed:
                  ctrl.isLoading ? null : () => ctrl.forgotPassword(context),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              const Expanded(
                child: Divider(
                  color: AppColors.textSecondary,
                  thickness: 0.7,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  'OR',
                  style: t.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const Expanded(
                child: Divider(
                  color: AppColors.textSecondary,
                  thickness: 0.7,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: ctrl.isLoading
                      ? null
                      : () => ctrl.signInWithGoogle(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: t.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  child: const Text('Google'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: ctrl.isLoading
                      ? null
                      : () => ctrl.signInWithApple(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(36),
                    backgroundColor: AppColors.surface,
                    foregroundColor: AppColors.textPrimary,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: t.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  child: const Text('Apple'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          LoginFooterLinks(
            isLoading: ctrl.isLoading,
            isLoggedIn: ctrl.isLoggedIn,
            onCreateAccount: () => ctrl.goToCreateAccount(context),
            onLogout: () => ctrl.signOut(context),
          ),
        ],
      ),
    );
  }
}