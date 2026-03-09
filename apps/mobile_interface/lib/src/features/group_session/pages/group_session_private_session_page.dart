import 'package:flutter/material.dart';
import '../../../app/constants.dart';
import '../../../common/widgets/primary_button.dart';
import '../controllers/group_session_lobby_code_controller.dart';
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
  final _c = OnboardingUserInfoController();

  final _lobbyCode = TextEditingController();

  bool _submitting = false;

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
                    onTap: () {print('Create Private Lobby Pressed');},
                    // onTap: () {Navigator.pushNamed(context, routes.AppRoutes.groupSessionPrivateSelect);} // leo TODO Need to make it actually do something later
                  ),

                  const SizedBox(height: 18),

                  OnboardingLabeledField(
                    label: 'Enter Lobby Code',
                    rightLabel: _c.lobbyCodeErr != null ? 'Cannot be empty' : null,
                    rightLabelColor: AppColors.failure,
                    child: TextField(
                      controller: _lobbyCode,
                      onChanged: (_) {
                        if (_c.lobbyCodeErr != null) _validate();
                      },
                      decoration: InputDecoration(
                        hintText: 'e.g. 11223344',
                        errorText: _c.lobbyCodeErr,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  private_button.PrivateButton(
                    title: "Join Lobby", 
                    subtitle: "Create or join with a code", 
                    icon: Icons.arrow_circle_right_outlined, 
                    // onTap: () {Navigator.pushNamed(context, routes.AppRoutes.groupSessionPrivateSelect);} // leo TODO Need to make it actually do something later
                    onTap: () {print('Join Private Lobby Pressed');},
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