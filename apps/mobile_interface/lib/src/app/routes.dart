import 'package:flutter/material.dart';

import '../features/login/pages/login_page.dart';

import '../features/onboarding/pages/onboarding_user_info_page.dart';
import '../features/onboarding/pages/learning_goal.dart';
import '../features/onboarding/pages/daily_goal.dart';
import '../features/onboarding/pages/feedback_tone.dart';
import '../features/onboarding/pages/skill_assess.dart';
import '../features/onboarding/pages/accent_selection.dart';
import '../features/onboarding/pages/onboarding_complete.dart';

import '../features/courses/pages/courses_list_page.dart';
import '../features/home/pages/home.dart';
import '../features/social/pages/social.dart';
import '../features/social/pages/social_debug_page.dart';
import '../features/public_profile/pages/profile.dart';

class AppRoutes {
  static const login = '/login';

  static const onboardingUserInfo = '/onboarding/user-info';
  static const onboardingLearningGoal = '/onboarding/learning-goal';
  static const onboardingDailyGoal = '/onboarding/daily-goal';
  static const onboardingFeedbackTone = '/onboarding/feedback-tone';
  static const onboardingSkillAssess = '/onboarding/skill-assess';
  static const onboardingAccentSelection = '/onboarding/accent-selection';
  static const onboardingComplete = '/onboarding/complete';

  static const onboardingIntro = '/onboarding/intro';

  static const courses = '/courses';
  static const home = '/home';
  static const social = '/social';
  static const profile = '/profile';
  static const socialDebug = '/social/debug';

  static Map<String, WidgetBuilder> get table => {
        login: (_) => const LoginPage(),

        onboardingUserInfo: (_) => const OnboardingUserInfoPage(),
        onboardingLearningGoal: (_) => const LearningGoalPage(),
        onboardingDailyGoal: (_) => const DailyGoalPage(),
        onboardingFeedbackTone: (_) => const FeedbackTonePage(),
        onboardingSkillAssess: (_) => const SkillAssessPage(),
        onboardingAccentSelection: (_) => const AccentSelectionPage(),
        onboardingComplete: (_) => const OnboardingCompletePage(),

        courses: (_) => const CoursesListPage(),
        home: (_) => const HomePage(),
        social: (_) => const SocialPage(),
        profile: (_) => const ProfilePage(),
        socialDebug: (_) => const SocialDebugPage(),
      };
}