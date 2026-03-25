import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/auth_service.dart';
import '../../onboarding/controllers/onboarding_controller.dart';

class LoginController extends ChangeNotifier {
  LoginController({
    required this.auth,
    required this.api,
    required this.onboarding,
  });

  final AuthService auth;
  final ApiClient api;
  final OnboardingController onboarding;

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

      var nextRoute = AppRoutes.courses;
      try {
        nextRoute = await onboarding.getPostLoginRoute();
      } catch (e) {
        debugPrint('Login resume route lookup failed: $e');
      }

      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, nextRoute);
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

  void forgotPassword(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Forgot password is not wired yet.')),
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