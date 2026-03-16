import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class Microphone extends StatefulWidget {
  const Microphone({
    super.key,
    this.onRecordingStarted,
    this.onRecordingStopped,
  });

  /// Called after a successful transition into the recording state.
  final VoidCallback? onRecordingStarted;

  /// Called after recording stops with the final file path (if available).
  final ValueChanged<String>? onRecordingStopped;

  @override
  State<Microphone> createState() => _MicrophoneState();
}

class _MicrophoneState extends State<Microphone> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _busy = false;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<String> _nextFilePath() async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}${Platform.pathSeparator}recording_$ts.wav';
  }

  Future<void> _toggleRecording() async {
    if (_busy) return;
    _busy = true;

    try {
      if (_isRecording) {
        final path = await _recorder.stop();

        if (!mounted) return;
        setState(() {
          _isRecording = false;
        });

        if (path != null && path.isNotEmpty) {
          widget.onRecordingStopped?.call(path);
        }
        return;
      }

      // hasPermission() on Android both checks and, if needed, requests the
      // RECORD_AUDIO runtime permission. Wrap in a timeout so a stalled
      // permission-result callback doesn't lock up the button indefinitely.
      final bool hasPermission;
      try {
        hasPermission = await _recorder
            .hasPermission()
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission request timed out. Please try again.'),
          ),
        );
        return;
      }

      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission denied. Enable it in app Settings.',
            ),
          ),
        );
        return;
      }

      final path = await _nextFilePath();
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 16000, // 16 kHz is guaranteed on all Android devices/emulators
          numChannels: 1,    // mono — also what Azure Speech SDK expects
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _isRecording = true;
      });
      widget.onRecordingStarted?.call();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording failed: $e')),
      );
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 48,
      onPressed: _busy ? null : _toggleRecording,
      icon: Icon(
        _isRecording ? Icons.stop : Icons.mic,
        color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary,
      ),
      tooltip: _isRecording ? 'Stop recording' : 'Start recording',
    );
  }
}
