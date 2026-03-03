class OnboardingUserInfoController {
  String? usernameErr;
  String? emailErr;
  String? passwordErr;

  void validate({
    required String username,
    required String email,
    required String password,
  }) {
    final u = username.trim();
    final e = email.trim();
    final p = password;

    usernameErr = u.isEmpty ? 'Required' : null;

    if (e.isEmpty) {
      emailErr = 'Required';
    } else if (!e.contains('@') || !e.contains('.')) {
      emailErr = 'Enter a valid email';
    } else {
      emailErr = null;
    }

    if (p.isEmpty) {
      passwordErr = 'Required';
    } else if (p.length < 8) {
      passwordErr = 'Password is too short';
    } else {
      passwordErr = null;
    }
  }

  bool get isValid => usernameErr == null && emailErr == null && passwordErr == null;
}