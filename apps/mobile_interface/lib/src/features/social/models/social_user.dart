class SocialUser {
  const SocialUser({
    required this.id,
    required this.displayName,
    required this.username,
    required this.level,
    required this.iFollow,
    required this.followsMe,
  });

  final String id;
  final String displayName;
  final String username;
  final int level;
  final bool iFollow;
  final bool followsMe;

  SocialUser copyWith({
    bool? iFollow,
    bool? followsMe,
  }) {
    return SocialUser(
      id: id,
      displayName: displayName,
      username: username,
      level: level,
      iFollow: iFollow ?? this.iFollow,
      followsMe: followsMe ?? this.followsMe,
    );
  }
}