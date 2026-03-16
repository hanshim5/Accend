import 'package:flutter/material.dart';

import '../../../app/constants.dart';
import '../models/course.dart';
import '../models/lesson.dart';

class StartLessonPopup extends StatefulWidget {
  const StartLessonPopup({
    super.key,
    required this.course,
    required this.lessons,
    required this.onStart,
  });

  final Course course;
  final List<Lesson> lessons;
  final void Function(Lesson lesson) onStart;

  @override
  State<StartLessonPopup> createState() => _StartLessonPopupState();
}

class _StartLessonPopupState extends State<StartLessonPopup> {
  Lesson? _selectedLesson;

  @override
  void initState() {
    super.initState();

    if (widget.lessons.isNotEmpty) {
      _selectedLesson = widget.lessons.firstWhere(
        (l) => !l.isCompleted,
        orElse: () => widget.lessons.first,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nextLesson = widget.lessons.cast<Lesson?>().firstWhere(
          (l) => l != null && !l.isCompleted,
          orElse: () => null,
        );

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
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: const Icon(Icons.menu_book_rounded, color: AppColors.accent),
            ),
            const SizedBox(height: 12),
            Text(
              widget.course.title,
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose a lesson to begin or continue.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            if (nextLesson != null) ...[
              const SizedBox(height: 14),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadii.md),
                onTap: () {
                  setState(() => _selectedLesson = nextLesson);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBg,
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Continue where you left off',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Lesson ${nextLesson.position}: ${nextLesson.title}',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: widget.lessons.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          'No lessons found for this course yet.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: widget.lessons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final lesson = widget.lessons[index];
                        final isSelected = _selectedLesson?.id == lesson.id;

                        return InkWell(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          onTap: () => setState(() => _selectedLesson = lesson),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBg
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.textSecondary.withValues(alpha: 0.2),
                                width: isSelected ? 1.4 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  lesson.isCompleted
                                      ? Icons.check_circle
                                      : isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                  color: lesson.isCompleted
                                      ? AppColors.success
                                      : isSelected
                                          ? AppColors.accent
                                          : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Lesson ${lesson.position}',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        lesson.title,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  lesson.isCompleted ? 'Completed' : 'Not started',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: lesson.isCompleted
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedLesson == null
                    ? null
                    : () => widget.onStart(_selectedLesson!),
                child: const Text('Start Lesson'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'KEEP BROWSING',
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