import 'package:flutter/material.dart';

import '../../../app/constants.dart';

class GenerateCoursePopup extends StatefulWidget {
  const GenerateCoursePopup({
    super.key,
    required this.onGenerate,
  });

  /// Return true to close modal, false to keep open (and show error)
  final Future<bool> Function(String prompt) onGenerate;

  @override
  State<GenerateCoursePopup> createState() => _GenerateCoursePopupState();
}

class _GenerateCoursePopupState extends State<GenerateCoursePopup> {
  final _promptCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final prompt = _promptCtrl.text.trim();

    if (prompt.isEmpty) {
      setState(() => _error = 'Please enter a topic.');
      return;
    }

    setState(() {
      _error = null;
      _submitting = true;
    });

    final ok = await widget.onGenerate(prompt);

    if (!mounted) return;

    setState(() => _submitting = false);

    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _error ??= 'Could not generate course. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // top icon (matches figma vibe)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: const Icon(Icons.add, color: AppColors.accent),
            ),
            const SizedBox(height: 12),

            Text(
              'Generate New Course?',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              'Ready to start a new journey? Enter a topic and our AI will craft a course for you.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _promptCtrl,
              enabled: !_submitting,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: 'Enter a topic (e.g. Conversations)',
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.failure,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Yes, Let's Go!"),
              ),
            ),

            const SizedBox(height: 8),

            TextButton(
              onPressed: _submitting ? null : () => Navigator.of(context).pop(),
              child: Text(
                'MAYBE LATER',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}