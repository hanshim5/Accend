class OnboardingUserInfoController {
  String? fullNameErr;
  String? usernameErr;
  String? emailErr;
  String? passwordErr;

  bool validate({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) {
    // Reset previous errors
    fullNameErr = null;
    usernameErr = null;
    emailErr = null;
    passwordErr = null;

    final f = fullName.trim();
    final u = username.trim();
    final e = email.trim();
    final p = password;

    // Full Name
    if (f.isEmpty) {
      fullNameErr = 'Required';
    }

    // Username
    if (u.isEmpty) {
      usernameErr = 'Required';
    } else if (u.length < 3) {
      usernameErr = 'Must be at least 3 characters';
    } else if (_looksLikeEmail(u)) {
      usernameErr = 'Username cannot be an email address';
    }

    // Email
    if (e.isEmpty) {
      emailErr = 'Required';
    } else if (!_isValidEmail(e)) {
      emailErr = 'Enter a valid email';
    }

    // Password
    if (p.isEmpty) {
      passwordErr = 'Required';
    } else if (p.length < 8) {
      passwordErr = 'Password must be at least 8 characters';
    }

    return isValid;
  }

  bool get isValid =>
      fullNameErr == null &&
      usernameErr == null &&
      emailErr == null &&
      passwordErr == null;

  bool _looksLikeEmail(String value) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return emailRegex.hasMatch(value.trim());
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    return emailRegex.hasMatch(email);
  }
}