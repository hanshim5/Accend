import 'package:flutter/material.dart';
import '../../../app/constants.dart';
import '../../../common/widgets/primary_button.dart';
import '../controllers/group_session_controller.dart';
import '../widgets/widget1.dart';
import '../../../app/routes.dart' as routes;
import '../widgets/private_button.dart' as private_button;
import '../../../common/widgets/bottom_nav_bar.dart' as bot_nav_bar;
import '../widgets/private_code_display.dart' as private_code_display;

class GroupSessionPrivateCreatePage extends StatefulWidget {
  const GroupSessionPrivateCreatePage({super.key});

  @override
  State<GroupSessionPrivateCreatePage> createState() => _GroupSessionSelectPageState();
}

class _GroupSessionSelectPageState extends State<GroupSessionPrivateCreatePage> {


  final _lobbyCode = TextEditingController();



  @override
  void dispose() {
    _lobbyCode.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
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
                                const TextSpan(text: 'Create Lobby'),
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

                  private_code_display.PrivateCodeDisplay(
                    code: "11223344",
                  ),
                  
                  Spacer(),

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