import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class Microphone extends StatefulWidget {
  const Microphone({super.key});

  @override
  State<Microphone> createState() => _MicrophoneState();
}

class _MicrophoneState extends State<Microphone> {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _busy = false;
  String? _lastPath;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<String> _nextFilePath() async {
    final dir = await getTemporaryDirectory(); // or getApplicationDocumentsDirectory()
    final fileName = 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';
    return '${dir.path}${Platform.pathSeparator}$fileName';
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
          _lastPath = path;
        });

        // Example: debug print
        // debugPrint('Saved recording at: $path');
        return;
      }

      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required.')),
        );
        return;
      }

      final path = await _nextFilePath();

      await _recorder.start(
        RecordConfig(
          encoder: AudioEncoder.wav, // match .wav
          // sampleRate: 16000, // optional, depends on your needs
          // bitRate: 128000,   // optional, depends on encoder
        ),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _isRecording = true;
      });
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
