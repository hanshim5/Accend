import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants.dart';
import '../../../common/widgets/primary_button.dart';
import '../controllers/group_session_controller.dart';

class GroupSessionActiveLobbyPage extends StatefulWidget {
  const GroupSessionActiveLobbyPage({super.key});

  @override
  State<GroupSessionActiveLobbyPage> createState() => _GroupSessionActiveLobbyPageState();
}

class _GroupSessionActiveLobbyPageState extends State<GroupSessionActiveLobbyPage> {
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
                        onPressed: () => Navigator.maybePop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      ),

                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: RichText(
                            text: TextSpan(
                              style: t.textTheme.headlineMedium,
                              children: [
                                const TextSpan(text: 'Lobby'),
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

                  const Spacer(),

                  Text(
                    'Code: $lobbyCode',
                    style: t.textTheme.titleLarge,
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
                        : () async {
                            final ok = await context
                                .read<GroupSessionController>()
                                .deletePrivateLobbyRow(ctrl.privateLobby.first.id);

                            if (!context.mounted) return;
                            final msg = ok ? 'Left lobby' : 'Failed to leave lobby';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(msg)),
                            );

                            if (ok) {
                              Navigator.maybePop(context);
                            }
                          },
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