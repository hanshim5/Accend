import 'package:flutter/material.dart';

import '../features/login/pages/login_page.dart';

import '../features/onboarding/pages/onboarding_user_info_page.dart';
import '../features/onboarding/pages/learning_goal.dart';
import '../features/onboarding/pages/daily_goal.dart';
import '../features/onboarding/pages/feedback_tone.dart';
import '../features/onboarding/pages/skill_assess.dart';
import '../features/onboarding/pages/accent_selection.dart';

import '../features/courses/pages/courses_list_page.dart';

class AppRoutes {
  static const login = '/login';

  static const onboardingUserInfo = '/onboarding/user-info';
  static const onboardingLearningGoal = '/onboarding/learning-goal';
  static const onboardingDailyGoal = '/onboarding/daily-goal';
  static const onboardingFeedbackTone = '/onboarding/feedback-tone';
  static const onboardingSkillAssess = '/onboarding/skill-assess';
  static const onboardingAccentSelection = '/onboarding/accent-selection';

  // Keep these for later if you want:
  static const onboardingIntro = '/onboarding/intro';
  static const courses = '/courses';

  static Map<String, WidgetBuilder> get table => {
        login: (_) => const LoginPage(),

        onboardingUserInfo: (_) => const OnboardingUserInfoPage(),
        onboardingLearningGoal: (_) => const LearningGoalPage(),
        onboardingDailyGoal: (_) => const DailyGoalPage(),
        onboardingFeedbackTone: (_) => const FeedbackTonePage(),
        onboardingSkillAssess: (_) => const SkillAssessPage(),
        onboardingAccentSelection: (_) => const AccentSelectionPage(),

        courses: (_) => const CoursesListPage(),
      };
}