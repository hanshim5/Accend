class OnboardingData {
  String? learningGoal;
  String? feedbackTone;
  String? accent;
  String? dailyPace;
  String? skillAssess;

  OnboardingData({
    this.learningGoal,
    this.feedbackTone,
    this.accent,
    this.dailyPace,
    this.skillAssess,
  });

  Map<String, dynamic> toJson() => {
    'learning_goal': learningGoal,
    'feedback_tone': feedbackTone,
    'accent': accent,
    'daily_pace': dailyPace,
    'skill_assess': skillAssess,
  };
}
