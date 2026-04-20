import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/constants.dart';
import '../models/pronunciation_feedback.dart';

/// Maps a word/phoneme accuracy score to a semantic color.
/// ≥ 85 → success green, ≥ 60 → action orange, else failure red.
Color feedbackScoreColor(double? accuracy) {
  if (accuracy == null) return AppColors.textPrimary;
  if (accuracy >= 85) return AppColors.success;
  if (accuracy >= 60) return AppColors.action;
  return AppColors.failure;
}

/// Word-level color driven by the worst phoneme, with a one-outlier grace rule.
///
///  • No phoneme data   → [feedbackScoreColor] on [word.accuracy].
///  • Substitutions (user said a different phoneme) count as red, mirroring
///    [userSaidPhonemeColor].
///  • ≥ 2 red phonemes  → failure red.
///  • 1 red phoneme     → action orange (grace: one isolated mistake ≠ red word).
///  • Any yellow (60–84, no substitution) → action orange.
///  • All green (≥ 85)  → success green.
Color strictWordColor(WordFeedback word) {
  if (word.phonemes.isEmpty) return feedbackScoreColor(word.accuracy);

  int redCount = 0;
  bool hasYellow = false;

  for (final p in word.phonemes) {
    final isSubstitution = p.userSaid != null && p.userSaid != p.symbol;
    final accuracy = p.accuracy ?? 100.0;
    if (isSubstitution || accuracy < 60) {
      redCount++;
    } else if (accuracy < 85) {
      hasYellow = true;
    }
  }

  if (redCount >= 2) return AppColors.failure;
  if (redCount == 1) return AppColors.action;
  if (hasYellow) return AppColors.action;
  return AppColors.success;
}

/// Color for a "You said" phoneme chip — green only when the symbol matches
/// AND accuracy is high (≥ 85). A substitution (different phoneme) is always red.
Color userSaidPhonemeColor(PhonemeFeedback p) {
  final said = p.userSaid ?? p.symbol;
  final symbolMatches = said == p.symbol;
  if (symbolMatches && (p.accuracy ?? 0) >= 85) return AppColors.success;
  // Substitution: user produced a different phoneme — always failure red.
  if (!symbolMatches) return AppColors.failure;
  final c = feedbackScoreColor(p.accuracy);
  return c == AppColors.success ? AppColors.action : c;
}

/// Shows the phoneme detail popup for a single [symbol].
void _showPhonemeDetailDialog({
  required BuildContext parentContext,
  required String symbol,
  double? accuracy,
  Color? chipColor,
}) {
  showDialog<void>(
    context: parentContext,
    builder: (_) => PhonemeDetailDialog(
      symbol: symbol,
      accuracy: accuracy,
      chipColor: chipColor ?? AppColors.textPrimary,
    ),
  );
}

/// Shows the word-level phoneme breakdown as a bottom sheet for [word].
/// Can be called from any widget that has a [BuildContext].
void showWordPhonemeDialog(BuildContext context, WordFeedback word) {
  final wordStyle = GoogleFonts.inter(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );
  final labelStyle = GoogleFonts.publicSans(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
  final hintStyle = GoogleFonts.publicSans(
    color: AppColors.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w400,
  );
  final phonemeStyle = GoogleFonts.inter(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  // Each phoneme column — wide enough for 2-char SAPI symbols at 22sp.
  const double colW = 42;
  // Label column — right-aligned "you" / "target".
  const double labelW = 52;

  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Word title
              Text(word.text, style: wordStyle),
              const SizedBox(height: AppSpacing.lg),

              if (word.phonemes.isEmpty)
                Text('No phoneme data available for this word.', style: hintStyle)
              else ...[
                // ── You row ───────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: labelW,
                      child: Text('you', textAlign: TextAlign.right, style: labelStyle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final p in word.phonemes)
                              GestureDetector(
                                onTap: () => _showPhonemeDetailDialog(
                                  parentContext: sheetContext,
                                  symbol: p.userSaid ?? p.symbol,
                                  accuracy: p.accuracy,
                                  chipColor: userSaidPhonemeColor(p),
                                ),
                                child: SizedBox(
                                  width: colW,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      p.userSaid ?? p.symbol,
                                      textAlign: TextAlign.center,
                                      style: phonemeStyle.copyWith(
                                        color: userSaidPhonemeColor(p),
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

                // ── Divider aligned to phoneme column only ────────────────
                Padding(
                  padding: const EdgeInsets.only(left: labelW + 12),
                  child: const Divider(color: AppColors.border, height: 1, thickness: 1),
                ),

                // ── Target row ────────────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: labelW,
                      child: Text('target', textAlign: TextAlign.right, style: labelStyle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final p in word.phonemes)
                              GestureDetector(
                                onTap: () => _showPhonemeDetailDialog(
                                  parentContext: sheetContext,
                                  symbol: p.symbol,
                                  chipColor: AppColors.textPrimary,
                                ),
                                child: SizedBox(
                                  width: colW,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: Text(
                                      p.symbol,
                                      textAlign: TextAlign.center,
                                      style: phonemeStyle.copyWith(
                                        color: AppColors.textSecondary,
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

                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text('Tap to hear pronunciation', style: hintStyle),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

/// Inline feedback card shown after the user submits a recording.
/// Displays word-level and phoneme-level scores; tap a word to see phoneme breakdown.
class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.feedback,
    required this.onRetry,
    required this.onNext,
  });

  final PronunciationFeedbackMock feedback;
  /// Re-record and regrade the same item from scratch.
  final VoidCallback onRetry;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final headingStyle = GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );
    final scoreStyle = GoogleFonts.inter(
      color: AppColors.accent,
      fontSize: 20,
      fontWeight: FontWeight.w700,
    );

    return Container(
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
          Text(
            'Pronunciation feedback',
            style: headingStyle.copyWith(fontSize: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            "Tap any word below to see your phoneme-level feedback!",
            style: bodyStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.md),
          if (feedback.words.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final w in feedback.words)
                  ActionChip(
                    onPressed: () => showWordPhonemeDialog(context, w),
                    backgroundColor: AppColors.inputFill,
                    shape: StadiumBorder(
                      side: BorderSide(color: AppColors.border),
                    ),
                    label: Text(
                      w.text,
                      style: bodyStyle.copyWith(
                        color: strictWordColor(w),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ScoreChip(label: 'Accuracy', score: feedback.accuracyScore, style: scoreStyle, bodyStyle: bodyStyle),
              ScoreChip(label: 'Fluency', score: feedback.fluencyScore, style: scoreStyle, bodyStyle: bodyStyle),
              ScoreChip(label: 'Complete', score: feedback.completenessScore, style: scoreStyle, bodyStyle: bodyStyle),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onRetry,
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
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.action,
                    foregroundColor: const Color(0xFF101828),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF101828)).copyWith(inherit: false),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Small chip showing a score label and numeric value (e.g. Accuracy: 85).
///
/// Styles are injected by the parent so all three chips in [FeedbackCard]
/// share the same `GoogleFonts` instances without extra allocations.
class ScoreChip extends StatelessWidget {
  const ScoreChip({
    super.key,
    required this.label,
    required this.score,
    required this.style,
    required this.bodyStyle,
  });

  final String label;
  final double score;
  final TextStyle style;
  final TextStyle bodyStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: bodyStyle.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 2),
        Text(
          '${score.round()}',
          style: style.copyWith(fontSize: 14),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Phoneme detail dialog
// ---------------------------------------------------------------------------

/// Dialog shown when the user taps a phoneme chip.
/// Manages its own [AudioPlayer] so it is properly disposed on close.
class PhonemeDetailDialog extends StatefulWidget {
  const PhonemeDetailDialog({
    super.key,
    required this.symbol,
    required this.chipColor,
    this.accuracy,
  });

  final String symbol;
  final Color chipColor;
  final double? accuracy;

  @override
  State<PhonemeDetailDialog> createState() => _PhonemeDetailDialogState();
}

class _PhonemeDetailDialogState extends State<PhonemeDetailDialog> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          // The spinner shows from tap until the player leaves `stopped`.
          // `stopped` is also the initial state before any audio loads, so
          // we only clear the spinner once playback, pause, or completion fires.
          if (state != PlayerState.stopped) _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _player.stop();
      return;
    }
    setState(() => _isLoading = true);
    final url = Supabase.instance.client.storage
        .from(AppStorage.phonemeBucket)
        .getPublicUrl(AppStorage.phonemeAudioPath(widget.symbol));
    try {
      // Stop any previous stream before starting a new one; calling play()
      // directly on an active player can cause overlap or stale-state errors.
      await _player.stop();
      await _player.play(UrlSource(url));
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not play audio. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bodyStyle = GoogleFonts.publicSans(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    final instruction = phonemeInstructions[widget.symbol.toLowerCase()];

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Text(
              widget.symbol,
              style: GoogleFonts.inter(
                color: widget.chipColor,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (widget.accuracy != null) ...[
            const SizedBox(width: 10),
            Text(
              '${widget.accuracy!.round()}',
              style: GoogleFonts.inter(
                color: widget.chipColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: 48,
            height: 48,
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                      strokeWidth: 2.5,
                    ),
                  )
                : IconButton(
                    onPressed: _togglePlayback,
                    tooltip: _isPlaying ? 'Stop' : 'Play example',
                    icon: Icon(
                      _isPlaying
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      color: AppColors.accent,
                      size: 32,
                    ),
                  ),
          ),
        ],
      ),
      content: instruction == null
          ? Text('No instruction available for "${widget.symbol}".', style: bodyStyle)
          : Text(instruction, style: bodyStyle),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }
}
