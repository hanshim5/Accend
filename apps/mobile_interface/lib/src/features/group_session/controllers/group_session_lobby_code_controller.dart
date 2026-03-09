class OnboardingUserInfoController {
  String? lobbyCodeErr;

  void validate({
    required String lobbyCode,
  }) {
    final code = lobbyCode.trim();

    lobbyCodeErr = code.isEmpty ? 'Required' : null;

    // Most likely need checks for length of code, as well as making sure it is all numbers
    if (code.isEmpty) {
      lobbyCodeErr = 'Required';
    } else {
      lobbyCodeErr = null;
    }
  }

  bool get isValid => usernameErr == null && emailErr == null && passwordErr == null;
}