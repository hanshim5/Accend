import 'package:flutter/material.dart';
import '../../../app/constants.dart';
import '../controllers/group_session_controller.dart';
import '../widgets/widget1.dart';
import '../../../app/routes.dart' as routes;
import '../widgets/private_button.dart' as private_button;
import '../../../common/widgets/bottom_nav_bar.dart' as bot_nav_bar;

class GroupSessionPrivateSelectPage extends StatefulWidget {
  const GroupSessionPrivateSelectPage({super.key});

  @override
  State<GroupSessionPrivateSelectPage> createState() => _GroupSessionSelectPageState();
}

class _GroupSessionSelectPageState extends State<GroupSessionPrivateSelectPage> {

  final _lobbyCode = TextEditingController();

  bool _submitting = false;

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
                                const TextSpan(text: 'Private Sessions '),
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

                  private_button.PrivateButton(
                    title: "Create Lobby", 
                    subtitle: "Create or join with a code", 
                    icon: Icons.add_circle_outline_rounded, 
                    onTap: () {Navigator.pushNamed(context, routes.AppRoutes.groupSessionPrivateCreate);} // leo TODO Need to make it actually do something later
                  ),

                  const SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 2,
                        width: 100,
                        color: Colors.white,
                      ),

                      SizedBox(width: 10),
                      Text(
                        'Or', 
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20
                        ),
                      ),
                      SizedBox(width: 10),

                      Container(
                        height: 2,
                        width: 100,
                        color: Colors.white,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  OnboardingLabeledField(
                    label: 'Enter Lobby Code',
  
                    rightLabelColor: AppColors.failure,
                    child: TextField(
                      controller: _lobbyCode,

                      decoration: InputDecoration(
                        hintText: 'e.g. 11223344',

                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  private_button.PrivateButton(
                    title: "Join Lobby", 
                    subtitle: "Create or join with a code", 
                    icon: Icons.arrow_circle_right_outlined, 
                    onTap: () {Navigator.pushNamed(context, routes.AppRoutes.groupSessionPrivateJoin);} // leo TODO Need to make it actually do something later
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