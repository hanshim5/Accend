// learning_goal.dart

import 'package:flutter/material.dart';
import 'onboarding_header.dart';
import 'package:mobile_interface/src/app/constants.dart';

// void main() => runApp(const LearningGoalApp());

// class LearningGoalApp extends StatelessWidget {
//   const LearningGoalApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: AppStrings.appName,
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.dark(),
//       home: const Scaffold(
//         body: SafeArea(child: LearningGoalPage()),
//       ),
//     );
//   }
// }

class LearningGoalPage extends StatefulWidget {
  const LearningGoalPage({super.key});

  @override
  State<LearningGoalPage> createState() => _LearningGoalPageState();
}

class _LearningGoalPageState extends State<LearningGoalPage> {
  int? _selectedIndex;

  final List<_GoalOption> _options = const [
    _GoalOption(title: 'Travel', subtitle: 'Speak while traveling'),
    _GoalOption(title: 'Career', subtitle: 'Advance my job prospects'),
    _GoalOption(title: 'Culture', subtitle: 'Connect with people & media'),
    _GoalOption(title: 'Brain Training', subtitle: 'Improve memory & thinking'),
  ];

  void _onSelect(int idx) => setState(() => _selectedIndex = idx);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 6, // ~18 like your original
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingTopBar(
            step: 2,
            totalSteps: 5,
            rightLabel: 'Learning Goal',
            showBack: true,
          ),
          const SizedBox(height: AppSpacing.sm),

          const OnboardingProgressBar(step: 2, totalSteps: 5),
          const SizedBox(height: AppSpacing.xl),

          const OnboardingQuestionHeader(
            icon: Icons.flag_outlined,
            leadingText: 'Why ',
            highlightedText: 'are you learning?',
            subheader: 'This will help the AI determine your coursework.',
          ),
          const SizedBox(height: AppSpacing.lg),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gridWidth = constraints.maxWidth;
                final gridHeight = constraints.maxHeight;

                const crossAxisSpacing = 16.0;
                const mainAxisSpacing = 12.0;

                final cardWidth = (gridWidth - crossAxisSpacing) / 2;
                final cardHeight = (gridHeight - mainAxisSpacing) / 2;
                final childAspectRatio =
                    (cardHeight <= 0) ? 1.0 : (cardWidth / cardHeight);

                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _options.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: crossAxisSpacing,
                    mainAxisSpacing: mainAxisSpacing,
                    childAspectRatio: childAspectRatio,
                  ),
                  itemBuilder: (context, idx) {
                    final opt = _options[idx];
                    final selected = _selectedIndex == idx;

                    return GestureDetector(
                      onTap: () => _onSelect(idx),
                      child: GoalOptionCard(
                        title: opt.title,
                        subtitle: opt.subtitle,
                        selected: selected,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Continue button
          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedIndex == null
                  ? null
                  : () {
                      // TODO: Navigator.push(...) to next onboarding page
                    },

              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _selectedIndex == null ? AppColors.surface : AppColors.action,
                foregroundColor: const Color(0xFF101828),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
              ),
              child: const Text('Continue'),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class GoalOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;

  const GoalOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.accent : const Color(0x7F334155),
          width: selected ? 2 : 1,
        ),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // circular icon placeholder
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withOpacity(0.12)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.star,
              size: 32,
              color: selected ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption {
  final String title;
  final String subtitle;
  const _GoalOption({required this.title, required this.subtitle});
}