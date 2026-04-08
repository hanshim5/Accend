class SocialUser {
  const SocialUser({
    required this.id,
    required this.displayName,
    required this.username,
    this.levelLabel,
    this.nativeLanguage,
    this.learningGoalCsv,
    this.focusAreasCsv,
    required this.iFollow,
    required this.followsMe,
  });

  final String id;
  final String displayName;
  final String username;
  final String? levelLabel;
  final String? nativeLanguage;
  final String? learningGoalCsv;
  final String? focusAreasCsv;
  final bool iFollow;
  final bool followsMe;

  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      id: json['id'] as String,
      displayName: (json['display_name'] ?? json['username'] ?? 'Unknown') as String,
      username: (json['username'] ?? 'unknown') as String,
      levelLabel: json['level_label'] as String?,
      nativeLanguage: json['native_language'] as String?,
      learningGoalCsv: json['learning_goal'] as String?,
      focusAreasCsv: json['focus_areas'] as String?,
      iFollow: json['i_follow'] == true,
      followsMe: json['follows_me'] == true,
    );
  }

  SocialUser copyWith({
    String? levelLabel,
    String? nativeLanguage,
    String? learningGoalCsv,
    String? focusAreasCsv,
    bool? iFollow,
    bool? followsMe,
  }) {
    return SocialUser(
      id: id,
      displayName: displayName,
      username: username,
      levelLabel: levelLabel ?? this.levelLabel,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      learningGoalCsv: learningGoalCsv ?? this.learningGoalCsv,
      focusAreasCsv: focusAreasCsv ?? this.focusAreasCsv,
      iFollow: iFollow ?? this.iFollow,
      followsMe: followsMe ?? this.followsMe,
    );
  }
}