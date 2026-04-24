import 'package:flutter/material.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/routes.dart';
import 'package:mobile_interface/src/features/onboarding/controllers/onboarding_controller.dart';
import 'package:provider/provider.dart';

import 'onboarding_header.dart';

class FocusAreasPage extends StatefulWidget {
  const FocusAreasPage({super.key});

  @override
  State<FocusAreasPage> createState() => _FocusAreasPageState();
}

class _FocusAreasPageState extends State<FocusAreasPage> {
  static const int _maxSelections = 3;

  static const List<_FocusAreaOption> _options = [
    _FocusAreaOption(label: 'Vocabulary', backendValue: 'vocabulary'),
    _FocusAreaOption(label: 'Grammar', backendValue: 'grammar'),
    _FocusAreaOption(label: 'Slang', backendValue: 'slang'),
    _FocusAreaOption(label: 'Pronunciation', backendValue: 'pronunciation'),
    _FocusAreaOption(label: 'Listening', backendValue: 'listening'),
    _FocusAreaOption(label: 'Conversation', backendValue: 'conversation'),
  ];

  final Set<String> _selected = <String>{};
  bool _syncedFromController = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedFromController) return;
    _syncedFromController = true;

    final saved = context.read<OnboardingController>().data.focusAreas;
    if (saved == null || saved.trim().isEmpty) return;

    final validValues = _options.map((o) => o.backendValue).toSet();
    final parsed = saved
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim().toLowerCase().replaceAll(' ', '_'))
        .where((s) => s.isNotEmpty && validValues.contains(s))
        .take(_maxSelections)
        .toSet();

    if (parsed.isNotEmpty) {
      setState(() => _selected.addAll(parsed));
    }
  }

  void _toggle(String backendValue) {
    if (_selected.contains(backendValue)) {
      setState(() => _selected.remove(backendValue));
    } else {
      if (_selected.length >= _maxSelections) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You can select up to 3 focus areas.')),
        );
        return;
      }
      setState(() => _selected.add(backendValue));
    }

    context.read<OnboardingController>().setFocusAreas(_selected.join(', '));
    context.read<OnboardingController>().saveProgress();
  }

  Future<void> _onBack() async {
    final onboardingController = context.read<OnboardingController>();
    await onboardingController.saveProgress();
    if (!mounted) return;
    final didPop = await Navigator.maybePop(context);
    if (!didPop && mounted) {
      final previousRoute = onboardingController.previousRouteFor(
        AppRoutes.onboardingFocusAreas,
      );
      if (previousRoute != null) {
        Navigator.pushReplacementNamed(context, previousRoute);
      }
    }
  }

  Future<void> _onContinue() async {
    if (_selected.isEmpty) return;
    await context.read<OnboardingController>().saveProgress(silent: false);
    if (!mounted) return;
    Navigator.pushNamed(context, AppRoutes.onboardingAccentSelection);
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
                step: 4,
                totalSteps: 7,
                rightLabel: 'Focus Areas',
                showBack: true,
                onBack: _onBack,
              ),
              const SizedBox(height: AppSpacing.sm),

              const OnboardingProgressBar(step: 4, totalSteps: 7),
              const SizedBox(height: AppSpacing.xl),

              const OnboardingQuestionHeader(
                icon: Icons.gps_fixed,
                leadingText: 'Choose your ',
                highlightedText: 'specialized focus',
                subheader:
                    'Pick up to 3 areas to prioritize in your coursework.',
              ),
              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _options.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.8,
                  ),
                  itemBuilder: (context, index) {
                    final option = _options[index];
                    final selected = _selected.contains(option.backendValue);
                    return _FocusAreaCard(
                      label: option.label,
                      selected: selected,
                      onTap: () => _toggle(option.backendValue),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _selected.isEmpty ? null : _onContinue,
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

class _FocusAreaOption {
  final String label;
  final String backendValue;

  const _FocusAreaOption({required this.label, required this.backendValue});
}

class _FocusAreaCard extends StatelessWidget {
  const _FocusAreaCard({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.accent : const Color(0x7F334155),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 28,
                height: 28,
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
                child: selected
                    ? const Icon(
                        Icons.check,
                        color: AppColors.primaryBg,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
