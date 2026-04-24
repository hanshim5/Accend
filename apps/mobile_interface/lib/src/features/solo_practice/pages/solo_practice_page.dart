import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../../common/models/pronunciation_feedback.dart';
import '../../../common/pages/session_results_page.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/widgets/microphone.dart';
import '../../courses/controllers/courses_controller.dart';
import '../../courses/models/lesson.dart';
import '../../home/controllers/home_controller.dart';
import '../../progress/services/progress_service.dart';
import '../controllers/solo_practice_controller.dart';
import '../../../common/widgets/interactive_feedback_sentence.dart';
import '../../../common/widgets/phoneme_feedback.dart';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class SoloPracticePage extends StatefulWidget {
  const SoloPracticePage({super.key, this.lesson});

  /// The lesson to practice. When null, falls back to built-in sample prompts.
  final Lesson? lesson;

  @override
  State<SoloPracticePage> createState() => _SoloPracticePageState();
}

class _SoloPracticePageState extends State<SoloPracticePage>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  late final SoloPracticeController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;
  bool _isSubmitting = false;
  DateTime? _activeStartedAt;
  Duration _accumulatedActive = Duration.zero;

  // ── Entrance animation ────────────────────────────────────────────────────
  late AnimationController _entrance;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late Animation<double> _bottomFade;

  void _initAnimations() {
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _cardFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
    ));
    _bottomFade = CurvedAnimation(
      parent: _entrance,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOut),
    );
    _entrance.forward();
  }

  @override
  void reassemble() {
    super.reassemble();
    // Guard: _entrance may not be initialized on the very first hot reload
    // after this animation code was introduced. Swallow the LateError so the
    // subsequent _initAnimations() call always succeeds.
    try {
      _entrance.dispose();
    } catch (_) {}
    _initAnimations();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pauseActiveTimer();
    _audioPlayer.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = SoloPracticeController(
      items: widget.lesson?.items,
    );
    _resumeActiveTimer();
    _initAnimations();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resumeActiveTimer();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _pauseActiveTimer();
    }
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  /// Called when the microphone widget transitions into recording.
  void _onRecordingStarted() {
    // Starting a new recording should discard any previous cached audio.
    _clearRecording();
    setState(() => _controller.advanceMicState());
  }

  /// Called when the microphone widget finishes recording and provides a file path.
  void _onRecordingStopped(String path) {
    setState(() {
      _recordingPath = path;
      _controller.advanceMicState();
    });
  }

  /// Resets the mic state back to idle (0) so the user can re-record
  /// without advancing to the next card.
  void _onRetryPressed() {
    _clearRecording();
    setState(() => _controller.retry());
  }

  /// Called when the microphone widget auto-stops after the recording time limit.
  void _onRecordingAutoStopped() {
    _clearRecording();
    setState(() => _controller.retry());
    showGeneralDialog<void>(
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
      pageBuilder: (ctx, _, __) => const _TimeUpDialog(),
    );
  }

  /// On Submit: load audio, call controller to fetch feedback and set state, then rebuild.
  Future<void> _onSubmitPressed() async {
    if (_recordingPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record audio before submitting.')),
      );
      return;
    }

    final file = File(_recordingPath!);
    if (!await file.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recorded audio file is unavailable. Please try again.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final bytes = await file.readAsBytes();
    final referenceText = _controller.currentCard;

    String? accessToken;
    try {
      accessToken = context.read<AuthService>().accessToken;
    } catch (_) {
      // AuthService not available (e.g. standalone debug mode).
    }

    await _controller.submit(
      audioBytes: bytes,
      referenceText: referenceText,
      accessToken: accessToken,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
  }

  /// "Try Again" from the feedback card: clear feedback + recording and let
  /// the user re-record the same item for a fresh grade.
  void _onFeedbackRetry() {
    _clearRecording();
    setState(() {
      _controller.setFeedback(null);
      _controller.retry(); // mic back to idle (state 0)
    });
  }

  /// After user taps Next on feedback: clear feedback, go to next card or show results page.
  void _advanceToNextCard() {
    _clearRecording();
    final hasMore = _controller.advanceToNextCard();
    if (hasMore) {
      setState(() {});
    } else {
      _pauseActiveTimer();
      final feedbacks = _controller.sessionFeedbacks;
      final items = _controller.items;
      final lesson = widget.lesson;
      final duration = _accumulatedActive;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => SessionResultsPage(
            feedbacks: feedbacks,
            items: items,
            sessionTitle: lesson?.title ?? 'Practice Session',
            sessionDuration: duration,
            ctaLabel: 'Back to Courses',
            onCtaTap: (ctx) => Navigator.of(ctx)
                .pushNamedAndRemoveUntil(AppRoutes.courses, (_) => false),
            onMount: (ctx) {
              if (lesson != null && !lesson.isCompleted) {
                ctx.read<CoursesController>().completeLesson(
                      lesson.courseId,
                      lesson.id,
                    );
              }
              ctx.read<ProgressService>().submitPhonemeScores(feedbacks);
              ctx.read<ProgressService>().submitDailyMinutes(
                    secondsDelta: duration.inSeconds,
                  );
              ctx.read<HomeController>().refreshProgressFromServer();
            },
          ),
        ),
      );
    }
  }

  /// Play the cached recording, if available.
  Future<void> _playRecording() async {
    if (_recordingPath == null) {
      return;
    }
    final file = File(_recordingPath!);
    if (!await file.exists()) {
      return;
    }
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(DeviceFileSource(_recordingPath!));
    } catch (_) {
      // Ignore playback errors for now.
    }
  }

  /// Delete the cached recording file (if present) and clear the path.
  void _clearRecording() {
    final path = _recordingPath;
    _recordingPath = null;
    if (path == null) return;
    final file = File(path);
    // Best-effort delete; ignore failures.
    file.delete().ignore();
  }

  void _resumeActiveTimer() {
    _activeStartedAt ??= DateTime.now();
  }

  void _pauseActiveTimer() {
    final startedAt = _activeStartedAt;
    if (startedAt == null) return;
    _accumulatedActive += DateTime.now().difference(startedAt);
    _activeStartedAt = null;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool showRetrySubmit = _controller.showRetrySubmit;
    final currentItem = _controller.currentItem;

    // --- Text styles ---

    final headingStyle = GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );

    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    final promptStyle = GoogleFonts.publicSans(
      color: AppColors.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w500,
    );

    final ipaStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
    );

    final scoreStyle = GoogleFonts.inter(
      color: AppColors.accent,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    );

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Column(
          children: [

            // -----------------------------------------------------------------
            // TOP SECTION — back button + progress bar
            // -----------------------------------------------------------------
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => _controller.resetSession());
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                Center(
                  child: SizedBox(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text('${_controller.currentCardIndex + 1}/${_controller.totalCards}', style: bodyStyle),
                            const Spacer(),
                            Text(
                              widget.lesson?.title ?? 'Practice',
                              style: headingStyle,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadii.sm),
                          child: LinearProgressIndicator(
                            value: _controller.progress,
                            minHeight: 8,
                            backgroundColor: AppColors.border,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // -----------------------------------------------------------------
            // MIDDLE SECTION — prompt card or inline feedback card
            // -----------------------------------------------------------------
            Expanded(
              child: FadeTransition(
                opacity: _cardFade,
                child: SlideTransition(
                  position: _cardSlide,
                  child: LayoutBuilder(
                builder: (context, constraints) {
                  // ConstrainedBox(minHeight) + Center ensures the content is
                  // vertically centred when it's shorter than the available
                  // space, while still allowing the scroll view to grow when
                  // the feedback card is taller than the viewport.
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          reverseDuration: const Duration(milliseconds: 180),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.96, end: 1.0)
                                  .animate(animation),
                              child: child,
                            ),
                          ),
                          child: _isSubmitting
                            ? Column(
                                key: const ValueKey<String>('loading'),
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const CircularProgressIndicator(
                                    color: AppColors.accent,
                                    strokeWidth: 3,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    'Analysing your pronunciation…',
                                    textAlign: TextAlign.center,
                                    style: bodyStyle,
                                  ),
                                ],
                              )
                            : _controller.currentFeedback == null
                                // ── Pre-submission: plain sentence card ───────
                                ? Column(
                                key: ValueKey<String>('pre-${_controller.currentCardIndex}'),
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xl,
                                          vertical: 40,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(AppRadii.lg),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              currentItem.text,
                                              textAlign: TextAlign.center,
                                              style: promptStyle,
                                            ),
                                            if (currentItem.ipa != null) ...[
                                              const SizedBox(height: 12),
                                              Text(
                                                currentItem.ipa!,
                                                textAlign: TextAlign.center,
                                                style: ipaStyle,
                                              ),
                                            ],
                                            if (currentItem.hint != null) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryBg,
                                                  borderRadius: BorderRadius.circular(AppRadii.sm),
                                                ),
                                                child: Text(
                                                  currentItem.hint!,
                                                  textAlign: TextAlign.center,
                                                  style: bodyStyle.copyWith(fontSize: 12),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        'Record yourself using the microphone button below!',
                                        textAlign: TextAlign.center,
                                        style: bodyStyle,
                                      ),
                                    ],
                                  )
                                // ── Post-submission: in-place color-coded sentence ─
                                : Padding(
                                    key: ValueKey<String>('post-${_controller.currentCardIndex}'),
                                    padding: const EdgeInsets.only(top: AppSpacing.md),
                                    child: Container(
                                      width: double.infinity,
                                      constraints: const BoxConstraints(maxWidth: 360),
                                      padding: const EdgeInsets.all(AppSpacing.lg),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(AppRadii.lg),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          // Color-coded sentence in place of the plain text.
                                          InteractiveFeedbackSentence(
                                            referenceText: currentItem.text,
                                            feedback: _controller.currentFeedback!,
                                            textStyle: promptStyle,
                                          ),
                                          if (currentItem.ipa != null) ...[
                                            const SizedBox(height: 12),
                                            Text(
                                              currentItem.ipa!,
                                              textAlign: TextAlign.center,
                                              style: ipaStyle,
                                            ),
                                          ],
                                          if (currentItem.hint != null) ...[
                                            const SizedBox(height: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primaryBg,
                                                borderRadius: BorderRadius.circular(AppRadii.sm),
                                              ),
                                              child: Text(
                                                currentItem.hint!,
                                                textAlign: TextAlign.center,
                                                style: bodyStyle.copyWith(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            'Tap any word for phoneme feedback',
                                            textAlign: TextAlign.center,
                                            style: bodyStyle.copyWith(fontSize: 12),
                                          ),
                                          const SizedBox(height: AppSpacing.md),
                                          // Overall scores row.
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                                            children: [
                                              ScoreChip(
                                                label: 'Accuracy',
                                                score: _controller.currentFeedback!.accuracyScore,
                                                style: scoreStyle,
                                                bodyStyle: bodyStyle,
                                              ),
                                              ScoreChip(
                                                label: 'Fluency',
                                                score: _controller.currentFeedback!.fluencyScore,
                                                style: scoreStyle,
                                                bodyStyle: bodyStyle,
                                              ),
                                              ScoreChip(
                                                label: 'Complete',
                                                score: _controller.currentFeedback!.completenessScore,
                                                style: scoreStyle,
                                                bodyStyle: bodyStyle,
                                              ),
                                            ],
                                          ),
                                          // ── AI Tips ──────────────────────────────
                                          if (_isLowScore(_controller.currentFeedback!)) ...[
                                            const SizedBox(height: AppSpacing.md),
                                            _AiTipsSection(
                                              cardIndex: _controller.currentCardIndex,
                                              controller: _controller,
                                              accessToken: () {
                                                try {
                                                  return context.read<AuthService>().accessToken;
                                                } catch (_) {
                                                  return null;
                                                }
                                              }(),
                                              onStateChanged: () => setState(() {}),
                                            ),
                                          ],
                                          const SizedBox(height: AppSpacing.lg),
                                          // Try Again / Next actions.
                                          Row(
                                            children: [
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: _onFeedbackRetry,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.surface,
                                                    foregroundColor: AppColors.textPrimary,
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(AppRadii.md),
                                                      side: const BorderSide(color: AppColors.border),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                                  ),
                                                  child: Text(
                                                    'Try Again',
                                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary).copyWith(inherit: false),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.sm),
                                              Expanded(
                                                child: ElevatedButton(
                                                  onPressed: _advanceToNextCard,
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: AppColors.action,
                                                    foregroundColor: const Color(0xFF101828),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(AppRadii.md),
                                                    ),
                                                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                                                  ),
                                                  child: Text(
                                                    _controller.currentCardIndex == _controller.totalCards - 1
                                                        ? 'Finish'
                                                        : 'Next',
                                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF101828)).copyWith(inherit: false),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                        ), // AnimatedSwitcher
                      ),
                    ),
                  );
                },
              ),
                  ), // SlideTransition
                ), // FadeTransition
            ),

            // -----------------------------------------------------------------
            // BOTTOM SECTION — Retry / mic button / Submit
            // Buttons always occupy Expanded slots on each side of the mic so
            // the mic stays centred; AnimatedOpacity fades them in/out and
            // IgnorePointer blocks taps when invisible — no layout jump.
            // -----------------------------------------------------------------
            FadeTransition(
              opacity: _bottomFade,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    // ── Left: Retry ─────────────────────────────────────────
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        opacity: showRetrySubmit ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !showRetrySubmit,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onRetryPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.surface,
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                                side: const BorderSide(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            ),
                            child: Text(
                              'Retry',
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary).copyWith(inherit: false),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // ── Centre: Mic button (always visible) ─────────────────
                    _AnimatedMicButton(
                      micStateIndex: _controller.micStateIndex,
                      onPlayRecording: _playRecording,
                      onRecordingStarted: _onRecordingStarted,
                      onRecordingStopped: _onRecordingStopped,
                      onAutoStopped: _onRecordingAutoStopped,
                    ),

                    const SizedBox(width: AppSpacing.sm),

                    // ── Right: Submit ────────────────────────────────────────
                    Expanded(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        opacity: showRetrySubmit ? 1.0 : 0.0,
                        child: IgnorePointer(
                          ignoring: !showRetrySubmit,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _onSubmitPressed,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.action,
                              foregroundColor: const Color(0xFF101828),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Color(0xFF101828),
                                    ),
                                  )
                                : Text(
                                    _controller.currentCardIndex == _controller.totalCards - 1 ? 'Finish' : 'Submit',
                                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF101828)).copyWith(inherit: false),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
// Low-score helper
// ---------------------------------------------------------------------------

/// Returns true when a result is below the threshold that triggers the AI tips
/// button.  Mirrors the existing red-zone threshold used by [feedbackScoreColor].
bool _isLowScore(PronunciationFeedbackMock f) {
  final score = f.pronScore ??
      (f.accuracyScore + f.fluencyScore + f.completenessScore) / 3;
  return score < 60;
}

// ---------------------------------------------------------------------------
// AI tips section
// ---------------------------------------------------------------------------

/// Shown inside the post-submission feedback card when the score is low.
///
/// Cycles through four states driven by local + controller state:
/// - Button (default, session ID present)
/// - Loading spinner (local `_loading` flag, avoids double-tap race)
/// - Suggestions list (permanent once loaded)
/// - Error message with retry (when controller reports failure)
class _AiTipsSection extends StatefulWidget {
  const _AiTipsSection({
    required this.cardIndex,
    required this.controller,
    required this.accessToken,
    required this.onStateChanged,
  });

  final int cardIndex;
  final SoloPracticeController controller;
  final String? accessToken;
  final VoidCallback onStateChanged;

  @override
  State<_AiTipsSection> createState() => _AiTipsSectionState();
}

class _AiTipsSectionState extends State<_AiTipsSection> {
  bool _loading = false;

  Future<void> _request() async {
    if (_loading) return;
    setState(() => _loading = true);
    await widget.controller.requestAiSuggestions(widget.accessToken);
    if (mounted) {
      setState(() => _loading = false);
      widget.onStateChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    );

    // Suggestions already loaded — render them permanently.
    final suggestions = widget.controller.aiSuggestionsFor(widget.cardIndex);
    if (suggestions != null && suggestions.isNotEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.primaryBg,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Tips',
              style: GoogleFonts.inter(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            for (final s in suggestions) ...[
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.arrow_right_rounded,
                      size: 16,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: Text(s, style: bodyStyle)),
                ],
              ),
            ],
          ],
        ),
      );
    }

    // Loading spinner — local flag prevents double-tap.
    if (_loading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('Getting AI tips…', style: bodyStyle),
        ],
      );
    }

    // Error state — show message and allow retry.
    if (widget.controller.aiSuggestionsFailed) {
      return Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 15, color: AppColors.failure),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Couldn\'t load tips.',
              style: bodyStyle.copyWith(color: AppColors.failure),
            ),
          ),
          TextButton(
            onPressed: _request,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.accent,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      );
    }

    // Default: button (only when a session ID is available).
    final sessionId = widget.controller.currentFeedback?.feedbackSessionId;
    if (sessionId == null) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _request,
        icon: const Icon(Icons.auto_awesome_rounded, size: 16),
        label: Text(
          'Get AI Tips',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
          ),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated mic / stop / play button with pulsing glow
// ---------------------------------------------------------------------------

class _AnimatedMicButton extends StatefulWidget {
  const _AnimatedMicButton({
    required this.micStateIndex,
    required this.onPlayRecording,
    required this.onRecordingStarted,
    required this.onRecordingStopped,
    this.onAutoStopped,
  });

  final int micStateIndex;
  final VoidCallback onPlayRecording;
  final VoidCallback onRecordingStarted;
  final ValueChanged<String> onRecordingStopped;
  final VoidCallback? onAutoStopped;

  @override
  State<_AnimatedMicButton> createState() => _AnimatedMicButtonState();
}

class _AnimatedMicButtonState extends State<_AnimatedMicButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _recordingProgress;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _recordingProgress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (widget.micStateIndex == 1) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AnimatedMicButton old) {
    super.didUpdateWidget(old);
    if (widget.micStateIndex == 1 && old.micStateIndex != 1) {
      _pulse.repeat(reverse: true);
    } else if (widget.micStateIndex != 1 && old.micStateIndex == 1) {
      _pulse.animateTo(0, duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _recordingProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.micStateIndex == 1;
    final isPlayback = widget.micStateIndex == 2;
    final glowColor = isRecording ? AppColors.failure : AppColors.accent;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, _) {
        final glowScale = 1.0 + _pulse.value * 0.18;
        final glowOpacity = isRecording
            ? 0.22 + _pulse.value * 0.18
            : 0.22;

        return SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Countdown arc — surrounds the full button while recording.
              if (isRecording)
                SizedBox(
                  width: 128,
                  height: 128,
                  child: AnimatedBuilder(
                    animation: _recordingProgress,
                    builder: (_, __) => CircularProgressIndicator(
                      value: 1.0 - _recordingProgress.value,
                      strokeWidth: 3,
                      color: AppColors.failure,
                      backgroundColor: AppColors.failure.withOpacity(0.2),
                    ),
                  ),
                ),

              // Pulsing glow ring — scale driven by animation when recording.
              Transform.scale(
                scale: isRecording ? glowScale : 1.0,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withOpacity(glowOpacity),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),

              // Button surface — transitions smoothly between states.
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecording
                      ? AppColors.failure.withOpacity(0.12)
                      : AppColors.surface,
                  border: Border.all(
                    color: isRecording
                        ? AppColors.failure.withOpacity(0.65)
                        : AppColors.accent.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: isPlayback
                    ? IconButton(
                        iconSize: 52,
                        padding: EdgeInsets.zero,
                        icon: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.accent,
                        ),
                        onPressed: widget.onPlayRecording,
                        tooltip: 'Play recording',
                      )
                    : Microphone(
                        idleColor: AppColors.accent,
                        recordingColor: AppColors.failure,
                        iconSize: 52,
                        onRecordingStarted: widget.onRecordingStarted,
                        onRecordingStopped: widget.onRecordingStopped,
                        onAutoStopped: widget.onAutoStopped,
                        progressController: _recordingProgress,
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Time's up dialog with animated icon entrance
// ---------------------------------------------------------------------------

class _TimeUpDialog extends StatefulWidget {
  const _TimeUpDialog();

  @override
  State<_TimeUpDialog> createState() => _TimeUpDialogState();
}

class _TimeUpDialogState extends State<_TimeUpDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;

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
    // Slight delay so the dialog entrance finishes before the icon pops in.
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _iconCtrl.forward();
    });
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
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
          Icons.timer_off_rounded,
          color: AppColors.failure,
          size: 32,
        ),
      ),
      title: Text(
        "Time's up",
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      content: Text(
        "Recording limit reached. Tap the mic to try again.",
        style: GoogleFonts.publicSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
          child: Text(
            'Got it',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
