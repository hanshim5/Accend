import 'package:flutter/foundation.dart';

import '../models/social_user.dart';

class SocialController extends ChangeNotifier {
  SocialController() : _users = _seedUsers;

  static const List<SocialUser> _seedUsers = [
    SocialUser(
      id: 'u1',
      displayName: 'Mina Sue',
      username: 'mina_sue',
      level: 84,
      iFollow: false,
      followsMe: true,
    ),
    SocialUser(
      id: 'u2',
      displayName: 'Steve .',
      username: 'ste_ve',
      level: 67,
      iFollow: false,
      followsMe: true,
    ),
    SocialUser(
      id: 'u3',
      displayName: 'Saul Goodman',
      username: 'saul_good',
      level: 999,
      iFollow: true,
      followsMe: true,
    ),
    SocialUser(
      id: 'u4',
      displayName: 'Markus Grayson',
      username: 'markus_grays',
      level: 41,
      iFollow: true,
      followsMe: true,
    ),
    SocialUser(
      id: 'u5',
      displayName: 'Ari Calder',
      username: 'ari_cal',
      level: 53,
      iFollow: true,
      followsMe: false,
    ),
  ];

  final List<SocialUser> _users;

  String _followersQuery = '';
  String _followingQuery = '';

  int get followerCount => _users.where((u) => u.followsMe).length;
  int get followingCount => _users.where((u) => u.iFollow).length;

  String get followersQuery => _followersQuery;
  String get followingQuery => _followingQuery;

  List<SocialUser> get followers {
    final source = _users.where((u) => u.followsMe).toList(growable: false);
    return _filterByQuery(source, _followersQuery);
  }

  List<SocialUser> get following {
    final source = _users.where((u) => u.iFollow).toList(growable: false);
    return _filterByQuery(source, _followingQuery);
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

  void follow(String userId) {
    _setFollowState(userId: userId, following: true);
  }

  void unfollow(String userId) {
    _setFollowState(userId: userId, following: false);
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

  void _setFollowState({
    required String userId,
    required bool following,
  }) {
    final index = _users.indexWhere((u) => u.id == userId);
    if (index < 0) return;

    final user = _users[index];
    if (user.iFollow == following) return;

    _users[index] = user.copyWith(iFollow: following);
    notifyListeners();
  }
}