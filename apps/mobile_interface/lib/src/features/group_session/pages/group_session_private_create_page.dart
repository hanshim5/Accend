import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/constants.dart';
import '../../../common/widgets/bottom_nav_bar.dart' as bot_nav_bar;
import '../controllers//group_session_controller.dart';
import '../widgets/private_code_display.dart' as private_code_display;

class GroupSessionPrivateCreatePage extends StatefulWidget {
  const GroupSessionPrivateCreatePage({super.key});

  @override
  State<GroupSessionPrivateCreatePage> createState() => _GroupSessionPrivateCreatePageState();
}

class _GroupSessionPrivateCreatePageState extends State<GroupSessionPrivateCreatePage> {


  int _selectedIndex = 1;



  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctrl = context.read<GroupSessionController>();
      ctrl.loadLobby();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

    final ctrl = context.watch<GroupSessionController>();

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
                              children: const [
                                TextSpan(text: 'Create Lobby'),
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
                  // const SizedBox(height: 30),

                  private_code_display.PrivateCodeDisplay(
                    code: lobbyCode,
                  ),
                  
                 const  Spacer(),

                  bot_nav_bar.BottomNavBar(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (index) => setState(() => _selectedIndex = index),
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