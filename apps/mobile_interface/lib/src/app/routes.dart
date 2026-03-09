import 'package:flutter/material.dart';
import '../features/onboarding/pages/onboarding_user_info_page.dart' as ouip;
import '../features/group_session/pages/group_session_select_page.dart' as gssp;

class AppRoutes {
  static const onboardingUserInfo = '/onboarding/user-info';
  static const groupSessionSelect = '/group_session/session-select';

  // Keep these for later if you want:
  static const login = '/login';
  static const onboardingIntro = '/onboarding/intro';
  static const courses = '/courses';

  static Map<String, WidgetBuilder> get table => {
        onboardingUserInfo: (_) => const ouip.OnboardingUserInfoPage(),
        // LEO TODO 
        groupSessionSelect: (_) => const gssp.GroupSessionSelectPage(),
      };
}