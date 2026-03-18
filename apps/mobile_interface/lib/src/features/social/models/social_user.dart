class SocialUser {
  const SocialUser({
    required this.id,
    required this.displayName,
    required this.username,
    this.levelLabel,
    required this.iFollow,
    required this.followsMe,
  });

  final String id;
  final String displayName;
  final String username;
  final String? levelLabel;
  final bool iFollow;
  final bool followsMe;

  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      id: json['id'] as String,
      displayName: (json['display_name'] ?? json['username'] ?? 'Unknown') as String,
      username: (json['username'] ?? 'unknown') as String,
      levelLabel: json['level_label'] as String?,
      iFollow: json['i_follow'] == true,
      followsMe: json['follows_me'] == true,
    );
  }

  SocialUser copyWith({
    String? levelLabel,
    bool? iFollow,
    bool? followsMe,
  }) {
    return SocialUser(
      id: id,
      displayName: displayName,
      username: username,
      levelLabel: levelLabel ?? this.levelLabel,
      iFollow: iFollow ?? this.iFollow,
      followsMe: followsMe ?? this.followsMe,
    );
  }
}