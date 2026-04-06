import 'package:flutter/foundation.dart';

import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';

import '../models/profile_page_data.dart';

class PublicProfileController extends ChangeNotifier {
  PublicProfileController({ApiClient? api, AuthService? auth})
      : _api = api ?? ApiClient(),
        _auth = auth ?? AuthService();

  final ApiClient _api;
  final AuthService _auth;

  ProfilePageData? _data;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  String? _error;

  ProfilePageData? get data => _data;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoaded && !force) return;

    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _error = 'You must be logged in to view your profile.';
      _hasLoaded = true;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final json = await _api.getJson('/profile/page', accessToken: accessToken);
      _data = ProfilePageData.fromJson(json);
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load profile page: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveProfileDetails({
    required String fullName,
    required String nativeLanguage,
    required String learningGoal,
    required String feedbackTone,
    required String accent,
    required String dailyPace,
    required String focusAreas,
  }) async {
    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _error = 'You must be logged in to update your profile.';
      notifyListeners();
      return;
    }

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      await _api.patchJson(
        '/profile',
        accessToken: accessToken,
        body: {
          'full_name': fullName,
          'native_language': nativeLanguage,
          'learning_goal': learningGoal,
          'feedback_tone': feedbackTone,
          'accent': accent,
          'daily_pace': dailyPace,
          'focus_areas': focusAreas,
        },
      );
      await load(force: true);
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to save profile details: $e');
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
}
