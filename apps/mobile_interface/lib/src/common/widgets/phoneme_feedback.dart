import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constants.dart';
import '../models/pronunciation_feedback.dart';

// ---------------------------------------------------------------------------
// Colour helpers
// ---------------------------------------------------------------------------

/// Maps a word/phoneme accuracy score to a semantic colour.
/// ≥ 85 → success green, ≥ 60 → action orange, else failure red.
Color feedbackScoreColor(double? accuracy) {
  if (accuracy == null) return AppColors.textPrimary;
  if (accuracy >= 85) return AppColors.success;
  if (accuracy >= 60) return AppColors.action;
  return AppColors.failure;
}

/// Word-level colour that balances the aggregate score with phoneme analysis.
///
/// Strategy — use [word.accuracy] as the primary signal, then apply phoneme
/// penalties only for phonemes that are *clearly* wrong (< 60):
///
///  • No phoneme data            → [feedbackScoreColor] on [word.accuracy].
///  • ≥ 2 red phonemes (< 60),
///    OR red share > 40%         → failure red (multiple clear errors).
///  • 1 red phoneme              → downgrade one level:
///                                   green  → action orange
///                                   orange → stays orange  (already flagged)
///                                   red    → stays red
///  • No red phonemes            → [feedbackScoreColor] on [word.accuracy].
///
/// Borderline phonemes (60–84) do NOT trigger a downgrade on their own;
/// the aggregate [word.accuracy] already reflects them naturally.
Color strictWordColor(WordFeedback word) {
  if (word.phonemes.isEmpty) return feedbackScoreColor(word.accuracy);

  final accuracies = word.phonemes.map((p) => p.accuracy ?? 100.0).toList();
  final total = accuracies.length;
  final redCount = accuracies.where((a) => a < 60).length;

  if (redCount >= 2 || redCount / total > 0.40) return AppColors.failure;

  final base = feedbackScoreColor(word.accuracy);

  if (redCount == 1) {
    return base == AppColors.success ? AppColors.action : base;
  }

  final hasSubstitution = word.phonemes.any(
    (p) => p.userSaid != null && p.userSaid != p.symbol && (p.accuracy ?? 100.0) < 85,
  );

  final orangeCount = accuracies.where((a) => a >= 60 && a < 85).length;

  if ((hasSubstitution || orangeCount >= 2) && base == AppColors.success) {
    return AppColors.action;
  }

  return base;
}

/// Colour for a "You said" phoneme chip — green only when the symbol matches
/// AND accuracy is high (≥ 85).
Color userSaidPhonemeColor(PhonemeFeedback p) {
  final said = p.userSaid ?? p.symbol;
  final symbolMatches = said == p.symbol;
  if (symbolMatches && (p.accuracy ?? 0) >= 85) return AppColors.success;
  final c = feedbackScoreColor(p.accuracy);
  return c == AppColors.success ? AppColors.action : c;
}

// ---------------------------------------------------------------------------
// Phoneme bottom sheet
// ---------------------------------------------------------------------------

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

  const double colW = 42;
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
              Text(word.text, style: wordStyle),
              const SizedBox(height: AppSpacing.lg),
              if (word.phonemes.isEmpty)
                Text('No phoneme data available for this word.', style: hintStyle)
              else ...[
                // You row
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
                Padding(
                  padding: const EdgeInsets.only(left: labelW + 12),
                  child: const Divider(color: AppColors.border, height: 1, thickness: 1),
                ),
                // Target row
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

// ---------------------------------------------------------------------------
// PhonemeDetailDialog
// ---------------------------------------------------------------------------

/// Dialog shown when the user taps a phoneme symbol.
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

// ---------------------------------------------------------------------------
// ScoreChip
// ---------------------------------------------------------------------------

/// Small chip showing a score label and numeric value.
///
/// Styles are injected by the parent so all chips in a row share the same
/// [GoogleFonts] instances without extra allocations.
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
        Text(label, style: bodyStyle.copyWith(fontSize: 12)),
        const SizedBox(height: 2),
        Text('${score.round()}', style: style.copyWith(fontSize: 14)),
      ],
    );
  }
}
