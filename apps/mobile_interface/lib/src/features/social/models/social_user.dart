class SocialUser {
  const SocialUser({
    required this.id,
    required this.displayName,
    required this.username,
    required this.level,
    this.nativeLanguage,
    this.learningGoalCsv,
    this.focusAreasCsv,
    required this.currentStreak,
    required this.overallAccuracy,
    required this.lessonsCompleted,
    required this.metersClimbed,
    required this.reputation,
    required this.iFollow,
    required this.followsMe,
    required this.iBlock,
    this.profileImageUrl,
  });

  final String id;
  final String displayName;
  final String username;
  final int level;
  final String? nativeLanguage;
  final String? learningGoalCsv;
  final String? focusAreasCsv;
  final int currentStreak;
  final double overallAccuracy;
  final int lessonsCompleted;
  final int metersClimbed;
  final int reputation;
  final bool iFollow;
  final bool followsMe;
  final bool iBlock;
  final String? profileImageUrl;

  String get levelLabel => 'Level $level';

  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      id: json['id'] as String,
      displayName: (json['display_name'] ?? json['username'] ?? 'Unknown') as String,
      username: (json['username'] ?? 'unknown') as String,
      level: ((json['level'] as num?)?.toInt() ?? 1).clamp(1, 1000000),
      nativeLanguage: json['native_language'] as String?,
      learningGoalCsv: json['learning_goal'] as String?,
      focusAreasCsv: json['focus_areas'] as String?,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      overallAccuracy: (json['overall_accuracy'] as num?)?.toDouble() ?? 0.0,
      lessonsCompleted: (json['lessons_completed'] as num?)?.toInt() ?? 0,
      metersClimbed: (json['meters_climbed'] as num?)?.toInt() ?? (((json['lessons_completed'] as num?)?.toInt() ?? 0) * 100),
      reputation: (json['reputation'] as num?)?.toInt() ?? 0,
      iFollow: json['i_follow'] == true,
      followsMe: json['follows_me'] == true,
      iBlock: json['i_block'] == true,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }

  SocialUser copyWith({
    int? level,
    String? nativeLanguage,
    String? learningGoalCsv,
    String? focusAreasCsv,
    int? currentStreak,
    double? overallAccuracy,
    int? lessonsCompleted,
    int? metersClimbed,
    int? reputation,
    bool? iFollow,
    bool? followsMe,
    bool? iBlock,
    String? profileImageUrl,
  }) {
    return SocialUser(
      id: id,
      displayName: displayName,
      username: username,
      level: level ?? this.level,
      nativeLanguage: nativeLanguage ?? this.nativeLanguage,
      learningGoalCsv: learningGoalCsv ?? this.learningGoalCsv,
      focusAreasCsv: focusAreasCsv ?? this.focusAreasCsv,
      currentStreak: currentStreak ?? this.currentStreak,
      overallAccuracy: overallAccuracy ?? this.overallAccuracy,
      lessonsCompleted: lessonsCompleted ?? this.lessonsCompleted,
      metersClimbed: metersClimbed ?? this.metersClimbed,
      reputation: reputation ?? this.reputation,
      iFollow: iFollow ?? this.iFollow,
      followsMe: followsMe ?? this.followsMe,
      iBlock: iBlock ?? this.iBlock,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}