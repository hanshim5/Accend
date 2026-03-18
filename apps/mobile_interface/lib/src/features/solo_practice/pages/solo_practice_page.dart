import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../common/services/auth_service.dart';
import '../../../common/widgets/microphone.dart';
import '../../courses/models/lesson.dart';
import '../controllers/solo_practice_controller.dart';
import '../widgets/feedback_card.dart';

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

class _SoloPracticePageState extends State<SoloPracticePage> {
  late final SoloPracticeController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = SoloPracticeController(
      items: widget.lesson?.items,
    );
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

  /// After user taps Next on feedback: clear feedback, go to next card or show completion.
  void _advanceToNextCard() {
    _clearRecording();
    final hasMore = _controller.advanceToNextCard();
    setState(() {});
    if (!hasMore) {
      showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Lesson Complete! 🎉', style: GoogleFonts.inter(color: AppColors.textPrimary)),
          content: Text(
            'You\'ve completed all ${_controller.totalCards} exercises. Great work!',
            style: GoogleFonts.publicSans(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.of(context).maybePop();
              },
              child: const Text('Finish'),
            ),
          ],
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
                        child: _isSubmitting
                            ? Column(
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
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Prompt card
                                      Container(
                                        width: 300,
                                        padding: const EdgeInsets.all(AppSpacing.lg),
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
                                : Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.md),
                                    child: FeedbackCard(
                                      feedback: _controller.currentFeedback!,
                                      onRetry: _onFeedbackRetry,
                                      onNext: _advanceToNextCard,
                                    ),
                                  ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // -----------------------------------------------------------------
            // BOTTOM SECTION — Retry / mic button / Submit
            // -----------------------------------------------------------------
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  if (showRetrySubmit) ...[
                    Expanded(
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
                    const SizedBox(width: AppSpacing.sm),
                  ],

                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _controller.micStateIndex == 1
                              ? AppColors.failure.withOpacity(0.4)
                              : AppColors.accent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _controller.micStateIndex == 2
                        ? IconButton(
                            iconSize: 56,
                            icon: const Icon(Icons.play_arrow, color: AppColors.primaryBg),
                            onPressed: _playRecording,
                          )
                        : Microphone(
                            onRecordingStarted: _onRecordingStarted,
                            onRecordingStopped: _onRecordingStopped,
                          ),
                  ),

                  if (showRetrySubmit) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
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
                  ],

                ],
              ),
            ),

          ],
        ),
      ),
    );
  }
}
