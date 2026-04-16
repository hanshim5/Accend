import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  AuthService({SupabaseClient? client}) : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  SupabaseClient get client => _client;

  /// Returns the current logged-in user (or null).
  User? get currentUser => _client.auth.currentUser;

  /// Returns the current session (or null).
  Session? get currentSession => _client.auth.currentSession;

  /// Convenience accessor for gateway calls.
  String? get accessToken => _client.auth.currentSession?.accessToken;

  /// Sign up with Supabase Auth (password handled by Supabase).
  ///
  /// Throws [AuthException] on failure.
  Future<User> signUp({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );

    final user = res.user;
    if (user == null) {
      // This can happen depending on email confirmation settings.
      // For Sprint 1, treat it as failure so you notice configuration issues.
      throw const AuthException('Signup failed: no user returned.');
    }
    return user;
  }

  /// Sign in (login).
  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    final res = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );

    final user = res.user;
    if (user == null) {
      throw const AuthException('Login failed: no user returned.');
    }
    return user;
  }

  /// Sends a password reset email with a deep-link redirect back into the app.
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: 'accend://reset-password',
    );
  }

  /// Updates the current user's password after a recovery flow.
  ///
  /// Must be called while the session recovered via [AuthChangeEvent.passwordRecovery]
  /// is still active.
  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() => _client.auth.signOut();
}