import 'package:flutter/material.dart';
import 'package:mobile_interface/src/app/routes.dart';
import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';
import '../models/onboarding_data.dart';

class OnboardingController extends ChangeNotifier {
  final ApiClient apiClient;
  final AuthService authService;
  final OnboardingData data = OnboardingData();

  OnboardingController({
    ApiClient? apiClient,
    AuthService? authService,
  })  : apiClient = apiClient ?? ApiClient(),
        authService = authService ?? AuthService();

  void setLearningGoal(String value) {
    data.learningGoal = value;
    notifyListeners();
  }

  void setFeedbackTone(String value) {
    data.feedbackTone = value;
    notifyListeners();
  }

  void setAccent(String value) {
    data.accent = value;
    notifyListeners();
  }

  void setDailyPace(String value) {
    data.dailyPace = value;
    notifyListeners();
  }

  void setSkillAssess(String value) {
    data.skillAssess = value;
    notifyListeners();
  }

  Future<void> saveProgress({bool silent = true}) async {
    final accessToken = authService.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      if (silent) return;
      throw Exception('No access token');
    }

    try {
      await apiClient.patchJson(
        '/profile/onboarding',
        accessToken: accessToken,
        body: data.toJson(),
      );
    } catch (e) {
      debugPrint('Failed to save onboarding progress: $e');
      if (!silent) rethrow;
    }
  }

  Future<String> getPostLoginRoute() async {
    final accessToken = authService.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token');
    }

    final profile = await apiClient.getJson(
      '/profile',
      accessToken: accessToken,
    );

    data.skillAssess = profile['skill_assess'] as String?;
    data.learningGoal = profile['learning_goal'] as String?;
    data.accent = profile['accent'] as String?;
    data.feedbackTone = profile['feedback_tone'] as String?;
    data.dailyPace = profile['daily_pace'] as String?;
    notifyListeners();

    if (profile['onboarding_complete'] == true) {
      return AppRoutes.courses;
    }

    if (data.skillAssess == null) return AppRoutes.onboardingSkillAssess;
    if (data.learningGoal == null) return AppRoutes.onboardingLearningGoal;
    if (data.accent == null) return AppRoutes.onboardingAccentSelection;
    if (data.feedbackTone == null) return AppRoutes.onboardingFeedbackTone;
    return AppRoutes.onboardingDailyGoal;
  }

  String? previousRouteFor(String currentRoute) {
    switch (currentRoute) {
      case AppRoutes.onboardingSkillAssess:
        return AppRoutes.login;
      case AppRoutes.onboardingLearningGoal:
        return AppRoutes.onboardingSkillAssess;
      case AppRoutes.onboardingAccentSelection:
        return AppRoutes.onboardingLearningGoal;
      case AppRoutes.onboardingFeedbackTone:
        return AppRoutes.onboardingAccentSelection;
      case AppRoutes.onboardingDailyGoal:
        return AppRoutes.onboardingFeedbackTone;
      default:
        return null;
    }
  }



  Future<void> saveAll() async {
    final accessToken = authService.accessToken;
    if (accessToken == null) {
      throw Exception('No access token');
    }

    final updates = {
      'learning_goal': data.learningGoal,
      'feedback_tone': data.feedbackTone,
      'accent': data.accent,
      'daily_pace': data.dailyPace,
      'skill_assess': data.skillAssess,
      'mark_complete': true,
    };

    await apiClient.patchJson(
      '/profile/onboarding',
      accessToken: accessToken,
      body: updates,
    );
  }
}
