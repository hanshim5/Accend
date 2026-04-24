import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:mobile_interface/src/common/services/auth_service.dart';
import '../../../app/constants.dart';
import '../../../app/routes.dart' as routes;
import '../controllers/group_session_controller.dart';
import '../data/session_topics.dart';
import '../widgets/private_code_display.dart';

/// Matchmaking: loading until lobby has 5 players or 10s timeout, then shows lobby.
class GroupSessionPublicMatchPage extends StatefulWidget {
  const GroupSessionPublicMatchPage({super.key});

  @override
  State<GroupSessionPublicMatchPage> createState() => _GroupSessionPublicMatchPageState();
}

class _GroupSessionPublicMatchPageState extends State<GroupSessionPublicMatchPage> {
  Timer? _timeoutTimer;
  bool _timedOut = false;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    context.read<GroupSessionController>().resetPrivateLobbyState(notify: false);

    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (mounted) setState(() => _timedOut = true);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctrl = context.read<GroupSessionController>();
      await ctrl.matchmakePublicLobby();
      if (!mounted) return;
      final id = ctrl.joinPrivateLobby?.lobbyId;
      if (id != null && id.isNotEmpty) {
        await ctrl.getPublicLobby(id, showLoading: false);
        await ctrl.subscribeToPublicLobby(id);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    context.read<GroupSessionController>().unsubscribeFromLobby();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final ctrl = context.watch<GroupSessionController>();
    final meId = context.read<AuthService>().currentUser?.id;

    const maxPlayers = 5;
    final players = ctrl.privateLobby.toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    final lobbyCode = ctrl.joinPrivateLobby?.lobbyId != null
        ? ctrl.joinPrivateLobby!.lobbyId.toString()
        : '------';

    final waiting =
        ctrl.error == null && players.length < maxPlayers && !_timedOut;

    if (waiting || (ctrl.isLoading && players.isEmpty && ctrl.error == null)) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'Finding a lobby…',
                      style: t.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Waiting for players (${players.length}/$maxPlayers)',
                      style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (ctrl.error != null && players.isEmpty) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ctrl.error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: const Text('Back'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
        children: [
          Container(
            height: 69,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              border: Border(
                bottom: BorderSide(color: Color(0xFF1E293B), width: 2),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 4,
                  child: IconButton(
                    onPressed: () async {
                      await ctrl.leavePublicLobby();
                      if (context.mounted) Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  ),
                ),
                const Text(
                  'Public Lobby',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(
                      children: [
                        Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Lobby:',
                      style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrivateCodeDisplay(code: lobbyCode),
                  const SizedBox(height: 16),
                  Text('Players', style: t.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 18),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadii.lg),
                          ),
                          child: ListView.separated(
                            itemCount: players.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final p = players[index];
                              final isMe = meId != null && p.userId == meId;
                              final isHost = p.host == p.userId;
                              final suffix = '${isMe ? ' (me)' : ''}${isHost ? ' 👑' : ''}';
                              final label = '${p.username}$suffix';
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.inputFill,
                                  borderRadius: BorderRadius.circular(AppRadii.md),
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    label,
                                    style: t.textTheme.bodyLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Positioned(
                          right: 12,
                          bottom: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${players.length}/$maxPlayers',
                              style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: (players.isEmpty || _isStarting)
                          ? null
                          : () async {
                              final lobbyId = ctrl.joinPrivateLobby?.lobbyId;
                              if (lobbyId == null) return;
                              final isHost = ctrl.joinPrivateLobby?.host == true;
                              setState(() => _isStarting = true);
                              try {
                                if (isHost) {
                                  final topic = kSessionTopics[Random().nextInt(kSessionTopics.length)];
                                  await ctrl.generateSessionItems(topic);
                                  await ctrl.setLobbyItems(lobbyKind: 'public', lobbyId: lobbyId);
                                } else {
                                  await ctrl.fetchLobbyItems(lobbyKind: 'public', lobbyId: lobbyId);
                                }
                                if (!mounted) return;
                                Navigator.pushNamed(
                                  context,
                                  routes.AppRoutes.groupSessionActiveLobby,
                                  arguments: 'public',
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to prepare session: $e')),
                                );
                              } finally {
                                if (mounted) setState(() => _isStarting = false);
                              }
                            },
                      icon: _isStarting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(_isStarting ? 'Preparing...' : 'Start'),
                    ),
                  ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
