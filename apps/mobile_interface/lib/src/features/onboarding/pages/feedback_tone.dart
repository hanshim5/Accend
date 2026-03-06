// feedback_tone.dart

import 'package:flutter/material.dart';
import 'onboarding_header.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:mobile_interface/src/app/theme.dart';

// void main() => runApp(const FeedbackToneApp());

// class FeedbackToneApp extends StatelessWidget {
//   const FeedbackToneApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: AppStrings.appName,
//       debugShowCheckedModeBanner: false,
//       theme: AppTheme.dark(),
//       home: const Scaffold(
//         body: SafeArea(child: FeedbackTonePage()),
//       ),
//     );
//   }
// }

enum FeedbackToneChoice { passionate, supportive, neutral, strict }

class FeedbackTonePage extends StatefulWidget {
  const FeedbackTonePage({super.key});

  @override
  State<FeedbackTonePage> createState() => _FeedbackTonePageState();
}

class _FeedbackTonePageState extends State<FeedbackTonePage> {
  FeedbackToneChoice? _selected;

  final List<_ToneOption> _options = const [
    _ToneOption(
      title: 'Passionate',
      value: FeedbackToneChoice.passionate,
      backendValue: 'passionate',
    ),
    _ToneOption(
      title: 'Supportive',
      value: FeedbackToneChoice.supportive,
      backendValue: 'supportive',
    ),
    _ToneOption(
      title: 'Neutral',
      value: FeedbackToneChoice.neutral,
      backendValue: 'neutral',
    ),
    _ToneOption(
      title: 'Strict',
      value: FeedbackToneChoice.strict,
      backendValue: 'strict',
    ),
  ];

  void _select(FeedbackToneChoice v) => setState(() => _selected = v);

  void _onContinue() {
    final sel = _selected;
    if (sel == null) return;

    final backend = _options.firstWhere((o) => o.value == sel).backendValue;
    debugPrint('FeedbackTone payload: {feedback_tone: $backend}');
    // TODO: Navigator.push(...) to next onboarding page
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
            step: 4,
            totalSteps: 5,
            rightLabel: 'Feedback Tone',
            showBack: true,
          ),
          const SizedBox(height: AppSpacing.sm),

          const OnboardingProgressBar(step: 4, totalSteps: 5),
          const SizedBox(height: AppSpacing.xl),

          const OnboardingQuestionHeader(
            // matches “feedback / voice” better than mountains
            icon: Icons.record_voice_over_outlined,
            leadingText: '',
            highlightedText: 'Feedback',
            trailingText: ' tone?',
            subheader: 'Choose how you want your feedback delivered to you.',
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

                return ToneOptionCard(
                  title: opt.title,
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

class ToneOptionCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback? onTap;

  const ToneOptionCard({
    super.key,
    required this.title,
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
                child: Text(
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

class _ToneOption {
  final String title;
  final FeedbackToneChoice value;
  final String backendValue;

  const _ToneOption({
    required this.title,
    required this.value,
    required this.backendValue,
  });
}