import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app/constants.dart';
import '../controllers/group_session_controller.dart';
import '../../../app/routes.dart' as routes;
import 'package:mobile_interface/src/common/services/auth_service.dart';
import 'package:mobile_interface/src/features/social/controllers/social_controller.dart';
import '../widgets/private_code_display.dart';

class GroupSessionPrivateJoinPage extends StatefulWidget {
  const GroupSessionPrivateJoinPage({super.key});

  @override
  State<GroupSessionPrivateJoinPage> createState() => _GroupSessionSelectPageState();
}



class _GroupSessionSelectPageState extends State<GroupSessionPrivateJoinPage> {
  GroupSessionController? _ctrl;
  String? _lobbyCode;
  bool _isStarting = false;
  List<String> _lastFetchedIds = const [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ctrl ??= context.read<GroupSessionController>();
    // Fetch profiles for any player not already in the social graph.
    final players = context.read<GroupSessionController>().privateLobby;
    final ids = players.map((p) => p.userId).toList();
    if (ids.length != _lastFetchedIds.length ||
        ids.any((id) => !_lastFetchedIds.contains(id))) {
      _lastFetchedIds = ids;
      context.read<SocialController>().fetchLobbyProfiles(ids);
    }
  }

  @override
  void initState() {
    super.initState();

    context.read<GroupSessionController>().resetPrivateLobbyState(notify: false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<GroupSessionController>();

      final userId = context.read<AuthService>().currentUser?.id ?? 'Unknown';
      final lobbyCode = ModalRoute.of(context)?.settings.arguments as String? ?? 'Unknown';
      _lobbyCode = lobbyCode;

      () async {
        final username = await ctrl.getCurrentUsername();
        await ctrl.joinLobby(userId, int.parse(lobbyCode), username);
        if (!mounted) return;
        await ctrl.getLobby(lobbyCode);
        await ctrl.subscribeToLobby(lobbyCode);
      }();
    });
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
    final requestedCode = _lobbyCode ?? (ModalRoute.of(context)?.settings.arguments as String? ?? 'Unknown');
    String lobbyCode = requestedCode;
    
    if (ctrl.isLoading) {
      lobbyCode = 'Loading...';
    } else if (ctrl.error != null) {
      lobbyCode = 'Lobby Not Found';
    } else if (ctrl.joinPrivateLobby?.lobbyId != null) {
      lobbyCode = (ctrl.joinPrivateLobby?.lobbyId).toString();
    } else {
      lobbyCode = '------';
    }

    const maxPlayers = 5;
    final players = ctrl.privateLobby.toList()
      ..sort((a, b) => a.joinedAt.compareTo(b.joinedAt));

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
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, routes.AppRoutes.groupSessionPrivateSelect);

                          ctrl.leaveLobby();
                        }, 
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),

                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.only(top:8),
                          child: RichText(
                            text: TextSpan(
                              style: t.textTheme.headlineMedium,
                              children: [
                                const TextSpan(text: 'Join Lobby'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Divider(
                    color: AppColors.border,
                    thickness: 5,
                  ),

                  const SizedBox(height: 18),

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
                      onPressed: (ctrl.isLoading || _lobbyCode == null || _isStarting)
                          ? null
                          : () async {
                              setState(() => _isStarting = true);
                              try {
                                await ctrl.fetchLobbyItems(
                                  lobbyKind: 'private',
                                  lobbyId: _lobbyCode!,
                                );
                                if (!mounted) return;
                                Navigator.pushNamed(
                                  context,
                                  routes.AppRoutes.groupSessionActiveLobby,
                                  arguments: 'private',
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to load session: $e')),
                                );
                              } finally {
                                if (mounted) setState(() => _isStarting = false);
                              }
                            },
                      icon: _isStarting
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(_isStarting ? 'Loading...' : 'Start'),
                    ),
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
    );
  }
}