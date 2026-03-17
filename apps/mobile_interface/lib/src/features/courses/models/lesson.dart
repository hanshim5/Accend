import 'lesson_item.dart';

class Lesson {
  Lesson({
    required this.id,
    required this.courseId,
    required this.position,
    required this.title,
    required this.isCompleted,
    this.items = const [],
  });

  final String id;
  final String courseId;
  final int position;
  final String title;
  final bool isCompleted;
  final List<LessonItem> items;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    return Lesson(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      position: json['position'] as int,
      title: (json['title'] as String?) ?? 'Untitled Lesson',
      isCompleted: (json['is_completed'] as bool?) ?? false,
      items: rawItems
          .cast<Map<String, dynamic>>()
          .map(LessonItem.fromJson)
          .toList(),
    );
  }
}
