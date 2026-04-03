import 'package:flutter/foundation.dart';

import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';

import '../models/social_user.dart';

class SocialController extends ChangeNotifier {
  SocialController({ApiClient? api, AuthService? auth})
      : _api = api ?? ApiClient(),
        _auth = auth ?? AuthService();

  final ApiClient _api;
  final AuthService _auth;

  List<SocialUser> _followers = const [];
  List<SocialUser> _following = const [];

  String _followersQuery = '';
  String _followingQuery = '';

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  int get followerCount => _followers.length;
  int get followingCount => _following.length;

  String get followersQuery => _followersQuery;
  String get followingQuery => _followingQuery;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;

  List<SocialUser> get followers {
    return _filterByQuery(_followers, _followersQuery);
  }

  List<SocialUser> get following {
    return _filterByQuery(_following, _followingQuery);
  }

  Future<void> load({bool force = false}) async {
    if (_isLoading) return;
    if (_hasLoaded && !force) return;

    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _error = 'You must be logged in to view followers.';
      _hasLoaded = true;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final followersJson = await _api.getList(
        '/social/followers',
        accessToken: accessToken,
      );
      final followingJson = await _api.getList(
        '/social/following',
        accessToken: accessToken,
      );

      _followers = followersJson
          .map((row) => SocialUser.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
      _following = followingJson
          .map((row) => SocialUser.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
      _hasLoaded = true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load social graph: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFollowersQuery(String value) {
    if (_followersQuery == value) return;
    _followersQuery = value;
    notifyListeners();
  }

  void setFollowingQuery(String value) {
    if (_followingQuery == value) return;
    _followingQuery = value;
    notifyListeners();
  }

  Future<void> follow(String userId) async {
    await _setFollowState(userId: userId, following: true);
  }

  Future<void> unfollow(String userId) async {
    await _setFollowState(userId: userId, following: false);
  }

  List<SocialUser> _filterByQuery(List<SocialUser> source, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return source;

    return source
        .where(
          (u) =>
              u.displayName.toLowerCase().contains(q) ||
              u.username.toLowerCase().contains(q),
        )
        .toList(growable: false);
  }

  Future<void> _setFollowState({
    required String userId,
    required bool following,
  }) async {
    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _error = 'You must be logged in to update follows.';
      notifyListeners();
      return;
    }

    try {
      if (following) {
        await _api.postJson('/social/follow/$userId', accessToken: accessToken);
      } else {
        await _api.deleteJson('/social/follow/$userId', accessToken: accessToken);
      }
      await load(force: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}