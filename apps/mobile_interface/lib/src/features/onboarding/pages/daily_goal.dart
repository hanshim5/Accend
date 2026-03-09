// daily_goal.dart

import 'package:flutter/material.dart';
import 'onboarding_header.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/routes.dart';
import 'package:mobile_interface/src/app/theme.dart';

// void main() => runApp(const DailyGoalApp());

// class DailyGoalApp extends StatelessWidget {
//   const DailyGoalApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: AppStrings.appName,
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.dark(),
//       home: const Scaffold(
//         body: SafeArea(child: DailyGoalPage()),
//       ),
//     );
//   }
// }

enum DailyGoalChoice { hiker, climber, summiter, mountaineer }

class DailyGoalPage extends StatefulWidget {
  const DailyGoalPage({super.key});

  @override
  State<DailyGoalPage> createState() => _DailyGoalPageState();
}

class _DailyGoalPageState extends State<DailyGoalPage> {
  DailyGoalChoice? _selected;

  final List<_DailyGoalOption> _options = const [
    _DailyGoalOption(
      title: 'Hiker',
      subtitle: '5 min a day | Starting small',
      value: DailyGoalChoice.hiker,
      backendValue: 'hiker',
    ),
    _DailyGoalOption(
      title: 'Climber',
      subtitle: '10 min a day | Building momentum',
      value: DailyGoalChoice.climber,
      backendValue: 'climber',
    ),
    _DailyGoalOption(
      title: 'Summiter',
      subtitle: '15 min a day | Serious climbing',
      value: DailyGoalChoice.summiter,
      backendValue: 'summiter',
    ),
    _DailyGoalOption(
      title: 'Mountaineer',
      subtitle: '20 min a day | Total immersion',
      value: DailyGoalChoice.mountaineer,
      backendValue: 'mountaineer',
    ),
  ];

  void _select(DailyGoalChoice v) => setState(() => _selected = v);

  void _onContinue() {
    final sel = _selected;
    if (sel == null) return;

    final backend = _options.firstWhere((o) => o.value == sel).backendValue;
    debugPrint('DailyGoal payload: {daily_goal: $backend}');
    // Onboarding complete - for now just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Onboarding complete! Welcome to Accend.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm + 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const OnboardingTopBar(
            step: 5,
            totalSteps: 5,
            rightLabel: 'Daily Goal',
            showBack: true,
          ),
          const SizedBox(height: AppSpacing.sm),

          const OnboardingProgressBar(step: 5, totalSteps: 5),
          const SizedBox(height: AppSpacing.xl),

          const OnboardingQuestionHeader(
            icon: Icons.timer_outlined,
            leadingText: 'Set your ',
            highlightedText: 'daily pace',
            trailingText: '',
            subheader:
                'Consistency is the peak of success. Choose how much you want to commit to your climb.',
          ),

          const SizedBox(height: AppSpacing.xl),

          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final opt = _options[i];
                final selected = _selected == opt.value;

                return DailyGoalOptionCard(
                  title: opt.title,
                  subtitle: opt.subtitle,
                  selected: selected,
                  onTap: () => _select(opt.value),
                );
              },
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
    );
  }
}

class DailyGoalOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  const DailyGoalOptionCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor =
        selected ? AppColors.accent : const Color(0x7F334155);
    final borderWidth = selected ? 2.0 : 1.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: (Theme.of(context).textTheme.headlineSmall ??
                              const TextStyle())
                          .copyWith(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? AppColors.accent
                        : const Color(0x7F334155),
                    width: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyGoalOption {
  final String title;
  final String subtitle;
  final DailyGoalChoice value;
  final String backendValue;

  const _DailyGoalOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.backendValue,
  });
}