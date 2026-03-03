import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';

class SoloPracticePage extends StatefulWidget {
  const SoloPracticePage({super.key});

  @override
  State<SoloPracticePage> createState() => _SoloPracticePageState();
}

class _SoloPracticePageState extends State<SoloPracticePage> {
  int _micStateIndex = 0; // 0 = mic, 1 = recording, 2 = play
  final AudioPlayer _audioPlayer = AudioPlayer();
  // Note: audioplayers' AssetSource is effectively relative to the `assets/` bundle prefix.
  // With `pubspec.yaml` declaring `assets/audio/testaudio.wav`, pass `audio/testaudio.wav` here.
  static const String _sampleAudioAsset = 'audio/testaudio.wav';

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _onMicPressed() async {
    if (_micStateIndex < 2) {
      setState(() {
        _micStateIndex += 1;
      });
    } else {
      // In play state: play bundled sample audio asset
      try {
        await _audioPlayer.stop();
        await _audioPlayer.play(AssetSource(_sampleAudioAsset));
      } catch (_) {
        // Swallow errors for now; real handling can be added later.
      }
    }
  }

  void _onRetryPressed() {
    setState(() {
      _micStateIndex = 0;
    });
  }

  IconData _currentMicIcon() {
    switch (_micStateIndex) {
      case 1:
        return Icons.fiber_manual_record; // circle for recording
      case 2:
        return Icons.play_arrow; // play icon
      case 0:
      default:
        return Icons.mic; // default mic
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showRetrySubmit = _micStateIndex == 2;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top section: back button above centered progress/info
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(height: 8),
                Center(
                  child: SizedBox(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: const [
                            Text('1/20'),
                            Spacer(),
                            Text('Lesson Title'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const LinearProgressIndicator(
                          value: 0.2, // placeholder for now
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Middle section: prompt box and text to repeat
            Expanded(
              child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      // Placeholder for prompt box
                      SizedBox(
                        height: 120,
                        width: 280,
                        child: Card(
                          child: Center(
                            child: Text(
                              'The quick brown fox jumped over the lazy dog.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Record yourself using the microphone button below!',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
              ),
            ),
            // Bottom section: controls (microphone button for now)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showRetrySubmit) ...[
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _onRetryPressed,
                        child: const Text('Retry'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: const CircleBorder(),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.center,
                      ),
                      onPressed: _onMicPressed,
                      child: Icon(
                        _currentMicIcon(),
                        size: 56,
                      ),
                    ),
                  ),
                  if (showRetrySubmit) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: submit audio in the future
                        },
                        child: const Text('Submit'),
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
