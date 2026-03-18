import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants.dart';
import '../controllers/group_session_controller.dart';
import '../../../app/routes.dart' as routes;
import'package:mobile_interface/src/common/services/auth_service.dart';
import '../widgets/private_code_display.dart';

class GroupSessionPrivateJoinPage extends StatefulWidget {
  const GroupSessionPrivateJoinPage({super.key});

  @override
  State<GroupSessionPrivateJoinPage> createState() => _GroupSessionSelectPageState();
}



class _GroupSessionSelectPageState extends State<GroupSessionPrivateJoinPage> {
  String? _lobbyCode;

  Future<void> _refreshLobby(BuildContext context) async {
    final ctrl = context.read<GroupSessionController>();
    final lobbyId = _lobbyCode ?? ctrl.joinPrivateLobby?.lobbyId;
    if (lobbyId == null || lobbyId.isEmpty) return;
    await ctrl.getLobby(lobbyId);
  }

  @override
  void initState() {
    super.initState();

    context.read<GroupSessionController>().resetPrivateLobbyState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<GroupSessionController>();

      final userId = context.read<AuthService>().currentUser?.id ?? 'Unknown';
      final username = context.read<AuthService>().currentUser?.email ?? 'Unknown';
      final lobbyCode = ModalRoute.of(context)?.settings.arguments as String? ?? 'Unknown';
      _lobbyCode = lobbyCode;

      () async {
        await ctrl.joinLobby(userId, int.parse(lobbyCode), username);
        if (!mounted) return;
        await ctrl.getLobby(lobbyCode);
      }();
    });
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
                      onPressed: (ctrl.isLoading || (_lobbyCode == null))
                          ? null
                          : () => Navigator.pushNamed(context, routes.AppRoutes.groupSessionActiveLobby),
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Start'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: (ctrl.isLoading || (_lobbyCode == null))
                          ? null
                          : () => _refreshLobby(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border, width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Refresh'),
                    ),
                  ),

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