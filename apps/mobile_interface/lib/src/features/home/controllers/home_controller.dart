import 'package:flutter/foundation.dart';

import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({ApiClient? api, AuthService? auth})
      : _api = api ?? ApiClient(),
        _auth = auth ?? AuthService();

  final ApiClient _api;
  final AuthService _auth;

  bool _isLoading = false;
  String? _error;
  String _displayName = 'there';
  String? _activeCourseId;
  String _activeCourseTitle = 'No active course yet';
  int _currentMinutes = 0;
  int _goalMinutes = 10;
  int _currentStreak = 0;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String get displayName => _displayName;
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

      _displayName = ((data['display_name'] as String?) ?? 'there').trim();
      if (_displayName.isEmpty) _displayName = 'there';
      _currentMinutes = (data['current_minutes'] as int?) ?? 0;
      _goalMinutes = (data['goal_minutes'] as int?) ?? 10;
      _currentStreak = (data['current_streak'] as int?) ?? 0;

      final activeCourse = data['active_course'];
      if (activeCourse is Map<String, dynamic>) {
        _activeCourseId = (activeCourse['id'] as String?)?.trim();
        _activeCourseTitle = ((activeCourse['title'] as String?) ?? 'Untitled course').trim();
      } else {
        _activeCourseId = null;
        _activeCourseTitle = 'No active course yet';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load home data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
