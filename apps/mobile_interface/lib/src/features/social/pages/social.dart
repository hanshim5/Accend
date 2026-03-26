import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_interface/src/app/constants.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import '../controllers/social_controller.dart';

import 'followers.dart';
import 'following.dart';
import 'search_popup.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SocialController>().load();
    });
  }

  void _onNavTap(int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
        break;
      case 2:
        Navigator.of(context).pushReplacementNamed(AppRoutes.profile);
        break;
    }
  }

  Future<void> _openSearchPopup() async {
    await SearchPopup.show(context);
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
              alignment: Alignment.center,
              child: Text(
                'Social',
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.45,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0x7F1E293B),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _SegmentButton(
                              title: 'Followers',
                              isSelected: _selectedTab == 0,
                              onTap: () => setState(() => _selectedTab = 0),
                            ),
                          ),
                          Expanded(
                            child: _SegmentButton(
                              title: 'Following',
                              isSelected: _selectedTab == 1,
                              onTap: () => setState(() => _selectedTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _selectedTab == 0
                            ? const FollowersTab(key: ValueKey('followers-tab'))
                            : const FollowingTab(key: ValueKey('following-tab')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: DecoratedBox(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x33F97316),
              blurRadius: 6,
              offset: Offset(0, 4),
              spreadRadius: -4,
            ),
            BoxShadow(
              color: Color(0x33F97316),
              blurRadius: 15,
              offset: Offset(0, 10),
              spreadRadius: -3,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _openSearchPopup,
          backgroundColor: const Color(0xFFF6B17A),
          foregroundColor: Colors.white,
          elevation: 0,
          focusElevation: 0,
          hoverElevation: 0,
          highlightElevation: 0,
          disabledElevation: 0,
          shape: const CircleBorder(),
          child: const Icon(Icons.search_rounded, size: 28),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        selectedIndex: 0,
        onDestinationSelected: _onNavTap,
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 36,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x0C000000),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.montserrat(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: isSelected ? 24 : 0,
              height: 3,
              decoration: BoxDecoration(
                color: const Color(0xFF06F9F9),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}