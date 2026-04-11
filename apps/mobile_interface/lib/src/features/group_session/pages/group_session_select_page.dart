import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/constants.dart';
import '../../../app/routes.dart' as routes;
import '../../../common/widgets/colored_button.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import '../controllers/group_session_controller.dart';

class GroupSessionSelectPage extends StatefulWidget {
  const GroupSessionSelectPage({super.key});

  @override
  State<GroupSessionSelectPage> createState() => _GroupSessionSelectPageState();
}

class _GroupSessionSelectPageState extends State<GroupSessionSelectPage> {
  void _onNavTap(int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(routes.AppRoutes.social);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(routes.AppRoutes.home);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(routes.AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
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
                      onPressed: () => Navigator.of(context).pushReplacementNamed(routes.AppRoutes.home),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                    ),
                  ),
                  const Text(
                    'Group Session',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Choose your room type',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ColoredButton(
                              title: 'Public Room',
                              subtitle: 'Automatically match-made rooms',
                              icon: Icons.public,
                              onTap: () {
                                context.read<GroupSessionController>().resetPrivateLobbyState(notify: false);
                                Navigator.pushNamed(context, routes.AppRoutes.groupSessionPublicMatch);
                              },
                              firstColor: 0xFF1FB6C9,
                              secondColor: 0xFF557BE3,
                              shadow: 0xFF557BE3,
                            ),
                            const SizedBox(height: 16),
                            ColoredButton(
                              title: 'Private Room',
                              subtitle: 'Create or join with a code',
                              icon: Icons.lock,
                              onTap: () {
                                Navigator.pushNamed(context, routes.AppRoutes.groupSessionPrivateSelect);
                              },
                              firstColor: 0xFF557BE3,
                              secondColor: 0xFF8A3FFC,
                              shadow: 0xFF8A3FFC,
                            ),
                          ],
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: null,
        onDestinationSelected: _onNavTap,
      ),
    );
  }
}