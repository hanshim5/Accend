// lib/src/features/courses/models/course.dart
class Course {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;

  // UI-only for now (until backend adds these)
  final double progress; // 0.0 - 1.0
  final String status;   // "IN PROGRESS", "COMPLETE", "NOT STARTED"
  final String? imageUrl;

  Course({
    required this.id,
    required this.userId,
    required this.title,
    required this.createdAt,
    this.progress = 0.0,
    this.status = "NOT STARTED",
    this.imageUrl,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json["id"] as String,
      userId: json["user_id"] as String,
      title: (json["title"] as String?) ?? "Untitled",
      createdAt: DateTime.parse(json["created_at"] as String),

      // If backend doesn't provide these yet, keep defaults
      progress: (json["progress"] is num) ? (json["progress"] as num).toDouble() : 0.0,
      status: (json["status"] as String?) ?? "NOT STARTED",
      imageUrl: json["image_url"] as String?,
    );
  }
}