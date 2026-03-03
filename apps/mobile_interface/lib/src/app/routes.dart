import 'package:flutter/material.dart';
import '../features/onboarding/pages/onboarding_user_info_page.dart';

class AppRoutes {
  static const onboardingUserInfo = '/onboarding/user-info';

  // Keep these for later if you want:
  static const login = '/login';
  static const onboardingIntro = '/onboarding/intro';
  static const courses = '/courses';

  static Map<String, WidgetBuilder> get table => {
        onboardingUserInfo: (_) => const OnboardingUserInfoPage(),
      };
}