// lib/bottom_nav_bar.dart
import 'package:flutter/material.dart';

/// A reusable bottom navigation bar that wraps Flutter's [NavigationBar].
/// - [selectedIndex] controls which destination is selected.
/// - [onDestinationSelected] is called when the user taps a destination.
/// - [indicatorColor] optionally overrides the default indicator color.
class BottomNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color? indicatorColor;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.indicatorColor,
  });

  @override
  Widget build(BuildContext context) {
    // default indicator (same green used in your original file, with 20% opacity)
    final Color defaultIndicator =
        const Color.fromARGB(255, 78, 169, 18).withOpacity(0.2);

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      indicatorColor: indicatorColor ?? defaultIndicator,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.group_outlined),
          selectedIcon: Icon(Icons.group),
          label: 'Social',
        ),
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}