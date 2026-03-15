// learning_goal.dart

import 'package:flutter/material.dart';
import 'onboarding_header.dart';
import 'package:provider/provider.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/routes.dart';
import 'package:mobile_interface/src/features/onboarding/controllers/onboarding_controller.dart';


class LearningGoalPage extends StatefulWidget {
  const LearningGoalPage({super.key});

  @override
  State<LearningGoalPage> createState() => _LearningGoalPageState();
}

class _LearningGoalPageState extends State<LearningGoalPage> {
  int? _selectedIndex;
  bool _syncedFromController = false;

  final List<_GoalOption> _options = const [
    _GoalOption(
      title: 'Travel',
      icon: Icons.flight_takeoff,
      backendValue: 'travel',
    ),
    _GoalOption(
      title: 'Career',
      icon: Icons.work_outline,
      backendValue: 'career',
    ),
    _GoalOption(
      title: 'Culture',
      icon: Icons.language,
      backendValue: 'culture',
    ),
    _GoalOption(
      title: 'Brain Training',
      icon: Icons.psychology_outlined,
      backendValue: 'brain_training',
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedFromController) return;
    _syncedFromController = true;
    final value = context.read<OnboardingController>().data.learningGoal;
    if (value == null) return;
    final idx = _options.indexWhere((o) => o.backendValue == value);
    if (idx >= 0) setState(() => _selectedIndex = idx);
  }

  void _onSelect(int idx) {
    setState(() => _selectedIndex = idx);
    final onboardingController = context.read<OnboardingController>();
    onboardingController.setLearningGoal(_options[idx].backendValue);
  }

  String? get _selectedGoalBackendValue {
    final idx = _selectedIndex;
    if (idx == null) return null;
    return _options[idx].backendValue;
  }

  void _onContinue() {
    final goal = _selectedGoalBackendValue;
    if (goal == null) return;
    // The value is already set in the controller
    debugPrint('LearningGoal payload: {learning_goal: $goal}');
    Navigator.pushNamed(context, AppRoutes.onboardingAccentSelection);
  }

  Future<void> _onBack() async {
    await context.read<OnboardingController>().saveProgress();
    if (!mounted) return;
    Navigator.maybePop(context);
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
            step: 2,
            totalSteps: 5,
            rightLabel: 'Learning Goal',
            showBack: true,
            onBack: _onBack,
          ),
          const SizedBox(height: AppSpacing.sm),

          const OnboardingProgressBar(step: 2, totalSteps: 5),
          const SizedBox(height: AppSpacing.xl),

          const OnboardingQuestionHeader(
            icon: Icons.flag_outlined,
            leadingText: 'Why ',
            highlightedText: 'are you learning?',
            subheader: 'This will help the AI determine your coursework.',
            leadingColor: AppColors.accent,          // blue "Why"
            highlightedColor: AppColors.textPrimary, // white "are you learning?"
          ),
          const SizedBox(height: AppSpacing.lg),

          // Grid fills remaining space; no scrolling
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const crossAxisSpacing = 16.0;
                const mainAxisSpacing = 12.0;

                final gridWidth = constraints.maxWidth;
                final gridHeight = constraints.maxHeight;

                // 2x2 grid: compute card sizes to exactly fit available height
                final cardWidth = (gridWidth - crossAxisSpacing) / 2;
                final cardHeight = (gridHeight - mainAxisSpacing) / 2;

                final childAspectRatio =
                    (cardHeight <= 0) ? 1.0 : (cardWidth / cardHeight);

                return GridView.builder(
                  padding: EdgeInsets.zero,
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
                        icon: opt.icon,
                        selected: selected,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // button margin top
          const SizedBox(height: 16),

          SizedBox(
            height: 56,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedIndex == null ? null : _onContinue,
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

class GoalOptionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool selected;

  const GoalOptionCard({
    super.key,
    required this.title,
    required this.icon,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    // Keep icon alignment consistent, but don’t let the title get pushed down.
    const double iconCircleSize = 80;
    const double iconSize = 40;
    const double iconSlotHeight = 84;   // ↓ was 96 (reduces empty space)
    const double titleSlotHeight = 56;  // fixed title slot instead of Expanded

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
          SizedBox(
            height: iconSlotHeight,
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: iconCircleSize,
                height: iconCircleSize,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accent.withOpacity(0.12)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: iconSize,
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6), // ↓ was 10

          SizedBox(
            height: titleSlotHeight,
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: (Theme.of(context).textTheme.titleMedium ??
                        const TextStyle())
                    .copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalOption {
  final String title;
  final IconData icon;
  final String backendValue;

  const _GoalOption({
    required this.title,
    required this.icon,
    required this.backendValue,
  });
}