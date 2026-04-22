// lib/src/features/courses/pages/courses_list_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';

import '../controllers/courses_controller.dart';
import '../models/course.dart';
import '../pages/generate_course_page.dart';
import '../widgets/course_card.dart';
import '../widgets/generate_course_popup.dart';
import '../widgets/start_lesson_popup.dart';

class CoursesListPage extends StatefulWidget {
  const CoursesListPage({super.key});

  @override
  State<CoursesListPage> createState() => _CoursesListPageState();
}

class _CoursesListPageState extends State<CoursesListPage> {
  String? _initialCourseId;
  bool _initialJumpHandled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CoursesController>().loadCourses();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialCourseId != null) return;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.trim().isNotEmpty) {
      _initialCourseId = args.trim();
    }
  }


  Future<void> _confirmDelete(Course course) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInQuart,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => _DeleteCourseDialog(courseTitle: course.title),
    );

    if (confirmed != true || !mounted) return;

    try {
      await context.read<CoursesController>().deleteCourse(course.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete course: $e')),
      );
    }
  }

  Future<void> _openCourse(Course course) async {
    final ctrl = context.read<CoursesController>();

    try {
      final lessons = await ctrl.fetchLessons(course.id);
      if (!mounted) return;

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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load lessons: $e')),
      );
    }
  }

  void _maybeHandleInitialCourseJump(CoursesController ctrl) {
    if (_initialJumpHandled || _initialCourseId == null || ctrl.isLoading) return;
    _initialJumpHandled = true;
    for (final course in ctrl.courses) {
      if (course.id == _initialCourseId) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openCourse(course);
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<CoursesController>();
    _maybeHandleInitialCourseJump(ctrl);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
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
                onTapCourse: _openCourse,
                onDeleteCourse: _confirmDelete,
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openGenerateCoursePopup(BuildContext context) async {
    final ctrl = context.read<CoursesController>();

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 280),
      transitionBuilder: (ctx, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutQuart,
          reverseCurve: Curves.easeInQuart,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
      pageBuilder: (ctx, _, __) => GenerateCoursePopup(
        onSubmitPrompt: (prompt) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: ctrl,
                child: GenerateCoursePage(prompt: prompt),
              ),
            ),
          );
        },
        onSubmitMetrics: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChangeNotifierProvider.value(
                value: ctrl,
                child: const GenerateCoursePage(),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CoursesGrid extends StatelessWidget {
  const _CoursesGrid({
    required this.courses,
    required this.onTapCourse,
    required this.onDeleteCourse,
  });

  final List<Course> courses;
  final void Function(Course course) onTapCourse;
  final void Function(Course course) onDeleteCourse;

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
          onDelete: () => onDeleteCourse(course),
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

// ---------------------------------------------------------------------------
// Delete course confirmation dialog
// ---------------------------------------------------------------------------

class _DeleteCourseDialog extends StatefulWidget {
  const _DeleteCourseDialog({required this.courseTitle});

  final String courseTitle;

  @override
  State<_DeleteCourseDialog> createState() => _DeleteCourseDialogState();
}

class _DeleteCourseDialogState extends State<_DeleteCourseDialog>
    with TickerProviderStateMixin {
  // Icon pops in with a scale entrance after the dialog settles.
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;

  // Content stagger: title → body → actions fade+slide up sequentially.
  late final AnimationController _contentCtrl;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _bodyFade;
  late final Animation<Offset> _bodySlide;
  late final Animation<double> _actionsFade;
  late final Animation<Offset> _actionsSlide;

  static const _slideBegin = Offset(0, 0.28);

  @override
  void initState() {
    super.initState();

    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _iconScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _iconCtrl, curve: Curves.easeOutQuart),
    );

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Title: first to appear.
    _titleFade = CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(begin: _slideBegin, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.0, 0.60, curve: Curves.easeOutQuart),
      ),
    );

    // Body: slightly delayed behind title.
    _bodyFade = CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.18, 0.72, curve: Curves.easeOut),
    );
    _bodySlide = Tween<Offset>(begin: _slideBegin, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.18, 0.75, curve: Curves.easeOutQuart),
      ),
    );

    // Actions: last to appear.
    _actionsFade = CurvedAnimation(
      parent: _contentCtrl,
      curve: const Interval(0.38, 0.90, curve: Curves.easeOut),
    );
    _actionsSlide = Tween<Offset>(begin: _slideBegin, end: Offset.zero).animate(
      CurvedAnimation(
        parent: _contentCtrl,
        curve: const Interval(0.38, 0.92, curve: Curves.easeOutQuart),
      ),
    );

    // Icon starts after dialog entrance settles; content stagger begins slightly
    // earlier so both sequences complete around the same time.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _iconCtrl.forward();
    });
    Future.delayed(const Duration(milliseconds: 80), () {
      if (mounted) _contentCtrl.forward();
    });
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        side: const BorderSide(color: AppColors.border),
      ),
      icon: ScaleTransition(
        scale: _iconScale,
        child: const Icon(
          Icons.delete_forever_rounded,
          color: AppColors.failure,
          size: 32,
        ),
      ),
      title: FadeTransition(
        opacity: _titleFade,
        child: SlideTransition(
          position: _titleSlide,
          child: Text(
            'Delete course?',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
      content: FadeTransition(
        opacity: _bodyFade,
        child: SlideTransition(
          position: _bodySlide,
          child: Text(
            '"${widget.courseTitle}" will be permanently removed. This cannot be undone.',
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
      actions: [
        FadeTransition(
          opacity: _actionsFade,
          child: SlideTransition(
            position: _actionsSlide,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        FadeTransition(
          opacity: _actionsFade,
          child: SlideTransition(
            position: _actionsSlide,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppColors.failure),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}