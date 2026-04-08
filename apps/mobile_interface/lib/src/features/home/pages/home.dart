import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../app/constants.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import '../../../common/widgets/colored_button.dart';
import '../../../app/routes.dart';
import '../../../features/home/widgets/home_introduction.dart';
import '../controllers/home_controller.dart';
import '../widgets/home_top_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.primaryBg,
        body: SafeArea(
          child: Column(
            children: [
              HomeTopBar(
                name: _controller.displayName,
                imagePath: _controller.profileImageUrl ?? 'assets/images/profile.png',
                isNetworkImage: _controller.profileImageUrl != null,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const verticalPadding = 24.0;
                    const gapAfterGoal = 10.0;
                    const gapAfterTitle = 8.0;
                    const gapBetweenButtons = 10.0;
                    const titleBlockHeight = 26.0;

                    var goalHeight = (constraints.maxHeight * 0.27).clamp(132.0, 156.0);
                    var buttonHeight = ((constraints.maxHeight - verticalPadding - gapAfterGoal - gapAfterTitle - gapBetweenButtons - titleBlockHeight - goalHeight) / 2)
                        .clamp(128.0, 170.0);

                    if (goalHeight >= buttonHeight) {
                      goalHeight = (buttonHeight - 12).clamp(112.0, 144.0);
                    }

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_controller.isLoading)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: LinearProgressIndicator(minHeight: 2),
                            ),
                          SizedBox(
                            height: goalHeight,
                            child: GoalCard(
                              title: _controller.activeCourseTitle,
                              currentMinutes: _controller.currentMinutes,
                              totalMinutes: _controller.goalMinutes,
                              streak: _controller.currentStreak,
                              progress: _controller.progress,
                              compact: true,
                              isLoading: _controller.isLoading || !_controller.hasActiveCourse,
                              onKeepGoing: () {
                                if (!_controller.hasActiveCourse) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('No active course to continue yet.')),
                                  );
                                  return;
                                }
                                Navigator.of(context).pushNamed(
                                  AppRoutes.courses,
                                  arguments: _controller.activeCourseId,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: gapAfterGoal),
                          Text(
                            'Practice Modes',
                            style: GoogleFonts.montserrat(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: gapAfterTitle),
                          SizedBox(
                            height: buttonHeight,
                            child: ColoredButton(
                              title: 'Solo Practice',
                              subtitle: 'Personalized AI drills',
                              icon: Icons.headphones,
                              onTap: () {
                                Navigator.of(context).pushNamed(AppRoutes.courses);
                              },
                              firstColor: 0xFF06B6D5,
                              secondColor: 0xFF49DC7E,
                              shadow: 0xFF06B6D5,
                              height: buttonHeight,
                            ),
                          ),
                          const SizedBox(height: gapBetweenButtons),
                          SizedBox(
                            height: buttonHeight,
                            child: ColoredButton(
                              icon: Icons.group,
                              title: 'Group Practice',
                              subtitle: 'Join a live conversation group',
                              onTap: () {
                                Navigator.of(context).pushNamed(AppRoutes.groupSessionSelect);
                              },
                              firstColor: 0xFF06B6D5,
                              secondColor: 0xFF984ADD,
                              shadow: 0xFF06B6D5,
                              height: buttonHeight,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(
          selectedIndex: 1,
          onDestinationSelected: (i) => _onNavTap(context, i),
        ),
      ),
    );
  }
}
