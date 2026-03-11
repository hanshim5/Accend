import 'package:flutter/material.dart';
import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';
import '../models/onboarding_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> saveAll() async {
    final userId = authService.currentUser?.id;
    if (userId == null) throw Exception('No user ID');
    final client = Supabase.instance.client;

    await client.from('profiles').select('id').eq('id', userId).single();

    final updates = {
      'learning_goal': data.learningGoal,
      'feedback_tone': data.feedbackTone,
      'accent': data.accent,
      'daily_pace': data.dailyPace,
      'skill_assess': data.skillAssess,
      'onboarding_complete': true,
    };

    await client.from('profiles').update(updates).eq('id', userId);
  }
}
