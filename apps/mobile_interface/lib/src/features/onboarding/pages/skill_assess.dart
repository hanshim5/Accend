import 'package:flutter/material.dart';
import 'onboarding_header.dart';
import 'package:provider/provider.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/routes.dart';
import 'package:mobile_interface/src/features/onboarding/controllers/onboarding_controller.dart';

enum SkillLevel { beginner, intermediate, advanced }

class SkillAssessPage extends StatefulWidget {
  const SkillAssessPage({super.key});

  @override
  State<SkillAssessPage> createState() => _SkillAssessPageState();
}

class _SkillAssessPageState extends State<SkillAssessPage> {
  SkillLevel? _selectedLevel;
  bool _syncedFromController = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedFromController) return;
    _syncedFromController = true;
    final value = context.read<OnboardingController>().data.skillAssess;
    if (value == null) return;
    final level = switch (value) {
      'beginner' => SkillLevel.beginner,
      'intermediate' => SkillLevel.intermediate,
      'advanced' => SkillLevel.advanced,
      _ => null,
    };
    if (level != null) setState(() => _selectedLevel = level);
  }

  void _selectLevel(SkillLevel level) {
    setState(() => _selectedLevel = level);
    final onboardingController = context.read<OnboardingController>();
    final backend = switch (level) {
      SkillLevel.beginner => 'beginner',
      SkillLevel.intermediate => 'intermediate',
      SkillLevel.advanced => 'advanced',
    };
    onboardingController.setSkillAssess(backend);
    onboardingController.saveProgress();
  }

  Future<void> _onContinue() async {
    final sel = _selectedLevel;
    if (sel == null) return;
    await context.read<OnboardingController>().saveProgress(silent: false);
    Navigator.pushNamed(context, AppRoutes.onboardingLearningGoal);
  }

  Future<void> _onBack() async {
    final onboardingController = context.read<OnboardingController>();
    await onboardingController.saveProgress();
    if (!mounted) return;
    final didPop = await Navigator.maybePop(context);
    if (!didPop && mounted) {
      final previousRoute = onboardingController.previousRouteFor(
        AppRoutes.onboardingSkillAssess,
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
            OnboardingTopBar(
              step: 1,
              totalSteps: 5,
              rightLabel: 'Skill Assessment',
              showBack: true,
              onBack: _onBack,
            ),
            const SizedBox(height: AppSpacing.sm),

            const OnboardingProgressBar(step: 1, totalSteps: 5),
            const SizedBox(height: AppSpacing.xl),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const OnboardingQuestionHeader(
                      leadingText: 'What is your ',
                      highlightedText: 'current level?',
                      subheader: 'This helps us customize your learning path.',
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    LevelCard(
                      tag: 'BEGINNER',
                      title: 'Newbie',
                      description: 'I know a few words or I am starting from scratch.',
                      isSelected: _selectedLevel == SkillLevel.beginner,
                      onTap: () => _selectLevel(SkillLevel.beginner),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    LevelCard(
                      tag: 'INTERMEDIATE',
                      title: 'Conversationalist',
                      description:
                          'I can hold basic conversations and understand common topics.',
                      isSelected: _selectedLevel == SkillLevel.intermediate,
                      onTap: () => _selectLevel(SkillLevel.intermediate),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    LevelCard(
                      tag: 'ADVANCED',
                      title: 'Fluent Speaker',
                      description: 'I can speak fluently and understand complex topics.',
                      isSelected: _selectedLevel == SkillLevel.advanced,
                      onTap: () => _selectLevel(SkillLevel.advanced),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _selectedLevel == null ? null : _onContinue,
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

class LevelCard extends StatelessWidget {
  final String tag;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback? onTap;

  const LevelCard({
    super.key,
    required this.tag,
    required this.title,
    required this.description,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isSelected ? AppColors.accent : const Color(0x7F334155),
              width: isSelected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: AppColors.primaryBg,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      title,
                      style: (Theme.of(context).textTheme.headlineMedium ??
                              const TextStyle())
                          .copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: const Color(0x7F334155)),
                ),
                child: isSelected
                    ? const Icon(Icons.check,
                        color: AppColors.primaryBg, size: 20)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}