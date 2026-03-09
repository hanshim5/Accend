import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/routes.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final auth = context.read<AuthService>();

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception("Email and password are required");
      }

      await auth.signIn(email: email, password: password);

      if (!mounted) return;

      // After login, go to Courses (or MainShell later)
      Navigator.pushReplacementNamed(context, AppRoutes.courses);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signOut() async {
    final auth = context.read<AuthService>();

    setState(() {
      _error = null;
      _isLoading = true;
    });

    try {
      await auth.signOut();
      if (!mounted) return;

      // Stay on login page; clear fields for convenience
      _emailCtrl.clear();
      _passwordCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Logged out")),
      );
      setState(() {});
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final auth = context.watch<AuthService>();
    final isLoggedIn = auth.currentSession != null;

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
                  // Header
                  RichText(
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
                  const SizedBox(height: 12),
                  Text(
                    'Sign in to continue',
                    style: t.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 28),

                  // Error
                  if (_error != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        border: Border.all(color: AppColors.failure),
                      ),
                      child: Text(
                        _error!,
                        style: t.textTheme.bodyMedium?.copyWith(
                          color: AppColors.failure,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Email
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      hintText: "you@example.com",
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _isLoading ? null : _signIn(),
                    decoration: const InputDecoration(
                      labelText: "Password",
                      hintText: "••••••••",
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Login button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _signIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.textPrimary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Log In"),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Logout (only if logged in)
                  if (isLoggedIn) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _signOut,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.failure),
                          foregroundColor: AppColors.failure,
                        ),
                        child: const Text("Log Out"),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Keep onboarding button (your existing flow)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushNamed(
                                context,
                                AppRoutes.onboardingUserInfo,
                              ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent),
                        foregroundColor: AppColors.accent,
                      ),
                      child: const Text('Start Onboarding'),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Debug: go to courses
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pushNamed(context, AppRoutes.courses),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.accent2),
                        foregroundColor: AppColors.accent2,
                      ),
                      child: const Text('Go to Courses (Debug)'),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Logged-in hint
                  if (isLoggedIn)
                    Text(
                      "Logged in as: ${auth.currentUser?.email ?? "(unknown)"}",
                      style: t.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
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