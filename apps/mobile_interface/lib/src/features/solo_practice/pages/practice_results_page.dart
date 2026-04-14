import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../courses/controllers/courses_controller.dart';
import '../../courses/models/lesson.dart';
import '../../courses/models/lesson_item.dart';
import '../../progress/services/progress_service.dart';
import '../models/pronunciation_feedback.dart';
import '../widgets/interactive_feedback_sentence.dart';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class PracticeResultsPage extends StatefulWidget {
  const PracticeResultsPage({
    super.key,
    required this.feedbacks,
    required this.items,
    this.lesson,
    this.sessionDuration = Duration.zero,
  });

  final List<PronunciationFeedbackMock> feedbacks;

  /// The ordered lesson items practiced — one per feedback entry.
  final List<LessonItem> items;

  /// The completed lesson. When provided, the server is notified of completion
  /// on mount (best-effort, non-blocking).
  final Lesson? lesson;
  final Duration sessionDuration;

  @override
  State<PracticeResultsPage> createState() => _PracticeResultsPageState();
}

class _PracticeResultsPageState extends State<PracticeResultsPage> {
  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _notifyLessonComplete();
    _submitPhonemeScores();
    _submitDailyMinutes();
  }

  void _notifyLessonComplete() {
    final lesson = widget.lesson;
    if (lesson == null || lesson.isCompleted) return;

    // Fire-and-forget: we don't await or show any loading state here so the
    // results page renders immediately. Failures are swallowed in the controller.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<CoursesController>()
          .completeLesson(lesson.courseId, lesson.id);
    });
  }

  /// Fire-and-forget: aggregate all phoneme scores from the session and send
  /// them to the progress-service for persistent weighted-average storage.
  ///
  /// Runs after the first frame so the results UI renders immediately.
  /// Errors are swallowed inside [ProgressService.submitPhonemeScores].
  void _submitPhonemeScores() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<ProgressService>()
          .submitPhonemeScores(widget.feedbacks);
    });
  }

  /// Fire-and-forget: add this session's active practice time to today's goal.
  void _submitDailyMinutes() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ProgressService>().submitDailyMinutes(
            secondsDelta: widget.sessionDuration.inSeconds,
          );
    });
  }

  List<PronunciationFeedbackMock> get _feedbacks => widget.feedbacks;

  // -------------------------------------------------------------------------
  // Computed averages
  // -------------------------------------------------------------------------

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
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // Headline + lesson name — left-aligned, immediate
                    Text(
                      _greetingHeadline,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.lesson?.title ?? 'Practice Session',
                      style: GoogleFonts.publicSans(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Hero score — large typographic number, no ring
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_avgOverall.round().clamp(0, 100)}',
                            style: GoogleFonts.inter(
                              color: _scoreColor(_avgOverall),
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
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Three flat metric columns — plain numbers, no rings
                    IntrinsicHeight(
                      child: Row(
                        children: [
                          _MetricColumn(label: 'Accuracy', score: _avgAccuracy),
                          VerticalDivider(
                            color: AppColors.border,
                            width: 1,
                            thickness: 1,
                          ),
                          _MetricColumn(label: 'Fluency', score: _avgFluency),
                          VerticalDivider(
                            color: AppColors.border,
                            width: 1,
                            thickness: 1,
                          ),
                          _MetricColumn(
                            label: 'Completeness',
                            score: _avgCompleteness,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Motivational message
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
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

                    // Session breakdown
                    if (_feedbacks.isNotEmpty && widget.items.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),

                      // Header row with exercise count inline
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
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

                      // Tiles without heavy outer border — surface bg + clip only
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        child: ColoredBox(
                          color: AppColors.surface,
                          child: Column(
                            children: [
                              for (int i = 0;
                                  i < math.min(widget.items.length, _feedbacks.length);
                                  i++) ...[
                                if (i > 0)
                                  const Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: AppColors.border,
                                  ),
                                _ItemBreakdownTile(
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

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // Back to Courses button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil(AppRoutes.courses, (_) => false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.action,
                    foregroundColor: AppColors.primaryBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Text(
                    'Back to Courses',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBg,
                    ).copyWith(inherit: false),
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

// ---------------------------------------------------------------------------
// Session breakdown — per-item expandable tile
// ---------------------------------------------------------------------------

/// An [ExpansionTile] row showing one lesson item's score summary; expands to
/// reveal word-level feedback chips and the reference text.
class _ItemBreakdownTile extends StatelessWidget {
  const _ItemBreakdownTile({
    required this.index,
    required this.item,
    required this.feedback,
  });

  final int index;
  final LessonItem item;
  final PronunciationFeedbackMock feedback;

  double get _overallScore {
    if (feedback.pronScore != null) return feedback.pronScore!;
    return (feedback.accuracyScore + feedback.fluencyScore + feedback.completenessScore) / 3;
  }

  Color _scoreColor(double score) {
    if (score >= 85) return AppColors.success;
    if (score >= 60) return AppColors.action;
    return AppColors.failure;
  }

  @override
  Widget build(BuildContext context) {
    final score = _overallScore;
    final color = _scoreColor(score);

    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    return Theme(
      // Remove the default ExpansionTile divider lines injected by the theme.
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md,
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Text(
            '${score.round()}',
            style: GoogleFonts.inter(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        title: Text(
          item.text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.publicSans(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Exercise ${index + 1}',
          style: bodyStyle.copyWith(fontSize: 11),
        ),
        iconColor: AppColors.textSecondary,
        collapsedIconColor: AppColors.textSecondary,
        children: [
          // ----------------------------------------------------------------
          // Expanded body — word chips + reference text
          // ----------------------------------------------------------------

          if (feedback.words.isNotEmpty) ...[
            InteractiveFeedbackSentence(
              referenceText: item.text,
              feedback: feedback,
              textStyle: GoogleFonts.publicSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap any word for phoneme feedback',
              style: bodyStyle.copyWith(fontSize: 11),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],

          const SizedBox(height: AppSpacing.xs),

          // Mini score row
          Row(
            children: [
              _MiniScoreChip(label: 'Accuracy', score: feedback.accuracyScore),
              const SizedBox(width: AppSpacing.xs),
              _MiniScoreChip(label: 'Fluency', score: feedback.fluencyScore),
              const SizedBox(width: AppSpacing.xs),
              _MiniScoreChip(label: 'Complete', score: feedback.completenessScore),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact inline score chip used inside the breakdown tile.
class _MiniScoreChip extends StatelessWidget {
  const _MiniScoreChip({required this.label, required this.score});

  final String label;
  final double score;

  Color get _color {
    if (score >= 85) return AppColors.success;
    if (score >= 60) return AppColors.action;
    return AppColors.failure;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: _color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${score.round()}',
              style: GoogleFonts.inter(
                color: _color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.publicSans(
                color: AppColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Flat metric column — label + bold number, no ring
// ---------------------------------------------------------------------------

class _MetricColumn extends StatelessWidget {
  const _MetricColumn({required this.label, required this.score});

  final String label;
  final double score;

  Color get _color {
    if (score >= 85) return AppColors.success;
    if (score >= 60) return AppColors.action;
    return AppColors.failure;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${score.round().clamp(0, 100)}',
              style: GoogleFonts.inter(
                color: _color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.publicSans(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
