class ProfilePageData {
  const ProfilePageData({
    required this.id,
    required this.username,
    required this.email,
    required this.onboardingComplete,
    this.fullName,
    this.nativeLanguage,
    this.learningGoal,
    this.feedbackTone,
    this.accent,
    this.dailyPace,
    this.focusAreas,
    this.profileImageUrl,
    required this.followersCount,
    required this.followingCount,
    required this.level,
    required this.currentStreak,
    required this.overallAccuracy,
    required this.lessonsCompleted,
    required this.metersClimbed,
    required this.dailyActivity,
  });

  final String id;
  final String username;
  final String email;
  final bool onboardingComplete;
  final String? fullName;
  final String? nativeLanguage;
  final String? learningGoal;
  final String? feedbackTone;
  final String? accent;
  final String? dailyPace;
  final String? focusAreas;
  final String? profileImageUrl;
  final int followersCount;
  final int followingCount;
  final int level;
  final int currentStreak;
  final double overallAccuracy;
  final int lessonsCompleted;
  final int metersClimbed;
  final List<DailyActivity> dailyActivity;

  String get displayName => (fullName?.trim().isNotEmpty ?? false) ? fullName!.trim() : username;

  String get levelLabel => 'Level $level';

  factory ProfilePageData.fromJson(Map<String, dynamic> json) {
    final profile = Map<String, dynamic>.from(json['profile'] as Map? ?? const {});
    final social = Map<String, dynamic>.from(json['social'] as Map? ?? const {});
    final stats = Map<String, dynamic>.from(json['stats'] as Map? ?? const {});
    final parsedLevel = (stats['level'] as num?)?.toInt() ?? 1;
    final activityList = (json['activity'] as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return ProfilePageData(
      id: profile['id']?.toString() ?? '',
      username: profile['username']?.toString() ?? 'unknown',
      email: profile['email']?.toString() ?? '',
      onboardingComplete: profile['onboarding_complete'] == true,
      fullName: profile['full_name']?.toString(),
      nativeLanguage: profile['native_language']?.toString(),
      learningGoal: profile['learning_goal']?.toString(),
      feedbackTone: profile['feedback_tone']?.toString(),
      accent: profile['accent']?.toString(),
      dailyPace: profile['daily_pace']?.toString(),
      focusAreas: profile['focus_areas']?.toString(),
      profileImageUrl: profile['profile_image_url']?.toString(),
      followersCount: (social['followers'] as num?)?.toInt() ?? 0,
      followingCount: (social['following'] as num?)?.toInt() ?? 0,
      level: parsedLevel < 1 ? 1 : parsedLevel,
      currentStreak: (stats['current_streak'] as num?)?.toInt() ?? 0,
      overallAccuracy: (stats['overall_accuracy'] as num?)?.toDouble() ?? 0.0,
      lessonsCompleted: (stats['lessons_completed'] as num?)?.toInt() ?? 0,
      metersClimbed: (stats['meters_climbed'] as num?)?.toInt() ?? (((stats['lessons_completed'] as num?)?.toInt() ?? 0) * 100),
      dailyActivity: activityList
          .map((item) => DailyActivity(
                date: item['date']?.toString() ?? '',
                minutes: (item['minutes'] as num?)?.toInt() ?? 0,
              ))
          .toList(),
    );
  }
}

class DailyActivity {
  final String date;
  final int minutes;

  const DailyActivity({
    required this.date,
    required this.minutes,
  });
}
