// lib/src/features/courses/models/course.dart
class Course {
  final String id;
  final String userId;
  final String title;
  final DateTime createdAt;

  // UI-facing values
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

  /// Convert backend enum -> UI display string
  static String _mapStatus(dynamic raw) {
    final value = (raw as String?)?.toLowerCase();

    switch (value) {
      case "completed":
        return "COMPLETE";
      case "in_progress":
        return "IN PROGRESS";
      case "not_started":
        return "NOT STARTED";
      default:
        // fallback if backend already sends UI string
        return raw is String && raw.isNotEmpty
            ? raw
            : "NOT STARTED";
    }
  }

  /// Convert backend progress_percent (0-100) -> 0.0-1.0
  static double _mapProgress(Map<String, dynamic> json) {
    final percent = json["progress_percent"];
    if (percent is num) {
      return (percent.toDouble() / 100.0).clamp(0.0, 1.0);
    }

    // Backward compatibility if backend ever sends 0-1 progress
    final raw = json["progress"];
    if (raw is num) {
      return raw.toDouble().clamp(0.0, 1.0);
    }

    return 0.0;
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json["id"] as String,
      userId: json["user_id"] as String,
      title: (json["title"] as String?) ?? "Untitled",
      createdAt: DateTime.parse(json["created_at"] as String),

      progress: _mapProgress(json),
      status: _mapStatus(json["status"]),
      imageUrl: json["image_url"] as String?,
    );
  }
}