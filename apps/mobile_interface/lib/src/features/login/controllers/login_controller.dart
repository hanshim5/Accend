import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/auth_service.dart';
import '../../home/controllers/home_controller.dart';
import '../../onboarding/controllers/onboarding_controller.dart';
import '../widgets/forgot_password_dialog.dart';

class LoginController extends ChangeNotifier {
  LoginController({
    required this.auth,
    required this.api,
    required this.onboarding,
    required this.home,
  });

  final AuthService auth;
  final ApiClient api;
  final OnboardingController onboarding;
  final HomeController home;

  final TextEditingController identifierController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  bool get isLoggedIn => auth.currentSession != null;

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    notifyListeners();
  }

  void clearError() {
    if (errorMessage == null) return;
    errorMessage = null;
    notifyListeners();
  }

  void onIdentifierChanged(String _) => clearError();
  void onPasswordChanged(String _) => clearError();

  Future<void> signIn(BuildContext context) async {
    final identifier = identifierController.text.trim();
    final password = passwordController.text;

    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      if (identifier.isEmpty || password.isEmpty) {
        errorMessage = 'Please enter your username or email and password.';
        return;
      }

      final resolved = await api.postJson(
        '/auth/resolve-login',
        body: {'identifier': identifier},
      );

      final email = (resolved['email'] as String?)?.trim();
      if (email == null || email.isEmpty) {
        throw Exception('Missing resolved email');
      }

      await auth.signIn(
        email: email,
        password: password,
      );

      home.load();

      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } catch (e) {
      errorMessage = 'Invalid username, email, or password.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut(BuildContext context) async {
    errorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      await auth.signOut();
      home.clear();
      identifierController.clear();
      passwordController.clear();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out')),
      );
    } catch (e) {
      errorMessage = 'Unable to log out right now. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void goToCreateAccount(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.onboardingUserInfo);
  }

  Future<void> forgotPassword(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const ForgotPasswordDialog(),
    );
  }

  void signInWithGoogle(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google sign-in is not wired yet.')),
    );
  }

  void signInWithApple(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple sign-in is not wired yet.')),
    );
  }

  @override
  void dispose() {
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}