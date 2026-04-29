import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:mobile_interface/src/common/services/auth_service.dart';
import 'package:mobile_interface/src/features/social/controllers/social_controller.dart';
import '../../../app/routes.dart' as routes;
import '../../../app/constants.dart';
import 'package:mobile_interface/src/features/group_session/controllers/group_session_controller.dart';
import '../data/session_topics.dart';
import '../widgets/private_code_display.dart';

class GroupSessionPrivateCreatePage extends StatefulWidget {
  const GroupSessionPrivateCreatePage({super.key});

  @override
  State<GroupSessionPrivateCreatePage> createState() => _GroupSessionPrivateCreatePageState();
}

enum _GenStatus { loading, done, failed }

class _GroupSessionPrivateCreatePageState extends State<GroupSessionPrivateCreatePage> {
  GroupSessionController? _ctrl;
  bool _isStarting = false;
  _GenStatus _genStatus = _GenStatus.loading;
  Future<void>? _genFuture;
  List<String> _lastFetchedIds = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl ??= context.read<GroupSessionController>();
  }

  @override
  void initState() {
    super.initState();

    context.read<GroupSessionController>().resetPrivateLobbyState(notify: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<GroupSessionController>();
      final userId = context.read<AuthService>().currentUser?.id ?? 'Unknown';

      () async {
        final username = await ctrl.getCurrentUsername();
        await ctrl.createLobby(userId, username);
        final lobbyId = ctrl.createPrivateLobby?.lobbyId;
        if (!mounted || lobbyId == null || lobbyId.isEmpty) return;
        await ctrl.getLobby(lobbyId);
        await ctrl.subscribeToLobby(lobbyId);
        // Kick off generation in the background while players join.
        _beginGeneration(ctrl, lobbyId);
      }();
    });
  }

  void _beginGeneration(GroupSessionController ctrl, String lobbyId) {
    final topic = kSessionTopics[Random().nextInt(kSessionTopics.length)];
    _genFuture = ctrl
        .generateSessionItems(topic)
        .then((_) => ctrl.setLobbyItems(lobbyKind: 'private', lobbyId: lobbyId))
        .then((_) {
      if (mounted) setState(() => _genStatus = _GenStatus.done);
    }).catchError((_) {
      if (mounted) setState(() => _genStatus = _GenStatus.failed);
    });
  }

  Future<void> _onStartPressed(GroupSessionController ctrl) async {
    final lobbyId = ctrl.createPrivateLobby?.lobbyId;
    if (lobbyId == null) return;

    if (_genStatus == _GenStatus.failed) {
      // Retry generation before navigating.
      setState(() {
        _genStatus = _GenStatus.loading;
        _isStarting = true;
      });
      _beginGeneration(ctrl, lobbyId);
    } else {
      setState(() => _isStarting = true);
    }

    try {
      await _genFuture;
      if (!mounted) return;
      if (_genStatus == _GenStatus.failed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to prepare session. Please try again.')),
        );
        return;
      }
      Navigator.pushNamed(
        context,
        routes.AppRoutes.groupSessionActiveLobby,
        arguments: 'private',
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  void dispose() {
    _ctrl?.unsubscribeFromLobby();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final ctrl = context.watch<GroupSessionController>();
    final meId = context.read<AuthService>().currentUser?.id;
    
    final String lobbyCode;
    if (ctrl.isLoading) {
      lobbyCode = 'Loading...';
    } else if (ctrl.createPrivateLobby?.lobbyId != null) {
      lobbyCode = (ctrl.createPrivateLobby?.lobbyId).toString();
    } else if (ctrl.error != null) {
      lobbyCode = 'Error';
    } else {
      lobbyCode = '------';
    }

    const maxPlayers = 5;
    final players = ctrl.privateLobby.toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

    // Trigger profile fetch whenever the player list changes.
    final ids = players.map((p) => p.userId).toList();
    if (ids.isNotEmpty &&
        (ids.length != _lastFetchedIds.length ||
            ids.any((id) => !_lastFetchedIds.contains(id)))) {
      _lastFetchedIds = ids;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SocialController>().fetchLobbyProfiles(ids);
      });
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
                    onPressed: () {
                      ctrl.leaveLobby();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                  ),
                ),
                const Text(
                  'Create Lobby',
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
                      'Join Code:',
                      style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                    ),
                  ),

                  const SizedBox(height: 8),

                  PrivateCodeDisplay(
                    code: lobbyCode,
                  ),
                  
                  const SizedBox(height: 16),

                  Text(
                    'Players',
                    style: t.textTheme.titleMedium,
                  ),

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
                          child: ctrl.isLoading && players.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : ctrl.error != null && players.isEmpty
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Text(
                                          ctrl.error!,
                                          style: t.textTheme.bodyMedium?.copyWith(color: AppColors.failure),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    )
                                  : ListView.separated(
                                      itemCount: players.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                                      itemBuilder: (context, index) {
                                        final p = players[index];
                                        final isMe = meId != null && p.userId == meId;
                                        final isHost = p.host == p.userId;
                                        final suffix = '${isMe ? ' (you)' : ''}${isHost ? ' 👑' : ''}';
                                        final label = '${p.username}$suffix';
                                        final social = context.watch<SocialController>();
                                        final knownUser = social.findUser(p.userId);
                                        final imageUrl = knownUser?.profileImageUrl;
                                        final rep = knownUser?.reputation ?? 0;
                                        final repColor = rep > 0
                                            ? const Color(0xFF22C55E)
                                            : rep < 0
                                                ? AppColors.failure
                                                : AppColors.textSecondary;

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: AppColors.inputFill,
                                            borderRadius: BorderRadius.circular(AppRadii.md),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 38,
                                                height: 38,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: AppColors.surface,
                                                  border: Border.all(color: AppColors.accent, width: 1.5),
                                                  image: imageUrl != null && imageUrl.isNotEmpty
                                                      ? DecorationImage(
                                                          image: NetworkImage(imageUrl),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                alignment: Alignment.center,
                                                child: imageUrl == null || imageUrl.isEmpty
                                                    ? Text(
                                                        p.username.isNotEmpty ? p.username[0].toUpperCase() : '?',
                                                        style: GoogleFonts.montserrat(
                                                          color: AppColors.accent,
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                      )
                                                    : null,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Text(
                                                  label,
                                                  style: t.textTheme.bodyLarge,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (!isMe) ...[
                                                Icon(
                                                  rep >= 0 ? Icons.thumb_up_rounded : Icons.thumb_down_rounded,
                                                  size: 13,
                                                  color: repColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  rep > 0 ? '+$rep' : '$rep',
                                                  style: GoogleFonts.inter(
                                                    color: repColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ],
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
                      onPressed: (ctrl.isLoading || ctrl.createPrivateLobby?.lobbyId == null || _isStarting)
                          ? null
                          : () => _onStartPressed(ctrl),
                      icon: _isStarting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_genStatus == _GenStatus.failed ? Icons.refresh_rounded : Icons.play_arrow_rounded),
                      label: Text(
                        _isStarting
                            ? (_genStatus == _GenStatus.loading ? 'Preparing...' : 'Starting...')
                            : (_genStatus == _GenStatus.failed ? 'Retry & Start' : 'Start'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: switch (_genStatus) {
                      _GenStatus.loading => Text(
                          'Preparing session…',
                          key: const ValueKey('loading'),
                          style: t.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                        ),
                      _GenStatus.done => Text(
                          'Session ready',
                          key: const ValueKey('done'),
                          style: t.textTheme.bodySmall?.copyWith(color: AppColors.success),
                        ),
                      _GenStatus.failed => Text(
                          'Preparation failed — tap Retry & Start',
                          key: const ValueKey('failed'),
                          style: t.textTheme.bodySmall?.copyWith(color: AppColors.failure),
                        ),
                    },
                  ),

                  // const SizedBox(height: 12),

                  // SizedBox(
                  //   width: double.infinity,
                  //   child: Text(
                  //     'Auto-updates enabled',
                  //     textAlign: TextAlign.center,
                  //     style: t.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  //   ),
                  // ),

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