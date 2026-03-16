import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants.dart';
import '../../../common/widgets/primary_button.dart';
import '../controllers/group_session_controller.dart';
import '../widgets/widget1.dart';
import '../../../app/routes.dart' as routes;
import '../widgets/private_button.dart' as private_button;
import '../../../common/widgets/bottom_nav_bar.dart' as bot_nav_bar;

class GroupSessionActiveLobbyPage extends StatefulWidget {
  const GroupSessionActiveLobbyPage({super.key});

  @override
  State<GroupSessionActiveLobbyPage> createState() => _GroupSessionActiveLobbyPageState();
}

class _GroupSessionActiveLobbyPageState extends State<GroupSessionActiveLobbyPage> {
 

  final _lobbyCode = TextEditingController();



  @override
  Widget build(BuildContext context) {

    // final ctrl = context.watch<GroupSessionController>();
    final t = Theme.of(context);

    int _selectedIndex = 1;

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
                          padding: EdgeInsets.only(top:8),
                          child: RichText(
                            text: TextSpan(
                              style: t.textTheme.headlineMedium,
                              children: [
                                const TextSpan(text: '[TEMP PAGE]'),
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

                  Spacer(),
                  // const SizedBox(height: 30),

                  // Builder(
                  //   builder: (_) {
                  //     // if (ctrl.isLoading) {
                  //     //   return const Center(child: CircularProgressIndicator());
                  //     // }

                  //     // return RichText(
                  //     //   text: TextSpan(
                  //     //     style: t.textTheme.headlineMedium,
                  //     //     children: [
                  //     //       const TextSpan(text: ctrl.privateLobby["lobby_id"]: String), // TOTALLY WRONG, BASICALLY PSEUDOCODE, BUT IDK WHAT TO DO HERE TO JUSTMAKE IT DISPLAY THE LOBBY CODE
                  //     //     ],
                  //     //   ),
                  //     // );
                  //   },
                  // ),

                  Spacer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}