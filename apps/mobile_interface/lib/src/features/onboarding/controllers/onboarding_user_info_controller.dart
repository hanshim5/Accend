class OnboardingUserInfoController {
  String? fullNameErr;
  String? usernameErr;
  String? emailErr;
  String? passwordErr;
  String? languageErr;

  bool validate({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String? selectedLanguage,
  }) {
    // Reset previous errors
    fullNameErr = null;
    usernameErr = null;
    emailErr = null;
    passwordErr = null;
    languageErr = null;

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

    // Language
    if (selectedLanguage == null || selectedLanguage.isEmpty) {
      languageErr = 'Please select a language';
    }

    return isValid;
  }

  bool get isValid =>
      fullNameErr == null &&
      usernameErr == null &&
      emailErr == null &&
      passwordErr == null &&
      languageErr == null;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    return emailRegex.hasMatch(email);
  }
}