import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  StreamSubscription<AuthState>? _oauthSub;

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

      final route = await onboarding.getPostLoginRoute();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, route);
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
      final cacheUserId = auth.currentUser?.id;
      await auth.signOut();
      await home.clear(cacheUserId: cacheUserId);
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

  Future<void> signInWithGoogle(BuildContext context) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await auth.signInWithGoogleOAuth();

      // Browser is now open. Listen for the session once the user
      // completes OAuth and the deep link brings them back.
      _oauthSub?.cancel();
      _oauthSub = auth.client.auth.onAuthStateChange.listen((data) async {
        if (data.event == AuthChangeEvent.signedIn) {
          _oauthSub?.cancel();
          _oauthSub = null;
          try {
            home.load();
            final route = await onboarding.getPostLoginRoute();
            if (context.mounted) {
              Navigator.pushReplacementNamed(context, route);
            }
          } catch (e) {
            errorMessage = 'Google sign-in failed. Please try again.';
            notifyListeners();
          } finally {
            isLoading = false;
            notifyListeners();
          }
        }
      });
    } on Exception catch (_) {
      errorMessage = 'Google sign-in failed. Please try again.';
      isLoading = false;
      notifyListeners();
      return;
    }

    // Clear loading while browser is open
    isLoading = false;
    notifyListeners();
  }

  void signInWithApple(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Apple sign-in is not wired yet.')),
    );
  }

  @override
  void dispose() {
    _oauthSub?.cancel();
    identifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}