import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../controllers/courses_controller.dart';
import '../widgets/start_lesson_popup.dart';

class GenerateCoursePage extends StatefulWidget {
  /// Prompt-based generation: the user's free-text topic.
  /// Omit (leave null) for phoneme-metrics-based generation.
  const GenerateCoursePage({
    super.key,
    this.prompt,
  });

  final String? prompt;

  /// True when generating from phoneme metrics rather than a user prompt.
  bool get isMetricsMode => prompt == null;

  @override
  State<GenerateCoursePage> createState() => _GenerateCoursePageState();
}

enum _GenerationState {
  loading,
  success,
  failure,
}

class _GenerateCoursePageState extends State<GenerateCoursePage> {
  _GenerationState _state = _GenerationState.loading;
  GeneratedCourseResult? _result;
  String? _error;
  bool _started = false;

  /// True when the error is specifically "no phoneme data" (HTTP 422).
  /// In this case "Try Again" is hidden — retrying won't help.
  bool get _isNoDataError =>
      widget.isMetricsMode && ((_error ?? '').contains('422'));

  /// True when the AI backend is temporarily overloaded (HTTP 503).
  bool get _isServiceUnavailable => (_error ?? '').contains('503');

  /// User-facing error message — never shows raw JSON or exception strings.
  String get _displayError {
    if (_isNoDataError) return '';
    if (_isServiceUnavailable) {
      return 'The AI is temporarily busy due to high demand. Please try again in a moment.';
    }
    final raw = _error ?? '';
    // Strip the "ApiException(NNN): " prefix if present, show just the detail.
    final prefixPattern = RegExp(r'^ApiException\(\d+\):\s*');
    return prefixPattern.hasMatch(raw)
        ? raw.replaceFirst(prefixPattern, '')
        : 'There was an error generating your course. Please try again.';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runGeneration();
    });
  }

  Future<void> _runGeneration() async {
    if (_started) return;
    _started = true;

    final ctrl = context.read<CoursesController>();

    final result = widget.isMetricsMode
        ? await ctrl.generateCourseFromMetrics()
        : await ctrl.generateCourse(widget.prompt!);

    if (!mounted) return;

    if (result != null) {
      setState(() {
        _result = result;
        _state = _GenerationState.success;
      });
    } else {
      setState(() {
        _error = ctrl.generateError ?? 'Could not generate course. Please try again.';
        _state = _GenerationState.failure;
      });
    }
  }

  Future<void> _openStartCourse() async {
    final result = _result;
    if (result == null) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StartLessonPopup(
        course: result.course,
        lessons: result.lessons,
        onStart: (lesson) {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacementNamed(
            AppRoutes.soloPractice,
            arguments: lesson,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: _state != _GenerationState.loading,
      child: Scaffold(
        backgroundColor: AppColors.primaryBg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _buildStateView(textTheme),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStateView(TextTheme textTheme) {
    switch (_state) {
      case _GenerationState.loading:
        return _buildLoading(textTheme);
      case _GenerationState.success:
        return _buildSuccess(textTheme);
      case _GenerationState.failure:
        return _buildFailure(textTheme);
    }
  }

  Widget _buildLoading(TextTheme textTheme) {
    return Column(
      key: const ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _GenerationLogoRing(
          color: AppColors.accent,
          loading: true,
        ),
        const SizedBox(height: 28),
        Text(
          'Ascending your curriculum...',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.isMetricsMode
              ? 'Our AI is analysing your pronunciation data and crafting a targeted course.'
              : 'Our AI is crafting a personalized course for "${widget.prompt}".',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildSuccess(TextTheme textTheme) {
    return Column(
      key: const ValueKey('success'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _GenerationLogoRing(
          color: AppColors.success,
          loading: false,
        ),
        const SizedBox(height: 28),
        Text(
          'Course Ready!',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _result == null
              ? 'Your personalized course has been created.'
              : '"${_result!.course.title}" is ready to begin.',
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _openStartCourse,
            child: const Text('Start Course'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'BACK TO COURSES',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFailure(TextTheme textTheme) {
    final isNoData = _isNoDataError;

    return Column(
      key: const ValueKey('failure'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _GenerationLogoRing(
          color: isNoData ? AppColors.action : AppColors.failure,
          loading: false,
        ),
        const SizedBox(height: 28),
        Text(
          isNoData ? 'No Practice Data Yet' : 'Generation Failed',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isNoData
              ? 'Complete at least one pronunciation session first. Your phoneme scores will be used to build a course targeted at your weakest sounds.'
              : _displayError,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        if (!isNoData) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _state = _GenerationState.loading;
                  _error = null;
                  _result = null;
                });
                _started = false;
                _runGeneration();
              },
              child: const Text('Try Again'),
            ),
          ),
          const SizedBox(height: 10),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            isNoData ? 'BACK TO COURSES' : 'RETURN TO COURSES',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _GenerationLogoRing extends StatelessWidget {
  const _GenerationLogoRing({
    required this.color,
    required this.loading,
  });

  final Color color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withValues(alpha: 0.9),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          if (loading)
            const SizedBox(
              width: 148,
              height: 148,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                backgroundColor: Colors.transparent,
              ),
            ),
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryBg,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Image.asset(
                'assets/images/accend_logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.school_rounded,
                  color: color,
                  size: 36,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
