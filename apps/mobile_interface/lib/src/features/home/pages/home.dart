import 'package:flutter/material.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import '../../../app/routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _onNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.of(context).pushReplacementNamed(AppRoutes.social);
        break;
      case 1:
        break; // already here
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Home")),
      body: const Center(
        child: Text("This is the home page!"),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 1,
        onDestinationSelected: (i) => _onNavTap(context, i),
      ),
    );
  }
}