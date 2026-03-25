import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../models/pronunciation_feedback.dart';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class PracticeResultsPage extends StatelessWidget {
  const PracticeResultsPage({
    super.key,
    required this.feedbacks,
    this.lessonTitle,
  });

  final List<PronunciationFeedbackMock> feedbacks;
  final String? lessonTitle;

  // -------------------------------------------------------------------------
  // Computed averages
  // -------------------------------------------------------------------------

  double get _avgAccuracy {
    if (feedbacks.isEmpty) return 0;
    return feedbacks.map((f) => f.accuracyScore).reduce((a, b) => a + b) /
        feedbacks.length;
  }

  double get _avgFluency {
    if (feedbacks.isEmpty) return 0;
    return feedbacks.map((f) => f.fluencyScore).reduce((a, b) => a + b) /
        feedbacks.length;
  }

  double get _avgCompleteness {
    if (feedbacks.isEmpty) return 0;
    return feedbacks.map((f) => f.completenessScore).reduce((a, b) => a + b) /
        feedbacks.length;
  }

  double get _avgOverall {
    final withPron = feedbacks.where((f) => f.pronScore != null).toList();
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
      return 'Excellent work! Your pronunciation is really sharp — keep it up.';
    }
    if (avg >= 70) {
      return 'Great job! A little more practice and you\'ll be sounding like a native.';
    }
    if (avg >= 55) {
      return 'Good effort! Focus on the words that tripped you up and you\'ll see fast progress.';
    }
    return 'Keep going! Consistent daily practice is the fastest path to improvement.';
  }

  String get _greetingHeadline {
    final avg = _avgOverall;
    if (avg >= 85) return 'Outstanding!';
    if (avg >= 70) return 'Great Work!';
    if (avg >= 55) return 'Well Done!';
    return 'Keep It Up!';
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
            // Back button row
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              ),
            ),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.lg),

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
                      lessonTitle ?? 'Practice Session',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.publicSans(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Score grid
                    Row(
                      children: [
                        Expanded(
                          child: _ScoreRing(
                            label: 'Accuracy',
                            score: _avgAccuracy,
                            color: _scoreColor(_avgAccuracy),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _ScoreRing(
                            label: 'Fluency',
                            score: _avgFluency,
                            color: _scoreColor(_avgFluency),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: _ScoreRing(
                            label: 'Completeness',
                            score: _avgCompleteness,
                            color: _scoreColor(_avgCompleteness),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _ScoreRing(
                            label: 'Overall',
                            score: _avgOverall,
                            color: _scoreColor(_avgOverall),
                            isHighlighted: true,
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
                      '${feedbacks.length} of ${feedbacks.length} exercise${feedbacks.length == 1 ? '' : 's'} completed',
                      style: GoogleFonts.publicSans(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

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
                    backgroundColor: AppColors.accent,
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
  });

  final String label;
  final double score;
  final Color color;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final displayScore = score.round().clamp(0, 100);

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
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
          // Circular progress ring with score overlaid
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _RingPainter(
                    progress: (score / 100).clamp(0.0, 1.0),
                    color: color,
                    trackColor: AppColors.border,
                    strokeWidth: 6,
                  ),
                ),
                Center(
                  child: Text(
                    '$displayScore',
                    style: GoogleFonts.inter(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            label,
            style: GoogleFonts.publicSans(
              color: isHighlighted ? AppColors.textPrimary : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.w600 : FontWeight.w500,
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
