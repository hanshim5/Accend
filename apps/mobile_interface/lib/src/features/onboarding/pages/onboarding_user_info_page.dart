import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/widgets/primary_button.dart';
import '../controllers/onboarding_user_info_controller.dart';
import '../widgets/onboarding_labeled_field.dart';

class OnboardingUserInfoPage extends StatefulWidget {
  const OnboardingUserInfoPage({super.key});

  @override
  State<OnboardingUserInfoPage> createState() => _OnboardingUserInfoPageState();
}

class _OnboardingUserInfoPageState extends State<OnboardingUserInfoPage> {
  final _c = OnboardingUserInfoController();

  final _auth = AuthService();
  final _api = ApiClient();

  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _hidePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    _api.dispose();
    super.dispose();
  }

  void _validate() {
    _c.validate(
      fullName: _fullName.text,
      username: _username.text,
      email: _email.text,
      password: _password.text,
    );
    setState(() {});
  }

  Future<void> _onContinue() async {
    _validate();
    if (!_c.isValid) return;

    setState(() => _submitting = true);

    try {
      final username = _username.text.trim();
      final email = _email.text.trim();
      final password = _password.text;
      final fullName = _fullName.text.trim();

      final check = await _api.getJson(
        '/profile/username-available',
        query: {'username': username},
      );

      final available = check['available'] == true;
      if (!available) {
        setState(() {
          _c.usernameErr = 'Username is taken';
        });
        return;
      }

      await _auth.signUp(
        email: email,
        password: password,
      );

      final accessToken = _auth.accessToken;
      if (accessToken == null) {
        throw Exception('Missing access token after signup.');
      }

      await _api.postJson(
        '/profile/init',
        accessToken: accessToken,
        body: {
          'username': username,
          'email': email,
          'full_name': fullName,
          'native_language': null,
        },
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.onboardingNativeLanguage);
    } on ApiException catch (e) {
      if (!mounted) return;

      final msg = e.toString().toLowerCase();

      if (msg.contains('username cannot be an email')) {
        setState(() {
          _c.usernameErr = 'Username cannot be an email address';
        });
        return;
      }

      if (msg.contains('username already taken') ||
          msg.contains('username is taken')) {
        setState(() {
          _c.usernameErr = 'Username is taken';
        });
        return;
      }

      if (msg.contains('email already registered') ||
          msg.contains('user already registered') ||
          msg.contains('user_already_exists')) {
        setState(() {
          _c.emailErr = 'An account with this email already exists';
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request failed: ${e.toString()}')),
      );
    } catch (e) {
      if (!mounted) return;

      final msg = e.toString().toLowerCase();

      if (msg.contains('user already registered') ||
          msg.contains('email already registered') ||
          msg.contains('user_already_exists')) {
        setState(() {
          _c.emailErr = 'An account with this email already exists';
        });
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: t.textTheme.headlineMedium,
                        children: [
                          const TextSpan(text: 'Start your '),
                          TextSpan(
                            text: 'Ascension',
                            style: t.textTheme.headlineMedium?.copyWith(
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Begin your journey to fluency',
                      style: t.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(bottom: bottomInset),
                      child: Column(
                        children: [
                          OnboardingLabeledField(
                            label: 'Full Name',
                            child: TextField(
                              controller: _fullName,
                              onChanged: (_) {
                                if (_c.fullNameErr != null) _validate();
                              },
                              decoration: InputDecoration(
                                hintText: 'e.g. Minh Tran',
                                errorText: _c.fullNameErr,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OnboardingLabeledField(
                            label: 'Username',
                            child: TextField(
                              controller: _username,
                              onChanged: (_) {
                                if (_c.usernameErr != null) _validate();
                              },
                              decoration: InputDecoration(
                                hintText: '@minhtran_is_awesome',
                                errorText: _c.usernameErr,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OnboardingLabeledField(
                            label: 'Email Address',
                            child: TextField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (_) {
                                if (_c.emailErr != null) _validate();
                              },
                              decoration: InputDecoration(
                                hintText: 'minh@example.com',
                                errorText: _c.emailErr,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OnboardingLabeledField(
                            label: 'Password',
                            rightLabel: '(At least 8 characters)',
                            rightLabelColor: AppColors.textSecondary,
                            child: TextField(
                              controller: _password,
                              obscureText: _hidePassword,
                              onChanged: (_) {
                                if (_c.passwordErr != null) _validate();
                              },
                              decoration: InputDecoration(
                                hintText: '••••••••••••',
                                errorText: _c.passwordErr,
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword,
                                  ),
                                  icon: Icon(
                                    _hidePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: t.textTheme.bodyMedium,
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'Log in',
                                  style: t.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          PrimaryButton(
                            text: 'Continue',
                            loading: _submitting,
                            onPressed: _submitting ? null : _onContinue,
                          ),
                        ],
                      ),
                    ),
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