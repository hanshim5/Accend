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

  /// Creates a LessonItem from a group session lobby_items row.
  ///
  /// The lobby_items table has no id or lesson_id columns — those are
  /// synthesised here so the rest of the app can treat session items
  /// identically to course lesson items.
  factory LessonItem.fromSessionJson(Map<String, dynamic> json) {
    final position = (json['position'] as num?)?.toInt() ?? 0;
    return LessonItem(
      id: 'gs-$position',
      lessonId: 'group-session',
      position: position,
      text: json['text'] as String,
      ipa: json['ipa'] as String?,
      hint: json['hint'] as String?,
    );
  }
}
