import 'package:flutter/material.dart';
import '../../../app/constants.dart';
import '../../../app/routes.dart' as routes;
import '../controllers/group_session_lobby_code_controller.dart';
import '../widgets/public_button.dart' as public_button;
import '../widgets/private_button.dart' as private_button;
import '../../../common/widgets/bottom_nav_bar.dart' as bot_nav_bar;

class GroupSessionSelectPage extends StatefulWidget {
  const GroupSessionSelectPage({super.key});

  @override
  State<GroupSessionSelectPage> createState() => _GroupSessionSelectPageState();
}

class _GroupSessionSelectPageState extends State<GroupSessionSelectPage> {
  final _c = OnboardingUserInfoController();

  final _lobbyCode = TextEditingController();

  bool _submitting = false;

  int _selectedIndex = 1;

  @override
  void dispose() {
    _lobbyCode.dispose();
    super.dispose();
  }

  void _validate() {
    _c.validate(
      lobbyCode: _lobbyCode.text
    );
    setState(() {});
  }

  Future<void> _onContinue() async {
    _validate();
    if (!_c.isValid) return;

    setState(() => _submitting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Continue (backend hookup next)')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);

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
                                const TextSpan(text: 'Group Session '),
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
                    indent: 0,
                  ),

                  Spacer(),

                  public_button.PublicButton(
                    title: "Public Room", 
                    subtitle: "Automatically match-made rooms", 
                    icon: Icons.public, 
                    onTap: () {print("Public room Pressed");} // leo TODO Need to make it actually do something later
                  ),
                  
                  const SizedBox(height: 60),
                  
                  private_button.PrivateButton(
                    title: "Private Room", 
                    subtitle: "Create or join with a code", 
                    icon: Icons.lock, 
                    onTap: () {Navigator.pushNamed(context, routes.AppRoutes.groupSessionPrivateSelect);} // leo TODO Need to make it actually do something later
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