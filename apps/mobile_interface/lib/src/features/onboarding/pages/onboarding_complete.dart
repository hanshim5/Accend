import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../courses/controllers/courses_controller.dart';
import '../../courses/widgets/generation_logo_ring.dart';
import '../controllers/onboarding_controller.dart';

const _kGoalTitles = <String, String>{
  'travel': 'Travel',
  'career': 'Career',
  'culture': 'Culture',
  'brain_training': 'Brain Training',
};

enum _SeedingState {
  loading,
  success,
  failure,
}

class OnboardingCompletePage extends StatefulWidget {
  const OnboardingCompletePage({super.key});

  @override
  State<OnboardingCompletePage> createState() => _OnboardingCompletePageState();
}

class _OnboardingCompletePageState extends State<OnboardingCompletePage> {
  _SeedingState _state = _SeedingState.loading;
  bool _kickedOff = false;

  /// Total goals for this onboarding session (fixed after first parse).
  int _sessionTotal = 0;

  /// Successfully seeded courses in this session (for progress "(n of total)").
  int _completedCount = 0;

  /// Goals not yet successfully persisted; retried subset after partial failure.
  List<String> _pendingGoals = [];

  String _loadingGoalKey = '';
  String? _focusAreasCsv;

  bool get _isServiceUnavailable =>
      (_errorText ?? '').contains('503');

  String? _errorText;

  String get _displayError {
    if (_isServiceUnavailable) {
      return 'The AI is temporarily busy due to high demand. Please try again in a moment.';
    }
    final raw = _errorText ?? '';
    final prefixPattern = RegExp(r'^ApiException\(\d+\):\s*');
    if (prefixPattern.hasMatch(raw)) {
      return raw.replaceFirst(prefixPattern, '');
    }
    if (raw.isEmpty) {
      return 'Something went wrong while creating your starter courses. Please try again.';
    }
    return raw;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kickoffIfNeeded();
    });
  }

  void _kickoffIfNeeded() {
    if (_kickedOff) return;
    _kickedOff = true;
    _prepareAndRun();
  }

  Future<void> _prepareAndRun() async {
    final oc = context.read<OnboardingController>();
    final goals = CoursesController.orderedOnboardingLearningGoals(
      oc.data.learningGoal,
    );
    _focusAreasCsv = oc.data.focusAreas;

    if (goals.isEmpty) {
      if (!mounted) return;
      setState(() => _state = _SeedingState.success);
      return;
    }

    if (_sessionTotal == 0) {
      _sessionTotal = goals.length;
      _pendingGoals = List<String>.from(goals);
      _loadingGoalKey = _pendingGoals.first;
    }

    await _runSeedingLoop();
  }

  Future<void> _runSeedingLoop() async {
    if (!mounted) return;
    setState(() {
      _state = _SeedingState.loading;
      _errorText = null;
    });

    final focus = _focusAreasCsv;
    final ctrl = context.read<CoursesController>();

    while (_pendingGoals.isNotEmpty) {
      final goal = _pendingGoals.first;
      if (!mounted) return;
      setState(() {
        _loadingGoalKey = goal;
      });

      final res = await ctrl.seedSingleOnboardingCourse(
        learningGoal: goal,
        focusAreasCsv: focus,
      );

      if (!mounted) return;

      if (res == null) {
        setState(() {
          _state = _SeedingState.failure;
          _errorText = ctrl.generateError ??
              'Could not create your starter courses. Please try again.';
        });
        return;
      }

      _completedCount++;
      _pendingGoals.removeAt(0);
    }

    if (!mounted) return;
    setState(() => _state = _SeedingState.success);
  }

  void _goHome() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.shell);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: _state != _SeedingState.loading,
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
      case _SeedingState.loading:
        return _buildLoading(textTheme);
      case _SeedingState.success:
        return _buildSuccess(textTheme);
      case _SeedingState.failure:
        return _buildFailure(textTheme);
    }
  }

  Widget _buildLoading(TextTheme textTheme) {
    final label = _kGoalTitles[_loadingGoalKey] ?? _loadingGoalKey;
    final progress = _sessionTotal == 0
        ? ''
        : ' (${_completedCount + 1} of $_sessionTotal)';

    return Column(
      key: const ValueKey('loading'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const GenerationLogoRing(
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
          _sessionTotal == 0
              ? 'Preparing your personalized starter courses.'
              : 'Creating your $label course$progress.',
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
        const GenerationLogoRing(
          color: AppColors.success,
          loading: false,
        ),
        const SizedBox(height: 28),
        Text(
          'All set!',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _sessionTotal == 0
              ? 'Welcome to Accend. Head home to explore.'
              : 'Your starter courses are ready on the Courses tab.',
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
            onPressed: _goHome,
            child: const Text('Go to Home'),
          ),
        ),
      ],
    );
  }

  Widget _buildFailure(TextTheme textTheme) {
    return Column(
      key: const ValueKey('failure'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const GenerationLogoRing(
          color: AppColors.failure,
          loading: false,
        ),
        const SizedBox(height: 28),
        Text(
          'Couldn\'t finish setup',
          textAlign: TextAlign.center,
          style: textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          _displayError,
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
            onPressed: _runSeedingLoop,
            child: const Text('Try Again'),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: _goHome,
          child: Text(
            'GO TO HOME ANYWAY',
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
