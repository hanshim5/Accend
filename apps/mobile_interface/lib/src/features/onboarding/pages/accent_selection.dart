// accent_selection.dart

import 'package:flutter/material.dart';
import 'onboarding_header.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/routes.dart';
import 'package:provider/provider.dart';
import 'package:mobile_interface/src/features/onboarding/controllers/onboarding_controller.dart';

enum AccentChoice { californian, british, southern, australian }

class AccentSelectionPage extends StatefulWidget {
  const AccentSelectionPage({super.key});

  @override
  State<AccentSelectionPage> createState() => _AccentSelectionPageState();
}

class _AccentSelectionPageState extends State<AccentSelectionPage> {
  AccentChoice? _selected;
  bool _syncedFromController = false;

  final List<_AccentOption> _options = const [
    _AccentOption(
      title: 'Californian',
      value: AccentChoice.californian,
      enabled: true,
    ),
    _AccentOption(
      title: 'British',
      value: AccentChoice.british,
      enabled: false,
      comingSoon: true,
    ),
    _AccentOption(
      title: 'Southern',
      value: AccentChoice.southern,
      enabled: false,
      comingSoon: true,
    ),
    _AccentOption(
      title: 'Australian',
      value: AccentChoice.australian,
      enabled: false,
      comingSoon: true,
    ),
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_syncedFromController) return;
    _syncedFromController = true;
    final value = context.read<OnboardingController>().data.accent;
    if (value == null) return;
    final choice = switch (value) {
      'californian' => AccentChoice.californian,
      'british' => AccentChoice.british,
      'southern' => AccentChoice.southern,
      'australian' => AccentChoice.australian,
      _ => null,
    };
    if (choice != null) setState(() => _selected = choice);
  }

  void _select(AccentChoice v) {
    setState(() => _selected = v);
    final onboardingController = context.read<OnboardingController>();
    final backend = switch (v) {
      AccentChoice.californian => 'californian',
      AccentChoice.british => 'british',
      AccentChoice.southern => 'southern',
      AccentChoice.australian => 'australian',
    };
    onboardingController.setAccent(backend);
    onboardingController.saveProgress();
  }

  Future<void> _onContinue() async {
    final sel = _selected;
    if (sel == null) return;
    await context.read<OnboardingController>().saveProgress(silent: false);
    Navigator.pushNamed(context, AppRoutes.onboardingFeedbackTone);
  }

  Future<void> _onBack() async {
    final onboardingController = context.read<OnboardingController>();
    await onboardingController.saveProgress();
    if (!mounted) return;
    final didPop = await Navigator.maybePop(context);
    if (!didPop && mounted) {
      final previousRoute = onboardingController.previousRouteFor(
        AppRoutes.onboardingAccentSelection,
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
            step: 5,
            totalSteps: 7,
            rightLabel: 'Accent Selection',
            showBack: true,
            onBack: _onBack,
          ),
          const SizedBox(height: AppSpacing.sm),
          const OnboardingProgressBar(step: 5, totalSteps: 7),
          const SizedBox(height: AppSpacing.xl),

          const OnboardingQuestionHeader(
            icon: Icons.graphic_eq,
            leadingText: 'What ',
            highlightedText: 'accent',
            trailingText: ' do you want?',
            subheader:
                'This will alter the pronunciation feedback based on how you want to sound.',
          ),

          const SizedBox(height: AppSpacing.xl),

          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, i) {
                final opt = _options[i];
                final selected = _selected == opt.value;

                return AccentOptionCard(
                  title: opt.title,
                  selected: selected,
                  enabled: opt.enabled,
                  comingSoon: opt.comingSoon,
                  onTap: opt.enabled ? () => _select(opt.value) : null,
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
        ),
      ),
    );
  }
}

class AccentOptionCard extends StatelessWidget {
  final String title;
  final bool selected;
  final bool enabled;
  final bool comingSoon;
  final VoidCallback? onTap;

  const AccentOptionCard({
    super.key,
    required this.title,
    this.selected = false,
    this.enabled = true,
    this.comingSoon = false,
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
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        height: 1.0,
                      ),
                    ),
                    if (comingSoon) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Coming soon',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
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

class _AccentOption {
  final String title;
  final AccentChoice value;
  final bool enabled;
  final bool comingSoon;

  const _AccentOption({
    required this.title,
    required this.value,
    this.enabled = true,
    this.comingSoon = false,
  });
}