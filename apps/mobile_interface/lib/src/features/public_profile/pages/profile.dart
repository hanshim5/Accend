import 'package:flutter/material.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import '../../../app/routes.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.social);
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 2:
        break; // already here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: const Center(
        child: Text("This is the profile page!"),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 2,
        onDestinationSelected: (i) => _onNavTap(context, i),
      ),
    );
  }
}