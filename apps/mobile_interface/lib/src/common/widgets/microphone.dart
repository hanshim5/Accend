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
    this.onAutoStopped,
    this.idleColor,
    this.recordingColor,
    this.iconSize,
    this.maxRecordingDuration = const Duration(seconds: 10),
    this.progressController,
  });

  /// Called after a successful transition into the recording state.
  final VoidCallback? onRecordingStarted;

  /// Called after recording stops with the final file path (if available).
  final ValueChanged<String>? onRecordingStopped;

  /// Called when recording is stopped automatically by [maxRecordingDuration].
  final VoidCallback? onAutoStopped;

  /// Icon color when idle (not recording). Falls back to the theme primary.
  final Color? idleColor;

  /// Icon color while recording. Falls back to [Colors.red].
  final Color? recordingColor;

  /// Icon size. Defaults to 48.
  final double? iconSize;

  /// Maximum recording duration before auto-stopping. Defaults to 10 seconds.
  final Duration maxRecordingDuration;

  /// Optional external [AnimationController] driven from 0→1 over
  /// [maxRecordingDuration] while recording. When provided the widget skips
  /// rendering its own arc so the caller can draw it wherever they like.
  final AnimationController? progressController;

  @override
  State<Microphone> createState() => _MicrophoneState();
}

class _MicrophoneState extends State<Microphone>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _busy = false;

  /// Internal controller used only when no external [progressController] is given.
  AnimationController? _ownProgressController;
  Timer? _autoStopTimer;

  AnimationController get _effectiveProgress =>
      widget.progressController ?? _ownProgressController!;

  @override
  void initState() {
    super.initState();
    if (widget.progressController == null) {
      _ownProgressController = AnimationController(
        vsync: this,
        duration: widget.maxRecordingDuration,
      );
    }
  }

  @override
  void dispose() {
    _autoStopTimer?.cancel();
    _ownProgressController?.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<String> _nextFilePath() async {
    final dir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}${Platform.pathSeparator}recording_$ts.wav';
  }

  Future<void> _stopRecording() async {
    _autoStopTimer?.cancel();
    _autoStopTimer = null;
    _effectiveProgress.stop();
    _effectiveProgress.reset();

    final path = await _recorder.stop();

    if (!mounted) return;
    setState(() {
      _isRecording = false;
    });

    if (path != null && path.isNotEmpty) {
      widget.onRecordingStopped?.call(path);
    }
  }

  Future<void> _autoStop() async {
    if (!_isRecording) return;
    _busy = true;
    try {
      await _stopRecording();
      if (mounted) widget.onAutoStopped?.call();
    } finally {
      _busy = false;
    }
  }

  Future<void> _toggleRecording() async {
    if (_busy) return;
    _busy = true;

    try {
      if (_isRecording) {
        await _stopRecording();
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

      _effectiveProgress.forward(from: 0);
      _autoStopTimer = Timer(widget.maxRecordingDuration, _autoStop);

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
    final double size = widget.iconSize ?? 48;
    final Color activeColor = widget.recordingColor ?? Colors.red;

    final button = IconButton(
      iconSize: size,
      padding: EdgeInsets.zero,
      onPressed: _busy ? null : _toggleRecording,
      icon: Icon(
        _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
        color: _isRecording
            ? activeColor
            : (widget.idleColor ?? Theme.of(context).colorScheme.primary),
      ),
      tooltip: _isRecording ? 'Stop recording' : 'Start recording',
    );

    // When an external controller is provided the caller renders the arc;
    // return only the plain button.
    if (widget.progressController != null) return button;

    // Standalone use: render arc + button together.
    if (!_isRecording) return button;

    return SizedBox(
      width: size + 16,
      height: size + 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _ownProgressController!,
            builder: (_, __) => CircularProgressIndicator(
              value: 1.0 - _ownProgressController!.value,
              strokeWidth: 3,
              color: activeColor,
              backgroundColor: activeColor.withOpacity(0.2),
            ),
          ),
          button,
        ],
      ),
    );
  }
}
