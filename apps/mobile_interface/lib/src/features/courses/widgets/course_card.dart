import 'package:flutter/material.dart';
import '../../../app/constants.dart';
import '../models/course.dart';

class CourseCard extends StatelessWidget {
  const CourseCard({
    super.key,
    required this.course,
    required this.onTap,
  });

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusUpper = course.status.toUpperCase();
    final isComplete = statusUpper == "COMPLETE";
    final isInProgress = statusUpper == "IN PROGRESS";

    final statusColor = isComplete
        ? AppColors.success
        : isInProgress
            ? AppColors.success
            : AppColors.textSecondary;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadii.lg),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.md),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: _CourseImage(imageUrl: course.imageUrl),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Title
              Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
              ),

              const SizedBox(height: 4),

              // Status
              Text(
                statusUpper,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: statusColor,
                    ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Progress label
              Text(
                "Progress",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),

              const SizedBox(height: 6),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: course.progress.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.primaryBg,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                ),
              ),

              const SizedBox(height: 6),

              // Percent
              Text(
                "${(course.progress * 100).round()}%",
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({required this.imageUrl});
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      // Placeholder that matches your palette
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryBg,
              AppColors.surface,
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.school_rounded,
            color: AppColors.textSecondary,
            size: 34,
          ),
        ),
      );
    }

    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: AppColors.primaryBg,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            color: AppColors.textSecondary,
          ),
        ),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.primaryBg,
          child: const Center(
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      },
    );
  }
}