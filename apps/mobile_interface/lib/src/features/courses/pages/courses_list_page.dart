import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../../common/widgets/bottom_nav_bar.dart';

import '../controllers/courses_controller.dart';
import '../models/course.dart';
import '../widgets/course_card.dart';
import '../widgets/generate_course_popup.dart';
import '../widgets/start_lesson_popup.dart';

class CoursesListPage extends StatefulWidget {
  const CoursesListPage({super.key});

  @override
  State<CoursesListPage> createState() => _CoursesListPageState();
}

class _CoursesListPageState extends State<CoursesListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoursesController>().loadCourses();
    });
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.social);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CoursesController>();

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () =>
              Navigator.of(context).pushReplacementNamed(AppRoutes.login),
        ),
        title: Text(
          "Courses",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle,
              color: AppColors.action,
              size: 28,
            ),
            onPressed: () => _openGenerateCoursePopup(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            0,
          ),
          child: Builder(
            builder: (_) {
              if (ctrl.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (ctrl.error != null) {
                return _ErrorState(
                  message: ctrl.error!,
                  onRetry: ctrl.loadCourses,
                );
              }

              if (ctrl.courses.isEmpty) {
                return _EmptyState(
                  onCreate: () => _openGenerateCoursePopup(context),
                );
              }

              return _CoursesGrid(
                courses: ctrl.courses,
                onTapCourse: (course) async {
                  final ctrl = context.read<CoursesController>();

                  try {
                    final lessons = await ctrl.fetchLessons(course.id);

                    if (!context.mounted) return;

                    await showDialog(
                      context: context,
                      barrierDismissible: true,
                      builder: (_) => StartLessonPopup(
                        course: course,
                        lessons: lessons,
                        onStart: (lesson) {
                          Navigator.of(context).pop();
                          Navigator.of(context).pushNamed(
                            AppRoutes.soloPractice,
                            arguments: lesson,
                          );
                        },
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not load lessons: $e'),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: null,
        onDestinationSelected: _onNavTap,
      ),
    );
  }

  Future<void> _openGenerateCoursePopup(BuildContext context) async {
    final ctrl = context.read<CoursesController>();

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => GenerateCoursePopup(
        onGenerate: (prompt) async {
          final ok = await ctrl.generateCourse(prompt);
          return ok;
        },
      ),
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  const _CoursesGrid({
    required this.courses,
    required this.onTapCourse,
  });

  final List<Course> courses;
  final void Function(Course course) onTapCourse;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      itemCount: courses.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.74,
      ),
      itemBuilder: (context, i) {
        final course = courses[i];
        return CourseCard(
          course: course,
          onTap: () => onTapCourse(course),
        );
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "No courses yet",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tap + to create your first course.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onCreate,
              child: const Text("Create course"),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 44, color: AppColors.failure),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Couldn't load courses",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }
}