import 'package:flutter/foundation.dart';

import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({required ApiClient api, required AuthService auth})
      : _api = api,
        _auth = auth;

  final ApiClient _api;
  final AuthService _auth;

  bool _isLoading = false;
  bool _hasStaticData = false;
  String? _error;
  String _displayName = 'there';
  String? _profileImageUrl;
  String? _activeCourseId;
  String _activeCourseTitle = 'No active course yet';
  int _currentMinutes = 0;
  int _goalMinutes = 10;
  int _currentStreak = 0;

  bool get isLoading => _isLoading;
  bool get hasStaticData => _hasStaticData;
  String? get error => _error;
  String get displayName => _displayName;
  String? get profileImageUrl => _profileImageUrl;
  String? get activeCourseId => _activeCourseId;
  String get activeCourseTitle => _activeCourseTitle;
  bool get hasActiveCourse => _activeCourseId != null && _activeCourseId!.isNotEmpty;
  int get currentMinutes => _currentMinutes;
  int get goalMinutes => _goalMinutes;
  int get currentStreak => _currentStreak;
  double get progress {
    if (_goalMinutes <= 0) return 0;
    return (_currentMinutes / _goalMinutes).clamp(0, 1).toDouble();
  }

  int _goalMinutesFromDailyPace(String? dailyPace) {
    switch ((dailyPace ?? '').trim().toLowerCase()) {
      case 'hiker':
        return 5;
      case 'climber':
        return 10;
      case 'summiter':
        return 15;
      case 'mountaineer':
        return 20;
      default:
        return 10;
    }
  }

  /// Loads home data. On the first call it fetches both /home and /profile and
  /// caches the static fields (display name, active course, goal minutes).
  /// On subsequent calls it only fetches /home and refreshes the dynamic fields
  /// (current_minutes, current_streak), saving the /profile round-trip.
  Future<void> load() async {
    if (_isLoading) return;

    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _error = 'You must be logged in.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getJson('/home', accessToken: accessToken);

      // Dynamic fields — always refresh on every visit.
      _currentMinutes = (data['current_minutes'] as int?) ?? 0;
      _currentStreak = (data['current_streak'] as int?) ?? 0;

      // Static fields — fetched once and cached for the session.
      if (!_hasStaticData) {
        final profile = await _api.getJson('/profile', accessToken: accessToken);

        _displayName = ((data['display_name'] as String?) ?? 'there').trim();
        if (_displayName.isEmpty) _displayName = 'there';

        _profileImageUrl = profile['profile_image_url'] as String?;

        final dailyPace = profile['daily_pace'] as String?;
        final backendGoal = (data['goal_minutes'] as int?) ?? 10;
        _goalMinutes = dailyPace == null || dailyPace.trim().isEmpty
            ? backendGoal
            : _goalMinutesFromDailyPace(dailyPace);

        final activeCourse = data['active_course'];
        if (activeCourse is Map<String, dynamic>) {
          _activeCourseId = (activeCourse['id'] as String?)?.trim();
          _activeCourseTitle =
              ((activeCourse['title'] as String?) ?? 'Untitled course').trim();
        } else {
          _activeCourseId = null;
          _activeCourseTitle = 'No active course yet';
        }

        _hasStaticData = true;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load home data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears all cached data. Call this when the user logs out so the next
  /// login starts with a fresh full fetch.
  void clear() {
    _hasStaticData = false;
    _displayName = 'there';
    _profileImageUrl = null;
    _activeCourseId = null;
    _activeCourseTitle = 'No active course yet';
    _currentMinutes = 0;
    _goalMinutes = 10;
    _currentStreak = 0;
    _error = null;
    notifyListeners();
  }
}
