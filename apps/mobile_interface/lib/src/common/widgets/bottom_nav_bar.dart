import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int? selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Color? indicatorColor;
  final Widget? overlay;

  const BottomNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.indicatorColor,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final bool nothingSelected = selectedIndex == null;

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0F172A), // dark background
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          return const TextStyle(color: Colors.grey);
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (!nothingSelected && states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: Color(0xFF06B6D4),
            ); // selected
          }
          return const IconThemeData(
            color: Color(0xFF94A3B8),
          ); // unselected
        }),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          NavigationBar(
            selectedIndex: selectedIndex ?? 0,
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
          if (overlay != null)
            Positioned(
              top: -28,
              child: Transform.translate(
                offset: const Offset(0, -4),
                child: overlay!,
              ),
            ),
        ],
      ),
    );
        ],
      ),
    );
  }
}