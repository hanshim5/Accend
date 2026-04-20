import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../../../common/widgets/primary_button.dart';
import '../controllers/group_session_controller.dart';
import '../models/private_lobby.dart';
import '../widgets/quit_group_session_back_button.dart';

class GroupSessionActiveLobbyPage extends StatefulWidget {
  const GroupSessionActiveLobbyPage({super.key});

  @override
  State<GroupSessionActiveLobbyPage> createState() =>
      _GroupSessionActiveLobbyPageState();
}

class _GroupSessionActiveLobbyPageState extends State<GroupSessionActiveLobbyPage> {
  Room? _room;
  EventsListener<RoomEvent>? _roomEvents;
  String? _voiceError;
  bool _voiceConnecting = false;
  bool _micEnabled = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _connectVoice() async {
    final ctrl = context.read<GroupSessionController>();
    if (ctrl.privateLobby.isEmpty) return;

    setState(() {
      _voiceConnecting = true;
      _voiceError = null;
    });

    final lobbyId = ctrl.privateLobby.first.lobbyId;
    final kind = ModalRoute.of(context)?.settings.arguments as String? ?? 'private';

    try {
      final data = await ctrl.getLiveKitToken(lobbyId: lobbyId, lobbyKind: kind);
      final url = data['url'] as String;
      final jwt = data['token'] as String;

      final room = Room();
      await room.connect(
        url,
        jwt,
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
        ),
      );
      // On web, remote tracks attach after connect; `startAudio()` must run again
      // after each remote audio track subscribes so hidden <audio> elements call play().
      _roomEvents = room.createListener()
        ..on<TrackSubscribedEvent>((event) async {
          if (event.track is RemoteAudioTrack) {
            await room.startAudio();
            if (mounted) setState(() {});
          }
        });
      // Required on web to unlock audio playback after user gesture.
      await room.startAudio();
      final micPub = await room.localParticipant?.setMicrophoneEnabled(true);

      room.addListener(_onRoomChanged);

      if (!mounted) return;
      setState(() {
        _room = room;
        _micEnabled = micPub != null;
        if (!_micEnabled) {
          _voiceError = 'Connected, but microphone was not published. Check browser mic permissions.';
        }
        _voiceConnecting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _voiceError = e.toString();
        _voiceConnecting = false;
      });
    }
  }

  void _onRoomChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _disconnectVoice() async {
    final r = _room;
    _room = null;
    _micEnabled = false;
    final ev = _roomEvents;
    _roomEvents = null;
    if (ev != null) {
      await ev.dispose();
    }
    if (r != null) {
      r.removeListener(_onRoomChanged);
      await r.disconnect();
      await r.dispose();
    }
  }

  Future<void> _toggleMic() async {
    final room = _room;
    if (room == null) return;
    final next = !_micEnabled;
    try {
      final micPub = await room.localParticipant?.setMicrophoneEnabled(next);
      if (!mounted) return;
      setState(() {
        _micEnabled = next ? (micPub != null) : false;
        _voiceError = (next && micPub == null)
            ? 'Microphone publish failed. Check browser permissions.'
            : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _voiceError = 'Failed to toggle mic: $e';
      });
    }
  }

  Color _statusColor(String state) {
    switch (state) {
      case 'connected':
        return AppColors.success;
      case 'reconnecting':
      case 'connecting':
        return AppColors.accent2;
      case 'disconnected':
        return AppColors.failure;
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _leaveLobby(BuildContext context) async {
    final ctrl = context.read<GroupSessionController>();
    final kind = ModalRoute.of(context)?.settings.arguments as String? ?? 'private';

    // Snapshot participants before leave — the controller clears privateLobby
    // during leavePublicLobby() / deletePrivateLobbyRow().
    final List<PrivateLobby> participants = List<PrivateLobby>.from(ctrl.privateLobby);

    await _disconnectVoice();

    bool ok;
    if (kind == 'public') {
      ok = await ctrl.leavePublicLobby();
    } else {
      ok = await ctrl.leaveLobby();
    }

    if (!context.mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to leave lobby')),
      );
      return;
    }

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.groupSessionResults,
      arguments: participants,
    );
  }

  @override
  void dispose() {
    unawaited(_disconnectVoice());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GroupSessionController>();
    final t = Theme.of(context);

    final String lobbyCode;
    if (ctrl.isLoading) {
      lobbyCode = 'Loading...';
    } else if (ctrl.privateLobby.isNotEmpty) {
      lobbyCode = ctrl.privateLobby.first.lobbyId;
    } else if (ctrl.error != null) {
      lobbyCode = 'Error';
    } else {
      lobbyCode = '------';
    }

    final remoteCount = _room?.remoteParticipants.length ?? 0;
    final voiceState = _room?.connectionState.name ?? '—';
    final remoteAudioTracks = _room?.remoteParticipants.values
            .expand((p) => p.trackPublications.values)
            .where((pub) => pub.track is RemoteAudioTrack)
            .length ??
        0;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const QuitGroupSessionBackButton(),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text('Lobby', style: t.textTheme.headlineMedium),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Divider(color: AppColors.border, thickness: 5),
                  const Spacer(),
                  Text(
                    'Code: $lobbyCode',
                    style: t.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  if (_voiceConnecting)
                    Text(
                      'Connecting voice…',
                      style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    )
                  else if (_voiceError != null)
                    Text(
                      _voiceError!,
                      style: t.textTheme.bodyMedium?.copyWith(color: AppColors.failure),
                      textAlign: TextAlign.center,
                    )
                  else if (_room != null) ...[
                    Text(
                      'Voice: $voiceState',
                      style: t.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _statusColor(voiceState).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: _statusColor(voiceState)),
                      ),
                      child: Text(
                        voiceState.toUpperCase(),
                        style: t.textTheme.bodySmall?.copyWith(
                          color: _statusColor(voiceState),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Participants in call: ${remoteCount + 1} (incl. you)',
                      style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remote audio tracks: $remoteAudioTracks | Mic published: ${_micEnabled ? 'yes' : 'no'}',
                      style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 18),
                  if (_room == null)
                    PrimaryButton(
                      text: 'Join Voice',
                      loading: _voiceConnecting,
                      onPressed: _voiceConnecting ? null : _connectVoice,
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _toggleMic,
                        icon: Icon(
                          _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded,
                        ),
                        label: Text(_micEnabled ? 'Mute Mic' : 'Unmute Mic'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.border, width: 2),
                        ),
                      ),
                    ),
                  if (ctrl.error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      ctrl.error!,
                      style: t.textTheme.bodyMedium?.copyWith(color: AppColors.failure),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 18),
                  PrimaryButton(
                    text: 'Leave lobby',
                    loading: ctrl.isLoading,
                    onPressed: ctrl.privateLobby.isEmpty
                        ? null
                        : () => _leaveLobby(context),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
