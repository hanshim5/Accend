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
import '../widgets/feedback_card.dart';

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
                  children: [
                    // Same vertical space as the old top bar row (no back control).
                    const SizedBox(height: kToolbarHeight),
                    const SizedBox(height: AppSpacing.sm),

                    // Trophy glow icon
                    _TrophyIcon(overallScore: _avgOverall),

                    const SizedBox(height: AppSpacing.lg),

                    // Headline
                    Text(
                      _greetingHeadline,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Lesson name
                    Text(
                      widget.lesson?.title ?? 'Practice Session',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.publicSans(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Primary overall score (larger, under hero text)
                    Center(
                      child: _ScoreRing(
                        label: 'Overall',
                        score: _avgOverall,
                        color: _scoreColor(_avgOverall),
                        isHighlighted: true,
                        ringSize: 128,
                        scoreFontSize: 34,
                        labelFontSize: 14,
                        ringStrokeWidth: 8,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Secondary metrics in one row
                    Row(
                      children: [
                        Expanded(
                          child: _ScoreRing(
                            label: 'Accuracy',
                            score: _avgAccuracy,
                            color: _scoreColor(_avgAccuracy),
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _ScoreRing(
                            label: 'Fluency',
                            score: _avgFluency,
                            color: _scoreColor(_avgFluency),
                            compact: true,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: _ScoreRing(
                            label: 'Completeness',
                            score: _avgCompleteness,
                            color: _scoreColor(_avgCompleteness),
                            compact: true,
                          ),
                        ),
                      ],
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
                            size: 20,
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

                    const SizedBox(height: AppSpacing.lg),

                    // Cards completed count
                    Text(
                      '${_feedbacks.length} of ${_feedbacks.length} exercise${_feedbacks.length == 1 ? '' : 's'} completed',
                      style: GoogleFonts.publicSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    // -------------------------------------------------------
                    // Session breakdown — expandable per-item feedback list
                    // -------------------------------------------------------
                    if (_feedbacks.isNotEmpty && widget.items.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Session Breakdown',
                          style: GoogleFonts.inter(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.lg),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
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

  /// Show the phoneme-breakdown dialog for a single [word].
  void _showWordPhonemeDialog(BuildContext context, WordFeedback word) {
    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            word.text,
            style: GoogleFonts.inter(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: word.phonemes.isEmpty
              ? Text(
                  'No phoneme data available for this word.',
                  style: bodyStyle,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'You said:',
                      style: bodyStyle.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in word.phonemes)
                          ActionChip(
                            onPressed: () => showDialog<void>(
                              context: dialogContext,
                              builder: (_) => PhonemeDetailDialog(
                                symbol: p.userSaid ?? p.symbol,
                                accuracy: p.accuracy,
                                chipColor: userSaidPhonemeColor(p),
                              ),
                            ),
                            label: Text(
                              p.userSaid ?? p.symbol,
                              style: bodyStyle.copyWith(
                                color: userSaidPhonemeColor(p),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.inputFill,
                            shape: const StadiumBorder(
                              side: BorderSide(color: AppColors.border),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Should be:',
                      style: bodyStyle.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final p in word.phonemes)
                          ActionChip(
                            onPressed: () => showDialog<void>(
                              context: dialogContext,
                              builder: (_) => PhonemeDetailDialog(
                                symbol: p.symbol,
                                chipColor: AppColors.textPrimary,
                              ),
                            ),
                            label: Text(
                              p.symbol,
                              style: bodyStyle.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            backgroundColor: AppColors.inputFill,
                            shape: const StadiumBorder(
                              side: BorderSide(color: AppColors.border),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap any phoneme to hear how to say it.',
                      style: bodyStyle.copyWith(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
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
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'You said:',
                style: bodyStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final w in feedback.words)
                  ActionChip(
                    onPressed: w.phonemes.isEmpty
                        ? null
                        : () => _showWordPhonemeDialog(context, w),
                    backgroundColor: AppColors.inputFill,
                    shape: const StadiumBorder(
                      side: BorderSide(color: AppColors.border),
                    ),
                    label: Text(
                      w.text,
                      style: bodyStyle.copyWith(
                        color: feedbackScoreColor(w.accuracy),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
          ],

          if (feedback.words.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap a word to see phoneme breakdown.',
              style: bodyStyle.copyWith(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
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
// Trophy icon with glow
// ---------------------------------------------------------------------------

class _TrophyIcon extends StatelessWidget {
  const _TrophyIcon({required this.overallScore});

  final double overallScore;

  Color get _glowColor {
    if (overallScore >= 85) return AppColors.success;
    if (overallScore >= 60) return AppColors.action;
    return AppColors.accent;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer glow ring
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _glowColor.withValues(alpha: 0.25),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        // Icon container
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: _glowColor.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: Icon(
            Icons.emoji_events_rounded,
            size: 52,
            color: _glowColor,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Score ring card
// ---------------------------------------------------------------------------

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({
    required this.label,
    required this.score,
    required this.color,
    this.isHighlighted = false,
    this.compact = false,
    this.ringSize = 72,
    this.scoreFontSize = 20,
    this.labelFontSize = 12,
    this.ringStrokeWidth = 6,
  });

  final String label;
  final double score;
  final Color color;
  final bool isHighlighted;
  /// Smaller ring + typography for the three-metric row.
  final bool compact;
  final double ringSize;
  final double scoreFontSize;
  final double labelFontSize;
  final double ringStrokeWidth;

  @override
  Widget build(BuildContext context) {
    final displayScore = score.round().clamp(0, 100);
    final effectiveRingSize = compact ? 58.0 : ringSize;
    final effectiveScoreSize = compact ? 15.0 : scoreFontSize;
    final effectiveLabelSize = compact ? 10.0 : labelFontSize;
    final effectiveStroke = compact ? 4.5 : ringStrokeWidth;
    final verticalPad = compact ? AppSpacing.sm : AppSpacing.md;
    final horizontalPad = compact ? AppSpacing.xs : AppSpacing.sm;

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: verticalPad,
        horizontal: horizontalPad,
      ),
      decoration: BoxDecoration(
        color: isHighlighted
            ? color.withValues(alpha: 0.08)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: isHighlighted ? color.withValues(alpha: 0.4) : AppColors.border,
          width: isHighlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            width: effectiveRingSize,
            height: effectiveRingSize,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _RingPainter(
                    progress: (score / 100).clamp(0.0, 1.0),
                    color: color,
                    trackColor: AppColors.border,
                    strokeWidth: effectiveStroke,
                  ),
                ),
                Center(
                  child: Text(
                    '$displayScore',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: effectiveScoreSize,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),

          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.publicSans(
              color: isHighlighted ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: effectiveLabelSize,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom ring painter (arc from top, clockwise)
// ---------------------------------------------------------------------------

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    const startAngle = -math.pi / 2; // top

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      2 * math.pi,
      false,
      trackPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
}
