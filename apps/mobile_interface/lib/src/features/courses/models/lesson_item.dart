class LessonItem {
  LessonItem({
    required this.id,
    required this.lessonId,
    required this.position,
    required this.text,
    this.ipa,
    this.hint,
  });

  final String id;
  final String lessonId;
  final int position;
  final String text;
  final String? ipa;
  final String? hint;

  factory LessonItem.fromJson(Map<String, dynamic> json) {
    return LessonItem(
      id: json['id'] as String,
      lessonId: json['lesson_id'] as String,
      position: json['position'] as int,
      text: json['text'] as String,
      ipa: json['ipa'] as String?,
      hint: json['hint'] as String?,
    );
  }
}
