import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/routes.dart';
import 'package:mobile_interface/src/features/onboarding/controllers/onboarding_controller.dart';
import '../widgets/onboarding_language_dropdown.dart';
import 'onboarding_header.dart';

class NativeLanguagePage extends StatefulWidget {
  const NativeLanguagePage({super.key});

  @override
  State<NativeLanguagePage> createState() => _NativeLanguagePageState();
}

class _NativeLanguagePageState extends State<NativeLanguagePage> {
  String? _selected;
  bool _syncedFromController = false;

  static const List<String> _languages = [
    'English',
    'Spanish',
    'French',
    'Japanese',
    'Korean',
    'Mandarin',
    'Cantonese',
    'Wu',
    'Vietnamese',
    'Ilocano',
    'Tagalog',
    'Russian',
    'Arabic',
    'Georgian',
    'German',
    'Latin',
    'Bulgarian',
    'Scandinavian',
    'Sinhala',
    'Hindi',
    'Portuguese',
    'Nepali',
    'Signese',
    'Braille',
    'Hausa',
    'Yoruba',
    'Igbo',
    'Swedish',
    'Italian',
    'Greek',
    'Pidgin',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedFromController) return;
    _syncedFromController = true;
    final value = context.read<OnboardingController>().data.nativeLanguage;
    if (value != null && value.isNotEmpty) {
      setState(() => _selected = value);
    }
  }

  void _onSelect(String value) {
    setState(() => _selected = value);
    final onboardingController = context.read<OnboardingController>();
    onboardingController.setNativeLanguage(value);
    onboardingController.saveProgress();
  }

  Future<void> _onContinue() async {
    if (_selected == null) return;
    await context.read<OnboardingController>().saveProgress(silent: false);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.onboardingSkillAssess);
  }

  Future<void> _onBack() async {
    final onboardingController = context.read<OnboardingController>();
    await onboardingController.saveProgress();
    if (!mounted) return;
    final didPop = await Navigator.maybePop(context);
    if (!didPop && mounted) {
      final previousRoute = onboardingController.previousRouteFor(
        AppRoutes.onboardingNativeLanguage,
      );
      if (previousRoute != null) {
        Navigator.pushReplacementNamed(context, previousRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm + 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OnboardingTopBar(
                        step: 1,
                        totalSteps: 7,
                        rightLabel: 'Native Language',
                        showBack: true,
                        onBack: _onBack,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      const OnboardingProgressBar(step: 1, totalSteps: 7),
                      const SizedBox(height: AppSpacing.xl),
                      const OnboardingQuestionHeader(
                        icon: Icons.record_voice_over_outlined,
                        leadingText: 'What is your ',
                        highlightedText: 'native language',
                        trailingText: '?',
                        subheader:
                            'We use this to tailor your experience by adjusting pronunciation feedback and which errors are flagged.',
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      OnboardingLanguageDropdown(
                        value: _selected,
                        options: _languages,
                        onChanged: _onSelect,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selected == null ? null : _onContinue,
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}