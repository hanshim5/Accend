import 'package:flutter/foundation.dart';

import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';
import 'package:mobile_interface/src/common/services/home_snapshot_cache.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required ApiClient api,
    required AuthService auth,
    required HomeSnapshotCache snapshotCache,
  })  : _api = api,
        _auth = auth,
        _snapshotCache = snapshotCache;

  final ApiClient _api;
  final AuthService _auth;
  final HomeSnapshotCache _snapshotCache;

  bool _isLoading = false;
  bool _hasStaticData = false;
  /// True once we have a persisted snapshot for this user or a successful `GET /home`.
  bool _hasHomeSnapshot = false;
  String? _error;
  String _displayName = '';
  String? _profileImageUrl;
  String? _activeCourseId;
  String _activeCourseTitle = 'No active course yet';
  int _currentMinutes = 0;
  int _goalMinutes = 10;
  int _currentStreak = 0;

  bool get isLoading => _isLoading;
  bool get hasStaticData => _hasStaticData;
  bool get hasHomeSnapshot => _hasHomeSnapshot;
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

  /// When true, the home page can hide the blocking loader / goal skeleton
  /// because streak/minutes are shown from cache while the network refreshes.
  bool get shouldShowBlockingHomeLoad => _isLoading && !_hasHomeSnapshot;

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

  Future<void> _hydrateDynamicFromDisk() async {
    final userId = _auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    final snap = await _snapshotCache.read(userId);
    if (snap == null) return;

    _currentStreak = snap.currentStreak;
    _currentMinutes = snap.currentMinutes;
    _hasHomeSnapshot = true;
  }

  Future<void> _persistDynamicSnapshot() async {
    final userId = _auth.currentUser?.id;
    if (userId == null || userId.isEmpty) return;

    await _snapshotCache.write(
      userId,
      currentStreak: _currentStreak,
      currentMinutes: _currentMinutes,
    );
    _hasHomeSnapshot = true;
  }

  void _applyDynamicFieldsFromHomeJson(Map<String, dynamic> data) {
    _currentMinutes = (data['current_minutes'] as num?)?.toInt() ?? 0;
    _currentStreak = (data['current_streak'] as num?)?.toInt() ?? 0;
  }

  /// Loads home data. On the first call it fetches both /home and /profile and
  /// caches the static fields (display name, active course, goal minutes).
  /// On subsequent calls it only fetches /home and refreshes the dynamic fields
  /// (current_minutes, current_streak), saving the /profile round-trip.
  ///
  /// Persists streak and minutes after each successful `/home` response.
  /// Applies the last persisted snapshot from disk first so the home goal card
  /// can render without a blocking load when cache exists.
  Future<void> load() async {
    if (_isLoading) return;

    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _error = 'You must be logged in.';
      notifyListeners();
      return;
    }

    await _hydrateDynamicFromDisk();
    notifyListeners();

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getJson('/home', accessToken: accessToken);

      _applyDynamicFieldsFromHomeJson(data);
      await _persistDynamicSnapshot();

      // Static fields — fetched once and cached for the session.
      if (!_hasStaticData) {
        final profile = await _api.getJson('/profile', accessToken: accessToken);

        _displayName = ((data['display_name'] as String?) ?? '').trim();
        if (_displayName.isEmpty) _displayName = '';

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

  /// Full refresh triggered by pull-to-refresh. Re-fetches both `/home` and
  /// `/profile` so every field (active course, streak, minutes, display name,
  /// profile image, goal) is up-to-date. Does not toggle [isLoading] — the
  /// [RefreshIndicator] shows its own spinner.
  Future<void> refresh() async {
    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) return;

    try {
      final results = await Future.wait([
        _api.getJson('/home', accessToken: accessToken),
        _api.getJson('/profile', accessToken: accessToken),
      ]);

      final data = results[0];
      final profile = results[1];

      _applyDynamicFieldsFromHomeJson(data);
      await _persistDynamicSnapshot();

      _displayName = ((data['display_name'] as String?) ?? '').trim();
      if (_displayName.isEmpty) _displayName = '';

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
    } catch (e) {
      debugPrint('Failed to refresh home data: $e');
    }
    notifyListeners();
  }

  /// Refreshes streak and minutes from `GET /home` and updates disk cache.
  /// Does not toggle [isLoading]; safe to call after a lesson completes.
  Future<void> refreshProgressFromServer() async {
    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) return;

    try {
      final data = await _api.getJson('/home', accessToken: accessToken);
      _applyDynamicFieldsFromHomeJson(data);
      await _persistDynamicSnapshot();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to refresh home progress: $e');
    }
  }

  /// Clears all cached data. Call this when the user logs out so the next
  /// login starts with a fresh full fetch.
  ///
  /// Pass [cacheUserId] when the auth session is already cleared (e.g. after
  /// [AuthService.signOut]) so the on-disk snapshot for that user is removed.
  Future<void> clear({String? cacheUserId}) async {
    final uid = cacheUserId ?? _auth.currentUser?.id;
    if (uid != null && uid.isNotEmpty) {
      await _snapshotCache.clear(uid);
    }

    _hasStaticData = false;
    _hasHomeSnapshot = false;
    _displayName = '';
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
