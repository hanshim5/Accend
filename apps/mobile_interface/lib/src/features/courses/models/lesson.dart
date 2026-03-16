class Lesson {
  Lesson({
    required this.id,
    required this.courseId,
    required this.position,
    required this.title,
    required this.isCompleted,
  });

  final String id;
  final String courseId;
  final int position;
  final String title;
  final bool isCompleted;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id'] as String,
      courseId: json['course_id'] as String,
      position: json['position'] as int,
      title: (json['title'] as String?) ?? 'Untitled Lesson',
      isCompleted: (json['is_completed'] as bool?) ?? false,
    );
  }
}