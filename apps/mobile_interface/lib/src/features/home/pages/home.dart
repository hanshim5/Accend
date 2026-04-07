import 'package:flutter/material.dart';
import '../../../common/widgets/bottom_nav_bar.dart';
import '../../../common/widgets/colored_button.dart';
import '../../../app/routes.dart';
import '../../../features/home/widgets/home_introduction.dart';
import '../controllers/home_controller.dart';

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
        appBar: AppBar(title: Text("Home - ${_controller.displayName}")),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
              if (_controller.isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: CircularProgressIndicator(),
                ),
              GoalCard(
                title: _controller.activeCourseTitle,
                currentMinutes: _controller.currentMinutes,
                totalMinutes: _controller.goalMinutes,
                streak: _controller.currentStreak,
                progress: _controller.progress,
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
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '  Practice Modes',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ColoredButton(
                title: 'Solo Practice',
                subtitle: 'Personalized AI drills',
                icon: Icons.headphones,
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.courses);
                },
                firstColor: 0xFF06B6D5,
                secondColor: 0xFF49DC7E,
                shadow: 0xFF06B6D5,
              ),
              const SizedBox(height: 24),
              ColoredButton(
                icon: Icons.group,
                title: 'Group Practice',
                subtitle: 'Join a live conversation group',
                onTap: () {
                  Navigator.of(context).pushNamed(AppRoutes.groupSessionSelect);
                },
                firstColor: 0xFF06B6D5,
                secondColor: 0xFF984ADD,
                shadow: 0xFF06B6D5,
              ),
              const SizedBox(height: 24),
            ],
            ),
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
