import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants.dart';
import '../../../common/widgets/microphone.dart';
import '../controllers/solo_practice_controller.dart';
import '../widgets/feedback_card.dart';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------
class SoloPracticePage extends StatefulWidget {
  const SoloPracticePage({super.key});

  @override
  State<SoloPracticePage> createState() => _SoloPracticePageState();
}

class _SoloPracticePageState extends State<SoloPracticePage> {
  late final SoloPracticeController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _recordingPath;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = SoloPracticeController();
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

    final bytes = await file.readAsBytes();
    final referenceText = _controller.currentCard;

    await _controller.submit(
      audioBytes: bytes,
      referenceText: referenceText,
      accessToken: null, // TODO: pass Supabase session access token when auth is wired
    );

    if (!mounted) return;
    setState(() {});
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

    // --- Text styles (defined here to keep build readable) ---

    // Used for the lesson title and any bold UI labels.
    final headingStyle = GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );

    // Used for secondary UI text like the card counter and instruction copy.
    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    // Used for the main prompt text displayed on the practice card.
    final promptStyle = GoogleFonts.publicSans(
      color: AppColors.textPrimary,
      fontSize: 24,
      fontWeight: FontWeight.w500,
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
                // Back button: resets session progress before popping the route.
                // This is a placeholder behaviour — in production this would
                // likely prompt the user before discarding their progress.
                IconButton(
                  onPressed: () {
                    setState(() => _controller.resetSession());
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),

                // Progress row + bar, constrained to a fixed width for
                // consistent alignment across different screen sizes.
                Center(
                  child: SizedBox(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            // Card counter e.g. "3/20"
                            Text('${_controller.currentCardIndex + 1}/${_controller.totalCards}', style: bodyStyle),
                            const Spacer(),
                            // Lesson name — hardcoded for now, pass via constructor later.
                            Text('Lesson Title', style: headingStyle),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Progress bar clipped to rounded corners using ClipRRect
                        // because LinearProgressIndicator doesn't natively support
                        // border radius.
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
            // MIDDLE SECTION — prompt card or inline feedback card (explorable)
            // -----------------------------------------------------------------
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Center(
                        child: _controller.currentFeedback == null
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Prompt card: phrase the user should read aloud.
                                  Container(
                                    width: 300,
                                    height: 200,
                                    padding: const EdgeInsets.all(AppSpacing.lg),
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(AppRadii.lg),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Center(
                                      child: Text(
                                        _controller.currentCard,
                                        textAlign: TextAlign.center,
                                        style: promptStyle,
                                      ),
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

                  // Retry button — only visible in playback state (2).
                  // Resets mic to idle so the user can re-record.
                  if (showRetrySubmit) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onRetryPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            side: const BorderSide(color: AppColors.border),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        ),
                        // inherit: false prevents a TextStyle lerp crash when
                        // Flutter animates the button press. See theme.dart for context.
                        child: Text(
                          'Retry',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary).copyWith(inherit: false),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],

                  // Mic button — the primary interaction element.
                  // A Container provides the glow shadow; ElevatedButton handles taps.
                  // Color shifts to failure red while recording (state 1).
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          // Glow shifts from accent (idle/playback) to failure (recording).
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

                  // Submit button — only visible in playback state (2).
                  // Advances to the next card or shows completion dialog on last card.
                  if (showRetrySubmit) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onSubmitPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.action,
                          foregroundColor: const Color(0xFF101828),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        ),
                        // Label changes to 'Finish' on the final card.
                        // inherit: false prevents TextStyle lerp crash on button press.
                        child: Text(
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