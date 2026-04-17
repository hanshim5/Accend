import 'package:google_sign_in/google_sign_in.dart';
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

  /// Native sign-in using google_sign_in package (requires Google Play Services).
  /// Use on real devices or Google Play emulators.
  Future<void> signInWithGoogleNative({
    required String webClientId,
    required String iosClientId,
  }) async {
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize(
      serverClientId: webClientId,
      clientId: iosClientId,
    );

    final lightweightUser = await googleSignIn.attemptLightweightAuthentication();
    final googleUser = lightweightUser ?? await googleSignIn.authenticate();

    const scopes = ['email', 'profile'];
    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(scopes) ??
        await googleUser.authorizationClient.authorizeScopes(scopes);

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw const AuthException('No ID token received from Google.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  /// Browser-based OAuth sign-in. Works on all devices and emulators.
  /// Opens a browser; session is delivered via onAuthStateChange.
  Future<void> signInWithGoogleOAuth() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'accend://login-callback',
      queryParams: {'prompt': 'select_account'},
    );
  }
}