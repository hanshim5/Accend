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
    

    return NavigationBarTheme(
  data: NavigationBarThemeData(
    backgroundColor: Color(0xFF0F172A), // dark background
    labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
  return const TextStyle(color: Colors.grey);
}),
    iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: Color(0xFF06B6D4)); // selected
      }
      return const IconThemeData(color: Color(0xFF94A3B8)); // 👈 unselected
    }),
  ),
  child: NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    indicatorColor: Colors.transparent,
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
  ),
);
  }
}