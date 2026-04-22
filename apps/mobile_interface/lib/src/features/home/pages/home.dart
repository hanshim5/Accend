import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../app/constants.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<HomeController>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HomeController>();
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => controller.refresh(),
          color: AppColors.accent,
          child: LayoutBuilder(
            builder: (context, outerConstraints) {
              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: outerConstraints.maxHeight,
                  ),
                  child: Column(
                    children: [
                      HomeTopBar(
                        name: controller.displayName,
                        imageUrl: controller.profileImageUrl,
                      ),
                      Builder(
                        builder: (context) {
                  final topBarHeight = 80.0; // approximate HomeTopBar height
                  final available = outerConstraints.maxHeight - topBarHeight;
                  const verticalPadding = 24.0;
                  const gapAfterGoal = 10.0;
                  const gapAfterTitle = 8.0;
                  const gapBetweenButtons = 10.0;
                  const titleBlockHeight = 26.0;

                  var goalHeight = (available * 0.27).clamp(132.0, 156.0);
                  var buttonHeight = ((available - verticalPadding - gapAfterGoal - gapAfterTitle - gapBetweenButtons - titleBlockHeight - goalHeight) / 2)
                      .clamp(128.0, 170.0);

                  if (goalHeight >= buttonHeight) {
                    goalHeight = (buttonHeight - 12).clamp(112.0, 144.0);
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (controller.shouldShowBlockingHomeLoad)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: LinearProgressIndicator(minHeight: 2),
                          ),
                        SizedBox(
                          height: goalHeight,
                          child: GoalCard(
                            title: controller.activeCourseTitle,
                            currentMinutes: controller.currentMinutes,
                            totalMinutes: controller.goalMinutes,
                            streak: controller.currentStreak,
                            progress: controller.progress,
                            compact: true,
                            isLoading: controller.shouldShowBlockingHomeLoad ||
                                !controller.hasActiveCourse,
                            onKeepGoing: () {
                              if (!controller.hasActiveCourse) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('No active course to continue yet.')),
                                );
                                return;
                              }
                              Navigator.of(context).pushNamed(
                                AppRoutes.courses,
                                arguments: controller.activeCourseId,
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
