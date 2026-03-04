import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/constants.dart';

// ---------------------------------------------------------------------------
// Mock data
// ---------------------------------------------------------------------------
// Temporary list of practice prompts used until real lesson data is wired in.
// Each string is a phrase the user will be asked to read aloud.
// Replace with a real data source (e.g. API response or lesson model) later.
const List<String> _mockCards = [
  'The quick brown fox jumped over the lazy dog.',
  'She sells seashells by the seashore.',
  'How much wood would a woodchuck chuck?',
  'Peter Piper picked a peck of pickled peppers.',
  'I scream, you scream, we all scream for ice cream.',
  'Red lorry, yellow lorry.',
  'Unique New York, unique New York.',
  'Buffalo buffalo Buffalo buffalo buffalo buffalo Buffalo buffalo.',
  'The sixth sick sheikh\'s sixth sheep\'s sick.',
  'Fresh French fried fish fingers.',
  'I saw Susie sitting in a shoeshine shop.',
  'Lesser leather never weathered wetter weather better.',
  'Can you can a can as a canner can can a can?',
  'Willy\'s real rear wheel.',
  'The thirty-three thieves thought that they thrilled the throne.',
  'Six sleek swans swam swiftly southwards.',
  'How can a clam cram in a clean cream can?',
  'Fuzzy Wuzzy was a bear. Fuzzy Wuzzy had no hair.',
  'Near an ear, a nearer ear, a nearly eerie ear.',
  'You\'ve done it! Great work completing the lesson.',
];

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
class SoloPracticePage extends StatefulWidget {
  const SoloPracticePage({super.key});

  @override
  State<SoloPracticePage> createState() => _SoloPracticePageState();
}

class _SoloPracticePageState extends State<SoloPracticePage> {
  // Index of the card currently displayed (0-based).
  int _currentCardIndex = 0;

  // Tracks the microphone button's visual/functional state:
  //   0 = idle     → shows mic icon, ready to record
  //   1 = recording → shows record icon, simulates active recording
  //   2 = playback  → shows play icon, allows playing back the "recording"
  int _micStateIndex = 0;

  // Audio player instance used to play back the sample asset in state 2.
  // Disposed in [dispose] to avoid memory leaks.
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Path to the bundled sample audio file (relative to the assets/ directory).
  // Used as a placeholder until real recorded audio is captured and stored.
  static const String _sampleAudioAsset = 'audio/testaudio.wav';

  // ---------------------------------------------------------------------------
  // Computed getters
  // ---------------------------------------------------------------------------

  /// Total number of practice cards in the current session.
  int get _totalCards => _mockCards.length;

  /// The prompt string for the card currently on screen.
  String get _currentCard => _mockCards[_currentCardIndex];

  /// Progress value between 0.0 and 1.0 for the LinearProgressIndicator.
  /// Based on the current card position (1-indexed so the first card shows
  /// some progress rather than an empty bar).
  double get _progress => (_currentCardIndex + 1) / _totalCards;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    // Always dispose the AudioPlayer when the widget leaves the tree to free
    // the underlying platform audio resources.
    _audioPlayer.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Event handlers
  // ---------------------------------------------------------------------------

  /// Called when the circular mic button is tapped.
  ///
  /// State machine:
  ///   0 → 1  : Start recording (UI only for now)
  ///   1 → 2  : Stop recording, enter playback-ready state
  ///   2 → 2  : Already in playback state — play the sample audio asset
  Future<void> _onMicPressed() async {
    if (_micStateIndex < 2) {
      // Advance through idle → recording → playback states.
      setState(() {
        _micStateIndex += 1;
      });
    } else {
      // In playback state: stop any currently playing audio, then play
      // the bundled sample asset as a stand-in for the user's recording.
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource(_sampleAudioAsset));
      } catch (_) {
        // Silently swallow errors for now.
        // TODO: surface playback errors to the user in a future iteration.
      }
    }
  }

  /// Resets the mic state back to idle (0) so the user can re-record
  /// without advancing to the next card.
  void _onRetryPressed() {
    setState(() {
      _micStateIndex = 0;
    });
  }

  /// Advances to the next card and resets the mic state.
  /// If the user is on the last card, shows a completion dialog instead.
  void _onSubmitPressed() {
    if (_currentCardIndex < _totalCards - 1) {
      // Move to the next card and reset the mic to idle.
      setState(() {
        _currentCardIndex += 1;
        _micStateIndex = 0;
      });
    } else {
      // All cards completed — show a completion dialog.
      // TODO: replace with a proper results/summary screen.
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lesson Complete! 🎉'),
          content: const Text('You\'ve completed all 20 exercises. Great work!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();   // Close dialog
                Navigator.of(context).maybePop(); // Return to previous screen
              },
              child: const Text('Finish'),
            ),
          ],
        ),
      );
    }
  }

  /// Returns the correct icon for the mic button based on [_micStateIndex].
  ///   0 → mic icon        (idle)
  ///   1 → record dot      (recording in progress)
  ///   2 → play arrow      (ready to play back)
  IconData _currentMicIcon() {
    switch (_micStateIndex) {
      case 1:
        return Icons.fiber_manual_record;
      case 2:
        return Icons.play_arrow;
      case 0:
      default:
        return Icons.mic;
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Only show Retry / Submit buttons once a recording has been made (state 2).
    final bool showRetrySubmit = _micStateIndex == 2;

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
      fontSize: 16,
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
                    setState(() {
                      _currentCardIndex = 0;
                      _micStateIndex = 0;
                    });
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
                            Text('${_currentCardIndex + 1}/$_totalCards', style: bodyStyle),
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
                            value: _progress,
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
            // MIDDLE SECTION — prompt card + instruction text
            // -----------------------------------------------------------------
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Prompt card: displays the phrase the user should read aloud.
                    // Styled to match the app's surface card design token.
                    Container(
                      width: 300,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        _currentCard,
                        textAlign: TextAlign.center,
                        style: promptStyle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Static instruction text — does not change between cards.
                    Text(
                      'Record yourself using the microphone button below!',
                      textAlign: TextAlign.center,
                      style: bodyStyle,
                    ),
                  ],
                ),
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
                          color: _micStateIndex == 1
                              ? AppColors.failure.withOpacity(0.4)
                              : AppColors.accent.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        // Background: red while recording, accent otherwise.
                        backgroundColor: _micStateIndex == 1
                            ? AppColors.surface
                            : AppColors.accent,
                        foregroundColor: AppColors.primaryBg,
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.center,
                      ),
                      onPressed: _onMicPressed,
                      child: Icon(
                        _currentMicIcon(),
                        size: 56,
                        color: _micStateIndex == 1 ? AppColors.failure : AppColors.primaryBg,
                      ),
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
                          _currentCardIndex == _totalCards - 1 ? 'Finish' : 'Submit',
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