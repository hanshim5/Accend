import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/constants.dart';
import '../widgets/pronunciation_metric_column.dart';
import '../widgets/session_breakdown_tile.dart';
import '../../features/courses/models/lesson_item.dart';
import '../models/pronunciation_feedback.dart';

// ---------------------------------------------------------------------------
// Unified session results page
//
// Used by both solo practice and group sessions. The only differences between
// the two contexts are surfaced as constructor parameters:
//   • [sessionTitle]   — subtitle shown under the greeting headline
//   • [ctaLabel]       — text on the primary action button
//   • [onCtaTap]       — navigation/action owned entirely by the caller
//   • [onMount]        — optional side-effect hook (lesson completion, progress
//                        submission, etc.) called after the first frame with
//                        this page's [BuildContext]
//   • [motivationalMessageOverride] — optional copy override per score tier
// ---------------------------------------------------------------------------

class SessionResultsPage extends StatefulWidget {
  const SessionResultsPage({
    super.key,
    required this.feedbacks,
    required this.items,
    required this.sessionTitle,
    required this.ctaLabel,
    required this.onCtaTap,
    this.sessionDuration = Duration.zero,
    this.onMount,
    this.motivationalMessageOverride,
  });

  /// One feedback entry per exercise, in order.
  final List<PronunciationFeedbackMock> feedbacks;

  /// The ordered lesson items practiced — parallel to [feedbacks].
  final List<LessonItem> items;

  /// Subtitle displayed beneath the greeting headline (e.g. lesson title or
  /// "Group Session").
  final String sessionTitle;

  /// Label on the primary CTA button (e.g. "Back to Courses").
  final String ctaLabel;

  /// Called when the user taps the CTA. Receives this page's [BuildContext]
  /// so the caller can call [Navigator] without keeping a reference.
  final void Function(BuildContext context) onCtaTap;

  /// Active practice time — used to submit daily-goal minutes.
  final Duration sessionDuration;

  /// Optional hook fired once after the first frame. Receives this page's
  /// [BuildContext] so callers can do provider reads (lesson completion,
  /// phoneme score submission, etc.) without coupling them into this page.
  final void Function(BuildContext context)? onMount;

  /// When non-null, overrides the default (solo-focused) motivational copy.
  /// Receives the computed average overall score and returns a message string.
  final String Function(double avgScore)? motivationalMessageOverride;

  @override
  State<SessionResultsPage> createState() => _SessionResultsPageState();
}

class _SessionResultsPageState extends State<SessionResultsPage>
    with TickerProviderStateMixin {
  // -------------------------------------------------------------------------
  // Animation fields
  // -------------------------------------------------------------------------

  late AnimationController _entrance;
  late AnimationController _glow;

  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _ruleWidthFactor;
  late Animation<double> _scoreFade;
  late Animation<double> _scoreScale;
  late Animation<double> _scoreCounter;
  late Animation<double> _metricsFade;
  late Animation<Offset> _metricsSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _breakdownFade;
  late Animation<Offset> _breakdownSlide;
  late Animation<Offset> _buttonSlide;

  // Post-entrance glow oscillation
  late Animation<double> _glowPulse;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fireOnMount();
    _initAnimations();
  }

  void _fireOnMount() {
    final hook = widget.onMount;
    if (hook == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) hook(context);
    });
  }

  void _initAnimations() {
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    );
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _glowPulse = Tween<double>(begin: 0.0, end: 1.0).animate(_glow);

    Animation<double> fade(double t0, double t1) => CurvedAnimation(
          parent: _entrance,
          curve: Interval(t0, t1, curve: Curves.easeOut),
        );

    Animation<Offset> slide(double t0, double t1,
            {Offset from = const Offset(0, 0.07)}) =>
        Tween<Offset>(begin: from, end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entrance,
            curve: Interval(t0, t1, curve: Curves.easeOutCubic),
          ),
        );

    _headlineFade = fade(0.00, 0.22);
    _headlineSlide = slide(0.00, 0.26, from: const Offset(-0.05, 0));

    _ruleWidthFactor = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.10, 0.30, curve: Curves.easeOutCubic),
    );

    _scoreFade = fade(0.15, 0.36);
    _scoreScale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.14, 0.50, curve: Curves.easeOutCubic),
      ),
    );
    _scoreCounter = Tween<double>(begin: 0, end: _avgOverall).animate(
      CurvedAnimation(
        parent: _entrance,
        curve: const Interval(0.16, 0.64, curve: Curves.easeOut),
      ),
    );

    _metricsFade = fade(0.40, 0.62);
    _metricsSlide = slide(0.40, 0.64);

    _cardFade = fade(0.50, 0.72);
    _cardSlide = slide(0.50, 0.74);

    _breakdownFade = fade(0.58, 0.80);
    _breakdownSlide = slide(0.58, 0.82);

    _buttonSlide = Tween<Offset>(
      begin: const Offset(0, 1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.72, 0.94, curve: Curves.easeOutCubic),
    ));

    _entrance.forward().then((_) {
      if (mounted) _glow.repeat(reverse: true);
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    try {
      _entrance.dispose();
      _glow.dispose();
    } catch (_) {}
    _initAnimations();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _glow.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Computed averages
  // -------------------------------------------------------------------------

  List<PronunciationFeedbackMock> get _feedbacks => widget.feedbacks;

  double get _avgAccuracy {
    if (_feedbacks.isEmpty) return 0;
    return _feedbacks.map((f) => f.accuracyScore).reduce((a, b) => a + b) /
        _feedbacks.length;
  }

  double get _avgFluency {
    if (_feedbacks.isEmpty) return 0;
    return _feedbacks.map((f) => f.fluencyScore).reduce((a, b) => a + b) /
        _feedbacks.length;
  }

  double get _avgCompleteness {
    if (_feedbacks.isEmpty) return 0;
    return _feedbacks.map((f) => f.completenessScore).reduce((a, b) => a + b) /
        _feedbacks.length;
  }

  double get _avgOverall {
    final withPron = _feedbacks.where((f) => f.pronScore != null).toList();
    if (withPron.isNotEmpty) {
      return withPron.map((f) => f.pronScore!).reduce((a, b) => a + b) /
          withPron.length;
    }
    return (_avgAccuracy + _avgFluency + _avgCompleteness) / 3;
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Color _scoreColor(double score) {
    if (score >= 85) return AppColors.success;
    if (score >= 60) return AppColors.action;
    return AppColors.failure;
  }

  String get _motivationalMessage {
    final avg = _avgOverall;
    final override = widget.motivationalMessageOverride;
    if (override != null) return override(avg);

    // Default solo-practice copy.
    if (avg >= 85) {
      return 'You\'re at the summit — your pronunciation is crisp and confident. Keep ascending!';
    }
    if (avg >= 70) {
      return 'You\'re well above base camp. A few more climbs like this and you\'ll own the peak.';
    }
    if (avg >= 55) {
      return 'Good footing! Study the words that slowed your ascent and the summit will come quickly.';
    }
    return 'Every climb starts with one step. Keep pushing upward — the view gets better every day.';
  }

  String get _greetingHeadline {
    final avg = _avgOverall;
    if (avg >= 85) return 'Summit Reached!';
    if (avg >= 70) return 'Ascending Fast!';
    if (avg >= 55) return 'Gaining Ground!';
    return 'Keep Climbing!';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Headline + accent rule + session title
                    FadeTransition(
                      opacity: _headlineFade,
                      child: SlideTransition(
                        position: _headlineSlide,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greetingHeadline,
                              style: GoogleFonts.inter(
                                color: AppColors.textPrimary,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedBuilder(
                              animation: _ruleWidthFactor,
                              builder: (_, __) => Container(
                                width: _ruleWidthFactor.value * 36,
                                height: 2.5,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          AppColors.accent.withOpacity(0.55),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.sessionTitle,
                              style: GoogleFonts.publicSans(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Hero score — count-up + scale entrance + post-entrance glow breath
                    FadeTransition(
                      opacity: _scoreFade,
                      child: ScaleTransition(
                        scale: _scoreScale,
                        child: Center(
                          child: AnimatedBuilder(
                            animation: Listenable.merge(
                                [_scoreCounter, _glowPulse]),
                            builder: (_, __) {
                              final displayScore = _scoreCounter.value;
                              final color = _scoreColor(_avgOverall);
                              final glowOpacity =
                                  0.13 + _glowPulse.value * 0.13;

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 180,
                                    height: 140,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              color.withOpacity(glowOpacity),
                                          blurRadius: 80,
                                          spreadRadius: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${displayScore.round().clamp(0, 100)}',
                                        style: GoogleFonts.inter(
                                          color: color,
                                          fontSize: 80,
                                          fontWeight: FontWeight.w800,
                                          height: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'OVERALL',
                                        style: GoogleFonts.publicSans(
                                          color: AppColors.textSecondary,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Three flat metric columns
                    FadeTransition(
                      opacity: _metricsFade,
                      child: SlideTransition(
                        position: _metricsSlide,
                        child: IntrinsicHeight(
                          child: Row(
                            children: [
                              PronunciationMetricColumn(
                                  label: 'Accuracy', score: _avgAccuracy),
                              VerticalDivider(
                                color: AppColors.border,
                                width: 1,
                                thickness: 1,
                              ),
                              PronunciationMetricColumn(
                                  label: 'Fluency', score: _avgFluency),
                              VerticalDivider(
                                color: AppColors.border,
                                width: 1,
                                thickness: 1,
                              ),
                              PronunciationMetricColumn(
                                label: 'Completeness',
                                score: _avgCompleteness,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Motivational message
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                                BorderRadius.circular(AppRadii.lg),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: AppColors.tip,
                                size: 24,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  _motivationalMessage,
                                  style: GoogleFonts.publicSans(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Session breakdown
                    if (_feedbacks.isNotEmpty &&
                        widget.items.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),

                      FadeTransition(
                        opacity: _breakdownFade,
                        child: SlideTransition(
                          position: _breakdownSlide,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    'Session Breakdown',
                                    style: GoogleFonts.inter(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_feedbacks.length} exercise${_feedbacks.length == 1 ? '' : 's'}',
                                    style: GoogleFonts.publicSans(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              ClipRRect(
                                borderRadius:
                                    BorderRadius.circular(AppRadii.lg),
                                child: ColoredBox(
                                  color: AppColors.surface,
                                  child: Column(
                                    children: [
                                      for (int i = 0;
                                          i <
                                              math.min(widget.items.length,
                                                  _feedbacks.length);
                                          i++) ...[
                                        if (i > 0)
                                          const Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: AppColors.border,
                                          ),
                                        SessionBreakdownTile(
                                          index: i,
                                          item: widget.items[i],
                                          feedback: _feedbacks[i],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // CTA — slides up from below on entrance
            SlideTransition(
              position: _buttonSlide,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.action.withOpacity(0.38),
                        blurRadius: 22,
                        spreadRadius: 0,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => widget.onCtaTap(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.action,
                        foregroundColor: AppColors.primaryBg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md),
                      ),
                      child: Text(
                        widget.ctaLabel,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryBg,
                        ).copyWith(inherit: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
