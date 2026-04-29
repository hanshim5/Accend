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
  List<SocialUser> _blocked = const [];
  Set<String> _blockedIds = const {};
  Map<String, SocialUser> _lobbyProfiles = const {};

  String _followersQuery = '';
  String _followingQuery = '';
  String _blockedQuery = '';

  bool _isLoading = false;
  bool _hasLoaded = false;
  String? _error;

  int get followerCount => _followers.length;
  int get followingCount => _following.length;
  int get blockedCount => _blocked.length;

  String get followersQuery => _followersQuery;
  String get followingQuery => _followingQuery;
  String get blockedQuery => _blockedQuery;
  bool get isLoading => _isLoading;
  bool get hasLoaded => _hasLoaded;
  String? get error => _error;
  Set<String> get blockedIds => _blockedIds;
  Map<String, SocialUser> get lobbyProfiles => _lobbyProfiles;

  List<SocialUser> get followers {
    return _filterByQuery(_followers, _followersQuery);
  }

  List<SocialUser> get following {
    return _filterByQuery(_following, _followingQuery);
  }

  List<SocialUser> get blocked {
    return _filterByQuery(_blocked, _blockedQuery);
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
      final results = await Future.wait([
        _api.getList('/social/followers', accessToken: accessToken),
        _api.getList('/social/following', accessToken: accessToken),
        _api.getList('/social/blocked-ids', accessToken: accessToken)
            .catchError((_) => <dynamic>[]),
        _api.getList('/social/blocked', accessToken: accessToken)
            .catchError((_) => <dynamic>[]),
      ]);

      _followers = (results[0])
          .map((row) => SocialUser.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
      _following = (results[1])
          .map((row) => SocialUser.fromJson(Map<String, dynamic>.from(row as Map)))
          .toList(growable: false);
      _blockedIds = (results[2]).map((id) => id as String).toSet();
      _blocked = (results[3])
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

  void setBlockedQuery(String value) {
    if (_blockedQuery == value) return;
    _blockedQuery = value;
    notifyListeners();
  }

  /// Fetches public profile + reputation for every user ID in [userIds] that
  /// is not already known via followers/following. Results are stored in
  /// [lobbyProfiles] and can be merged with the social graph on read.
  Future<void> fetchLobbyProfiles(List<String> userIds) async {
    if (userIds.isEmpty) return;
    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) return;

    // Only fetch IDs we don't already know about.
    final knownIds = {
      ..._followers.map((u) => u.id),
      ..._following.map((u) => u.id),
      ..._lobbyProfiles.keys,
    };
    final toFetch = userIds.where((id) => !knownIds.contains(id)).toList();
    if (toFetch.isEmpty) return;

    try {
      final rows = await _api.postList(
        '/social/profiles/batch',
        accessToken: accessToken,
        body: toFetch,
      );
      final fetched = {
        for (final row in rows)
          (row['id'] as String): SocialUser.fromJson(Map<String, dynamic>.from(row as Map)),
      };
      _lobbyProfiles = {..._lobbyProfiles, ...fetched};
      notifyListeners();
    } catch (_) {
      // Non-fatal — lobby still works without enriched profiles.
    }
  }

  /// Look up a user by ID, checking followers, following, and lobby cache.
  SocialUser? findUser(String userId) {
    return [
      ..._followers,
      ..._following,
      ..._lobbyProfiles.values,
    ].where((u) => u.id == userId).firstOrNull;
  }

  Future<void> follow(String userId) async {
    await _setFollowState(userId: userId, following: true);
  }

  Future<void> unfollow(String userId) async {
    await _setFollowState(userId: userId, following: false);
  }

  Future<void> block(String userId) async {
    await _setBlockState(userId: userId, blocking: true);
  }

  Future<void> unblock(String userId) async {
    await _setBlockState(userId: userId, blocking: false);
  }

  /// Vote for or against a participant. [delta] is +1/-1 on first tap,
  /// +2/-2 when switching direction, or the reverse value to cancel.
  Future<void> vote(String targetId, int delta) async {
    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _error = 'You must be logged in to vote.';
      notifyListeners();
      return;
    }
    try {
      await _api.postJson(
        '/social/vote/$targetId',
        accessToken: accessToken,
        body: {'delta': delta},
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
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

  void clear() {
    _followers = const [];
    _following = const [];
    _blocked = const [];
    _blockedIds = const {};
    _lobbyProfiles = const {};
    _followersQuery = '';
    _followingQuery = '';
    _blockedQuery = '';
    _isLoading = false;
    _hasLoaded = false;
    _error = null;
    notifyListeners();
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

  Future<void> _setBlockState({
    required String userId,
    required bool blocking,
  }) async {
    final accessToken = _auth.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      _error = 'You must be logged in to block users.';
      notifyListeners();
      return;
    }

    try {
      if (blocking) {
        await _api.postJson('/social/block/$userId', accessToken: accessToken);
      } else {
        await _api.deleteJson('/social/block/$userId', accessToken: accessToken);
      }
      await load(force: true);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}