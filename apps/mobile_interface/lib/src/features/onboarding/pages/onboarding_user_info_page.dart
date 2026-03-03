import 'package:flutter/material.dart';
import '../../../app/constants.dart';
import '../../../common/widgets/primary_button.dart';
import '../controllers/onboarding_user_info_controller.dart';
import '../widgets/onboarding_labeled_field.dart';
import '../widgets/onboarding_language_dropdown.dart';

class OnboardingUserInfoPage extends StatefulWidget {
  const OnboardingUserInfoPage({super.key});

  @override
  State<OnboardingUserInfoPage> createState() => _OnboardingUserInfoPageState();
}

class _OnboardingUserInfoPageState extends State<OnboardingUserInfoPage> {
  final _c = OnboardingUserInfoController();

  final _fullName = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _hidePassword = true;
  bool _submitting = false;

  String? _nativeLanguage;
  final _languages = const ['Spanish', 'Chinese', 'Vietnamese'];

  @override
  void dispose() {
    _fullName.dispose();
    _username.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _validate() {
    _c.validate(
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
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Continue (backend hookup next)')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    return Scaffold(
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
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          'Onboarding',
                          style: t.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('User Information', style: t.textTheme.bodyMedium),
                  ),

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
                    child: Text('Begin your journey to fluency', style: t.textTheme.bodyMedium),
                  ),

                  const SizedBox(height: 18),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          OnboardingLabeledField(
                            label: 'Full Name',
                            child: TextField(
                              controller: _fullName,
                              decoration: const InputDecoration(hintText: 'e.g. Minh Tran'),
                            ),
                          ),
                          const SizedBox(height: 12),

                          OnboardingLabeledField(
                            label: 'Username',
                            rightLabel: _c.usernameErr != null ? 'Username is taken' : null,
                            rightLabelColor: AppColors.failure,
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
                            rightLabel: _c.emailErr != null ? 'Email is taken' : null,
                            rightLabelColor: AppColors.failure,
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
                                  onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                  icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          OnboardingLabeledField(
                            label: 'Native Language',
                            child: OnboardingLanguageDropdown(
                              value: _nativeLanguage,
                              options: _languages,
                              onChanged: (v) => setState(() => _nativeLanguage = v),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account? ', style: t.textTheme.bodyMedium),
                              GestureDetector(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Login page coming next')),
                                  );
                                },
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
                            onPressed: _onContinue,
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