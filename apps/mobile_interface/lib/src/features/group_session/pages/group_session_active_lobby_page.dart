import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/constants.dart';
import '../../../app/routes.dart';
import '../controllers/group_session_controller.dart';
import '../models/private_lobby.dart';
import '../widgets/quit_group_session_back_button.dart';
import 'package:mobile_interface/src/features/courses/models/lesson_item.dart';
import 'package:mobile_interface/src/features/social/controllers/social_controller.dart';

class GroupSessionActiveLobbyPage extends StatefulWidget {
  const GroupSessionActiveLobbyPage({super.key});

  @override
  State<GroupSessionActiveLobbyPage> createState() =>
      _GroupSessionActiveLobbyPageState();
}

class _GroupSessionActiveLobbyPageState extends State<GroupSessionActiveLobbyPage>
    with TickerProviderStateMixin {
  Room? _room;
  EventsListener<RoomEvent>? _roomEvents;
  String? _voiceError;
  bool _voiceConnecting = false;
  bool _micEnabled = false;
  bool _turnSyncing = false;
  Timer? _turnPoller;
  RealtimeChannel? _turnStateChannel;
  String? _turnStateLobbyKey;
  Timer? _turnMicTimer;
  bool _turnMicActive = false;
  String _lobbyKind = 'private';
  final TextEditingController _scoreController = TextEditingController();
  _LobbyTurnState? _turnState;
  final Set<String> _newlyPlantedFlags = <String>{};
  late final AnimationController _turnMicPulse;
  late final AnimationController _turnMicProgress;

  /// Counts completed rounds — used to advance through session items.
  /// Incremented whenever roundComplete transitions from true → false.
  int _roundIndex = 0;

  @override
  void initState() {
    super.initState();
    _turnMicPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _turnMicProgress = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _lobbyKind = ModalRoute.of(context)?.settings.arguments as String? ?? 'private';
    _startTurnStateSync();
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
      final micPub = await room.localParticipant?.setMicrophoneEnabled(false);

      room.addListener(_onRoomChanged);

      if (!mounted) return;
      setState(() {
        _room = room;
        _micEnabled = false;
        _turnMicActive = false;
        if (micPub == null) {
          _voiceError = 'Connected to voice. Mic will activate only during your turn.';
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

  Future<void> _submitCurrentScore(List<PrivateLobby> players) async {
    final state = _turnState;
    if (players.isEmpty || state == null || state.roundComplete) return;
    final value = double.tryParse(_scoreController.text.trim());
    if (value == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a numeric score first.')),
      );
      return;
    }

    final lobbyId = int.tryParse(players.first.lobbyId);
    if (lobbyId == null) return;

    final ctrl = context.read<GroupSessionController>();
    try {
      final json = await ctrl.submitLobbyTurnScore(
        lobbyId: lobbyId,
        lobbyKind: _lobbyKind,
        score: value.clamp(0, 100).toDouble(),
      );
      final next = _LobbyTurnState.fromJson(json);
      final latestUserId = next.latestScoredUserId;
      if (!mounted) return;
      setState(() {
        _turnState = next;
        _scoreController.clear();
        if (latestUserId != null) {
          _newlyPlantedFlags.add(latestUserId);
        }
      });
      await _handleTurnMicPermissions();
      await Future<void>.delayed(const Duration(milliseconds: 850));
      if (!mounted || latestUserId == null) return;
      setState(() {
        _newlyPlantedFlags.remove(latestUserId);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Score submit failed (check turn order).')),
      );
      await _syncTurnState();
    }
  }

  Future<void> _voteNextRound(List<PrivateLobby> players) async {
    final state = _turnState;
    if (players.isEmpty || state == null || !state.roundComplete) return;

    final lobbyId = int.tryParse(players.first.lobbyId);
    if (lobbyId == null) return;

    final ctrl = context.read<GroupSessionController>();
    try {
      final json = await ctrl.voteLobbyNextRound(
        lobbyId: lobbyId,
        lobbyKind: _lobbyKind,
      );
      final next = _LobbyTurnState.fromJson(json);
      if (!mounted) return;
      setState(() {
        // Detect round transition: was complete, now active → new round started.
        if (_turnState?.roundComplete == true && !next.roundComplete) {
          _roundIndex++;
        }
        _turnState = next;

        if (!next.roundComplete) {
          _newlyPlantedFlags.clear();
          _scoreController.clear();
        }
      });
      await _handleTurnMicPermissions();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vote failed. Try again.')),
      );
      await _syncTurnState();
    }
  }

  void _startTurnStateSync() {
    _subscribeToTurnStateRealtime();
    _turnPoller?.cancel();
    _turnPoller = Timer.periodic(const Duration(seconds: 8), (_) {
      unawaited(_syncTurnState());
    });
    unawaited(_syncTurnState());
  }

  void _subscribeToTurnStateRealtime() {
    final ctrl = context.read<GroupSessionController>();
    final players = ctrl.privateLobby;
    if (players.isEmpty) return;

    final lobbyId = int.tryParse(players.first.lobbyId);
    if (lobbyId == null) return;
    final lobbyKey = '$_lobbyKind:$lobbyId';
    if (_turnStateLobbyKey == lobbyKey && _turnStateChannel != null) return;

    if (_turnStateChannel != null) {
      Supabase.instance.client.removeChannel(_turnStateChannel!);
      _turnStateChannel = null;
    }

    _turnStateLobbyKey = lobbyKey;
    _turnStateChannel = Supabase.instance.client
        .channel('lobby_turn_state_$lobbyKey')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'lobby_turn_state',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'lobby_key',
            value: lobbyKey,
          ),
          callback: (_) {
            unawaited(_syncTurnState());
          },
        )
        .subscribe();
  }

  Future<void> _syncTurnState() async {
    if (_turnSyncing) return;
    final ctrl = context.read<GroupSessionController>();
    final players = ctrl.privateLobby;
    if (players.isEmpty) return;
    final lobbyId = int.tryParse(players.first.lobbyId);
    if (lobbyId == null) return;
    _turnSyncing = true;
    try {
      final json = await ctrl.getLobbyTurnState(
        lobbyId: lobbyId,
        lobbyKind: _lobbyKind,
      );
      final next = _LobbyTurnState.fromJson(json);
      final prevSeq = _turnState?.eventSeq ?? 0;
      final nextSeq = next.eventSeq;
      final latestUserId = next.latestScoredUserId;
      if (!mounted) return;
      setState(() {
        if (_turnState?.roundComplete == true && !next.roundComplete) {
          _roundIndex++;
        }
        _turnState = next;
        if (latestUserId != null && nextSeq > prevSeq) {
          _newlyPlantedFlags.add(latestUserId);
        }
      });
      await _handleTurnMicPermissions();
      if (latestUserId != null && nextSeq > prevSeq) {
        await Future<void>.delayed(const Duration(milliseconds: 850));
        if (!mounted) return;
        setState(() {
          _newlyPlantedFlags.remove(latestUserId);
        });
      }
    } catch (_) {
      // Keep current UI state if backend sync fails transiently.
    } finally {
      _turnSyncing = false;
    }
  }

  Future<void> _toggleMic() async {
    if (_turnMicActive) {
      await _stopTurnMicWindow();
      return;
    }
    if (!_isMyTurn()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the active speaker can use the microphone.')),
      );
      return;
    }
    final room = _room;
    if (room == null) return;
    try {
      final micPub = await room.localParticipant?.setMicrophoneEnabled(true);
      if (!mounted) return;
      setState(() {
        _micEnabled = micPub != null;
        _turnMicActive = _micEnabled;
        _voiceError = (micPub == null)
            ? 'Microphone publish failed. Check browser permissions.'
            : null;
      });
      if (_micEnabled) {
        _turnMicTimer?.cancel();
        _turnMicProgress.forward(from: 0);
        _turnMicPulse.repeat(reverse: true);
        _turnMicTimer = Timer(const Duration(seconds: 10), () {
          unawaited(_stopTurnMicWindow());
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _voiceError = 'Failed to toggle mic: $e';
      });
    }
  }

  Future<void> _stopTurnMicWindow() async {
    _turnMicTimer?.cancel();
    _turnMicTimer = null;
    _turnMicProgress.stop();
    _turnMicProgress.reset();
    _turnMicPulse.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    final room = _room;
    if (room != null) {
      try {
        await room.localParticipant?.setMicrophoneEnabled(false);
      } catch (_) {
        // Best-effort mute.
      }
    }
    if (!mounted) return;
    setState(() {
      _micEnabled = false;
      _turnMicActive = false;
    });
  }

  bool _isMyTurn() {
    final state = _turnState;
    final myUserId = context.read<GroupSessionController>().myUserId;
    if (state == null || myUserId == null || myUserId.isEmpty || state.roundComplete) {
      return false;
    }
    return state.currentPlayer?.userId == myUserId;
  }

  Future<void> _handleTurnMicPermissions() async {
    if (_isMyTurn()) return;
    if (_turnMicActive || _micEnabled) {
      await _stopTurnMicWindow();
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
    _turnPoller?.cancel();
    final channel = _turnStateChannel;
    if (channel != null) {
      Supabase.instance.client.removeChannel(channel);
    }
    _turnMicTimer?.cancel();
    _turnMicPulse.dispose();
    _turnMicProgress.dispose();
    _scoreController.dispose();
    unawaited(_disconnectVoice());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<GroupSessionController>();
    final t = Theme.of(context);
    final players = ctrl.privateLobby;
    if (players.isNotEmpty) {
      _subscribeToTurnStateRealtime();
    }
    final state = _turnState;
    final allTurnsScored = state?.roundComplete ?? false;

    final items = ctrl.sessionItems;
    final LessonItem? currentItem = items.isEmpty
        ? null
        : items[_roundIndex % items.length];
    final queue = state?.queueParticipants ?? const <_TurnParticipant>[];
    final currentPlayer = state?.currentPlayer;
    final scoresByPlayer = state?.scoresByPlayer ?? const <String, double>{};
    final myUserId = ctrl.myUserId;
    final nextRoundVotes = state?.nextRoundVotes ?? const <String>[];
    final nextRoundVoteCount = state?.nextRoundVoteCount ?? 0;
    final haveIVotedNextRound =
        myUserId != null && myUserId.isNotEmpty && nextRoundVotes.contains(myUserId);
    final participantCount = state?.participants.length ?? players.length;
    final isMyTurn = _isMyTurn();

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const QuitGroupSessionBackButton(),
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Time',
                            style: t.textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '10',
                    style: t.textTheme.displayLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Prompt:',
                    style: t.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: currentItem == null
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            children: [
                              Text(
                                currentItem.text,
                                style: t.textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              if (currentItem.ipa != null && currentItem.ipa!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  currentItem.ipa!,
                                  style: t.textTheme.titleMedium?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    allTurnsScored
                        ? 'Round complete!'
                        : '${currentPlayer?.displayName ?? 'Player'} get ready!',
                    style: t.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _TurnMountainView(
                      players: players,
                      orderedPlayers: queue,
                      currentPlayerId: currentPlayer?.userId,
                      scoresByPlayer: scoresByPlayer,
                      newlyPlantedFlags: _newlyPlantedFlags,
                      profileImages: {
                        for (final u in [
                          ...context.watch<SocialController>().followers,
                          ...context.watch<SocialController>().following,
                        ])
                          u.id: u.profileImageUrl,
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _TurnLimitedMicButton(
                    connecting: _voiceConnecting,
                    connected: _room != null,
                    micEnabled: _micEnabled,
                    isMyTurn: isMyTurn,
                    activeWindow: _turnMicActive,
                    pulse: _turnMicPulse,
                    progress: _turnMicProgress,
                    onPressed: _voiceConnecting
                        ? null
                        : () {
                            if (_room == null) {
                              _connectVoice();
                            } else {
                              _toggleMic();
                            }
                          },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isMyTurn
                        ? (_turnMicActive ? 'You are live now (10s max).' : 'Your turn: tap mic to speak (10s).')
                        : 'Only ${currentPlayer?.displayName ?? 'current speaker'} can use the mic',
                    style: t.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  if (_room != null || _voiceConnecting)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _voiceConnecting
                                ? AppColors.accent2
                                : (_room != null ? AppColors.success : AppColors.failure),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _voiceConnecting
                              ? 'Connecting voice...'
                              : (_room != null ? 'Connected to voice' : 'Voice offline'),
                          style: t.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  if (_voiceError != null && _room == null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Voice unavailable',
                      style: t.textTheme.bodySmall?.copyWith(color: AppColors.failure),
                    )
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _scoreController,
                    enabled: !allTurnsScored,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter score (0-100)',
                      hintStyle: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.surface.withValues(alpha: 0.6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadii.md),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _submitCurrentScore(players),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: players.isEmpty
                          ? null
                          : (allTurnsScored
                              ? (haveIVotedNextRound ? null : () => _voteNextRound(players))
                              : () => _submitCurrentScore(players)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                          side: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: Text(
                        allTurnsScored
                            ? (haveIVotedNextRound
                                ? 'Voted ($nextRoundVoteCount/$participantCount)'
                                : 'Vote next round ($nextRoundVoteCount/$participantCount)')
                            : 'Submit score',
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: ctrl.isLoading || players.isEmpty ? null : () => _leaveLobby(context),
                    child: Text(
                      'Leave lobby',
                      style: t.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TurnMountainView extends StatelessWidget {
  const _TurnMountainView({
    required this.players,
    required this.orderedPlayers,
    required this.currentPlayerId,
    required this.scoresByPlayer,
    required this.newlyPlantedFlags,
    required this.profileImages,
  });

  final List<PrivateLobby> players;
  final List<_TurnParticipant> orderedPlayers;
  final String? currentPlayerId;
  final Map<String, double> scoresByPlayer;
  final Set<String> newlyPlantedFlags;
  final Map<String, String?> profileImages;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        return Stack(
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, height),
              painter: _MountainPainter(),
            ),
            Positioned(
              left: 30,
              top: 8,
              child: Text(
                '0.00 m',
                style: t.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: Icon(
                Icons.near_me_rounded,
                color: AppColors.textPrimary,
                size: 14,
              ),
            ),
            if (players.isNotEmpty)
              ...orderedPlayers.asMap().entries.map((entry) {
                final i = entry.key;
                final p = entry.value;
                final y = 52 + i * 40.0;
                final isCurrent = p.userId == currentPlayerId;
                return Positioned(
                  left: 4,
                  top: y,
                  child: _PlayerOrderItem(
                    label: p.displayName,
                    isCurrent: isCurrent,
                    color: _playerColor(i),
                    imageUrl: profileImages[p.userId],
                  ),
                );
              }),
            ...players.map((p) {
              final score = scoresByPlayer[p.userId];
              if (score == null) return const SizedBox.shrink();
              final top = math.max(20.0, height - 42 - ((score / 100) * (height - 70)));
              final slopeX = _mountainSlopeX(top, constraints.maxWidth, height);
              final flagColor = _colorForUser(p.userId);
              return Positioned(
                left: slopeX + 10,
                top: top,
                child: _FlagMarker(
                  animated: newlyPlantedFlags.contains(p.userId),
                  color: flagColor,
                ),
              );
            }),
            // Positioned(
            //   left: 2,
            //   bottom: 0,
            //   child: Text(
            //     'Altitude',
            //     style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
            //   ),
            // ),
          ],
        );
      },
    );
  }

  Color _playerColor(int idx) {
    const palette = [
      Color(0xFFC06BFF),
      Color(0xFF67A9FF),
      Color(0xFF74EC8A),
      Color(0xFFE8F087),
      Color(0xFFF57E62),
    ];
    return palette[idx % palette.length];
  }

  Color _colorForUser(String userId) {
    final idx = orderedPlayers.indexWhere((p) => p.userId == userId);
    if (idx < 0) return _playerColor(0);
    return _playerColor(idx);
  }

  double _mountainSlopeX(double y, double width, double height) {
    final start = Offset(44, height - 20);
    final end = Offset(width * 0.82, height * 0.28);
    final dy = start.dy - end.dy;
    if (dy <= 0) return start.dx;
    final t = ((start.dy - y) / dy).clamp(0.0, 1.0);
    return start.dx + (end.dx - start.dx) * t;
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.85)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final dimLinePaint = Paint()
      ..color = AppColors.textSecondary.withValues(alpha: 0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final verticalX = 20.0;
    final topY = 24.0;
    final bottomY = size.height + 16;
    canvas.drawLine(Offset(verticalX, topY), Offset(verticalX, bottomY), linePaint);

    final ridgePath = Path()
      ..moveTo(verticalX + 24, bottomY)
      ..lineTo(size.width * 0.84, size.height * 0.11)
      ..lineTo(size.width + 12, size.height * 0.40);
    canvas.drawPath(ridgePath, dimLinePaint);

    final snowPath = Path()
      ..moveTo(size.width * 0.72, size.height * 0.30) // left edge of snowcap
      ..lineTo(size.width * 0.84, size.height * 0.14) // peak
      ..lineTo(size.width * 0.94, size.height * 0.30) // right edge of snowcap
      ..lineTo(size.width * 0.89, size.height * 0.27)// right slope
      ..lineTo(size.width * 0.84, size.height * 0.30)// back to peak
      ..lineTo(size.width * 0.78, size.height * 0.27)// left slope
      ..close();
    canvas.drawPath(
      snowPath,
      Paint()..color = AppColors.textPrimary.withValues(alpha: 0.95),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerOrderItem extends StatelessWidget {
  const _PlayerOrderItem({
    required this.label,
    required this.isCurrent,
    required this.color,
    this.imageUrl,
  });

  final String label;
  final bool isCurrent;
  final Color color;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primaryBg,
            border: Border.all(
              color: color.withValues(alpha: isCurrent ? 1 : 0.8),
              width: isCurrent ? 2.6 : 2,
            ),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.45),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? ClipOval(child: Image.network(imageUrl!, fit: BoxFit.cover, width: 30, height: 30))
              : Icon(
                  Icons.person_outline_rounded,
                  color: color,
                  size: 17,
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: t.textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary.withValues(alpha: isCurrent ? 1 : 0.88),
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _TurnLimitedMicButton extends StatelessWidget {
  const _TurnLimitedMicButton({
    required this.connecting,
    required this.connected,
    required this.micEnabled,
    required this.isMyTurn,
    required this.activeWindow,
    required this.pulse,
    required this.progress,
    required this.onPressed,
  });

  final bool connecting;
  final bool connected;
  final bool micEnabled;
  final bool isMyTurn;
  final bool activeWindow;
  final AnimationController pulse;
  final AnimationController progress;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final bool isRecordingWindow = activeWindow && connected;
    final Color glowColor = isRecordingWindow ? AppColors.failure : AppColors.accent;

    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glowScale = 1.0 + pulse.value * 0.18;
        final glowOpacity = isRecordingWindow ? (0.2 + pulse.value * 0.16) : 0.16;

        return SizedBox(
          width: 128,
          height: 128,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isRecordingWindow)
                SizedBox(
                  width: 128,
                  height: 128,
                  child: AnimatedBuilder(
                    animation: progress,
                    builder: (_, __) => CircularProgressIndicator(
                      value: 1.0 - progress.value,
                      strokeWidth: 3,
                      color: AppColors.failure,
                      backgroundColor: AppColors.failure.withOpacity(0.2),
                    ),
                  ),
                ),
              Transform.scale(
                scale: isRecordingWindow ? glowScale : 1.0,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withOpacity(glowOpacity),
                        blurRadius: 32,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isRecordingWindow
                      ? AppColors.failure.withOpacity(0.12)
                      : AppColors.surface,
                  border: Border.all(
                    color: isRecordingWindow
                        ? AppColors.failure.withOpacity(0.65)
                        : AppColors.accent.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: IconButton(
                  iconSize: 50,
                  padding: EdgeInsets.zero,
                  onPressed: connecting ? null : onPressed,
                  tooltip: isMyTurn ? 'Start speaking window' : 'Waiting for your turn',
                  icon: connecting
                      ? const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Icon(
                          isRecordingWindow ? Icons.stop_rounded : Icons.mic_rounded,
                          color: isRecordingWindow
                              ? AppColors.failure
                              : ((!isMyTurn && !isRecordingWindow)
                                  ? AppColors.textSecondary
                                  : AppColors.accent),
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FlagMarker extends StatelessWidget {
  const _FlagMarker({required this.animated, required this.color});

  final bool animated;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: animated ? 18 : 0, end: 0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(value, 0),
          child: Opacity(
            opacity: animated ? (1 - (value / 18).clamp(0, 1)) : 1,
            child: child,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 2,
            height: 16,
            color: AppColors.textPrimary.withValues(alpha: 0.92),
          ),
          ClipPath(
            clipper: _TriangleClipper(),
            child: Container(
              width: 14,
              height: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(size.width, size.height * 0.5)
      ..lineTo(0, 0)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _LobbyTurnState {
  const _LobbyTurnState({
    required this.currentTurnIndex,
    required this.participants,
    required this.roundComplete,
    required this.eventSeq,
    required this.latestScoredUserId,
    required this.nextRoundVotes,
    required this.nextRoundVoteCount,
  });

  final int currentTurnIndex;
  final List<_TurnParticipant> participants;
  final bool roundComplete;
  final int eventSeq;
  final String? latestScoredUserId;
  final List<String> nextRoundVotes;
  final int nextRoundVoteCount;

  factory _LobbyTurnState.fromJson(Map<String, dynamic> json) {
    final list = (json['participants'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_TurnParticipant.fromJson)
        .toList()
      ..sort((a, b) => a.turnOrder.compareTo(b.turnOrder));
    final votes = (json['next_round_votes'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
    return _LobbyTurnState(
      currentTurnIndex: (json['current_turn_index'] as num?)?.toInt() ?? 0,
      participants: list,
      roundComplete: json['round_complete'] == true,
      eventSeq: (json['event_seq'] as num?)?.toInt() ?? 0,
      latestScoredUserId: json['latest_scored_user_id'] as String?,
      nextRoundVotes: votes,
      nextRoundVoteCount: (json['next_round_vote_count'] as num?)?.toInt() ?? votes.length,
    );
  }

  Map<String, double> get scoresByPlayer {
    final out = <String, double>{};
    for (final p in participants) {
      if (p.score != null) {
        out[p.userId] = p.score!;
      }
    }
    return out;
  }

  _TurnParticipant? get currentPlayer {
    if (participants.isEmpty) return null;
    final idx = currentTurnIndex.clamp(0, participants.length - 1);
    return participants[idx];
  }

  List<_TurnParticipant> get queueParticipants {
    if (participants.isEmpty) return const [];
    final idx = currentTurnIndex.clamp(0, participants.length - 1);
    return [
      ...participants.skip(idx),
      ...participants.take(idx),
    ];
  }
}

class _TurnParticipant {
  const _TurnParticipant({
    required this.userId,
    required this.displayName,
    required this.turnOrder,
    required this.score,
  });

  final String userId;
  final String displayName;
  final int turnOrder;
  final double? score;

  factory _TurnParticipant.fromJson(Map<String, dynamic> json) {
    final dynamic rawScore = json['score'];
    return _TurnParticipant(
      userId: (json['user_id'] as String?) ?? '',
      displayName: (json['username'] as String?) ?? 'Player',
      turnOrder: (json['turn_order'] as num?)?.toInt() ?? 0,
      score: rawScore is num ? rawScore.toDouble() : null,
    );
  }
}
