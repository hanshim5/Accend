import 'package:flutter/material.dart';
import 'package:mobile_interface/src/app/routes.dart';
import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';
import '../models/onboarding_data.dart';

class OnboardingController extends ChangeNotifier {
  final ApiClient apiClient;
  final AuthService authService;
  final OnboardingData data = OnboardingData();

  OnboardingController({ApiClient? apiClient, AuthService? authService})
    : apiClient = apiClient ?? ApiClient(),
      authService = authService ?? AuthService();

  void setNativeLanguage(String value) {
    data.nativeLanguage = value;
    notifyListeners();
  }

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

  void setFocusAreas(String value) {
    data.focusAreas = value;
    notifyListeners();
  }

  void reset() {
    data.nativeLanguage = null;
    data.learningGoal = null;
    data.feedbackTone = null;
    data.accent = null;
    data.dailyPace = null;
    data.skillAssess = null;
    data.focusAreas = null;
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

    Map<String, dynamic> profile;
    try {
      profile = await apiClient.getJson('/profile', accessToken: accessToken);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        await _initProfileForExistingUser(accessToken);
        profile = await apiClient.getJson('/profile', accessToken: accessToken);
      } else {
        rethrow;
      }
    }

    data.nativeLanguage = profile['native_language'] as String?;
    data.skillAssess = profile['skill_assess'] as String?;
    data.learningGoal = profile['learning_goal'] as String?;
    data.focusAreas = profile['focus_areas'] as String?;
    data.accent = profile['accent'] as String?;
    data.feedbackTone = profile['feedback_tone'] as String?;
    data.dailyPace = profile['daily_pace'] as String?;
    notifyListeners();

    if (profile['onboarding_complete'] == true) {
      return AppRoutes.shell;
    }

    if (_isMissing(data.nativeLanguage)) return AppRoutes.onboardingNativeLanguage;
    if (_isMissing(data.skillAssess)) return AppRoutes.onboardingSkillAssess;
    if (_isMissing(data.learningGoal)) return AppRoutes.onboardingLearningGoal;
    if (_isMissing(data.focusAreas)) return AppRoutes.onboardingFocusAreas;
    if (_isMissing(data.accent)) return AppRoutes.onboardingAccentSelection;
    if (_isMissing(data.feedbackTone)) return AppRoutes.onboardingFeedbackTone;
    return AppRoutes.onboardingDailyGoal;
  }

  bool _isMissing(String? value) => value == null || value.trim().isEmpty;

  Future<void> _initProfileForExistingUser(String accessToken) async {
    final user = authService.currentUser;
    if (user == null) {
      throw Exception('Missing user while initializing profile');
    }

    final metadata = user.userMetadata;
    final fullName = (metadata?['full_name'] as String?)?.trim();
    final email = (user.email ?? '').trim().toLowerCase();
    if (email.isEmpty) {
      throw Exception('Missing email while initializing profile');
    }
    final emailPrefix = (user.email ?? '').split('@').first.trim();
    final idPrefix = user.id.replaceAll('-', '').substring(0, 8);

    var username = _normalizeUsername(emailPrefix);
    if (username.length < 3) {
      username = 'user$idPrefix';
    }

    try {
      await apiClient.postJson(
        '/profile/init',
        accessToken: accessToken,
        body: {
          'username': username,
          'email': email,
          'full_name': (fullName != null && fullName.isNotEmpty)
              ? fullName
              : null,
          'native_language': null,
        },
      );
    } on ApiException catch (e) {
      if (e.statusCode != 409) rethrow;

      await apiClient.postJson(
        '/profile/init',
        accessToken: accessToken,
        body: {
          'username': 'user$idPrefix',
          'email': email,
          'full_name': (fullName != null && fullName.isNotEmpty)
              ? fullName
              : null,
          'native_language': null,
        },
      );
    }
  }

  String _normalizeUsername(String raw) {
    final lower = raw.toLowerCase();
    final sanitized = lower.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    final squashed = sanitized
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return squashed;
  }

  String? previousRouteFor(String currentRoute) {
    switch (currentRoute) {
      case AppRoutes.onboardingNativeLanguage:
        return AppRoutes.login;
      case AppRoutes.onboardingSkillAssess:
        return AppRoutes.onboardingNativeLanguage;
      case AppRoutes.onboardingLearningGoal:
        return AppRoutes.onboardingSkillAssess;
      case AppRoutes.onboardingFocusAreas:
        return AppRoutes.onboardingLearningGoal;
      case AppRoutes.onboardingAccentSelection:
        return AppRoutes.onboardingFocusAreas;
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
      'native_language': data.nativeLanguage,
      'learning_goal': data.learningGoal,
      'feedback_tone': data.feedbackTone,
      'accent': data.accent,
      'daily_pace': data.dailyPace,
      'skill_assess': data.skillAssess,
      'focus_areas': data.focusAreas,
      'mark_complete': true,
    };

    await apiClient.patchJson(
      '/profile/onboarding',
      accessToken: accessToken,
      body: updates,
    );
  }
}
