// skill_assess.dart
import 'package:flutter/material.dart';
import 'onboarding_header.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/theme.dart';

void main() => runApp(const SkillAssessApp());

class SkillAssessApp extends StatelessWidget {
  const SkillAssessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      home: const Scaffold(
        body: SafeArea(child: SkillAssessPage()),
      ),
    );
  }
}

class SkillAssessPage extends StatelessWidget {
  const SkillAssessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 6, // ~18 like your original
      ),
      children: [
        const OnboardingTopBar(
          step: 1,
          totalSteps: 5,
          rightLabel: 'Skill Assessment',
          showBack: false,
        ),
        const SizedBox(height: AppSpacing.sm),

        const OnboardingProgressBar(step: 1, totalSteps: 5),
        const SizedBox(height: AppSpacing.xl),

        const OnboardingQuestionHeader(
          icon: Icons.insights,
          leadingText: 'What is your ',
          highlightedText: 'current level?',
          subheader: 'This helps us customize your learning path.',
        ),
        const SizedBox(height: AppSpacing.xl),

        // Level cards
        const LevelCard(
          tag: 'BEGINNER',
          title: 'Newbie',
          description: 'I know a few words or I am starting from scratch.',
          isSelected: false,
        ),
        const SizedBox(height: AppSpacing.md),

        const LevelCard(
          tag: 'INTERMEDIATE',
          title: 'Conversationalist',
          description: 'I can hold basic conversations and understand common topics.',
          isSelected: false,
        ),
        const SizedBox(height: AppSpacing.md),

        const LevelCard(
          tag: 'ADVANCED',
          title: 'Fluent Speaker',
          description: 'I can speak fluently and understand complex topics.',
          isSelected: true,
        ),
        const SizedBox(height: AppSpacing.xl),

        // Continue button
        SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Navigator.push(...) to next onboarding page
            },
            child: const Text('Continue'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}

class LevelCard extends StatelessWidget {
  final String tag;
  final String title;
  final String description;
  final bool isSelected;

  const LevelCard({
    super.key,
    required this.tag,
    required this.title,
    required this.description,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                // tag pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),

                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),

          // selection circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x7F334155)),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: AppColors.primaryBg, size: 20)
                : null,
          ),
        ],
      ),
    );
  }
}