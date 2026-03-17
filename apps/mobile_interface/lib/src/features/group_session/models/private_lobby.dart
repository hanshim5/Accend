// lib/src/features/courses/models/course.dart
class PrivateLobby {
  final String id;
  final String lobbyId;
  final String username;
  final String userId;
  final String host;
  final String sessionStart;
  final DateTime joinedAt;

  PrivateLobby({
    required this.id,
    required this.lobbyId,
    required this.username,
    required this.userId,
    required this.host,
    required this.sessionStart,
    required this.joinedAt
  });

  factory PrivateLobby.fromJson(Map<String, dynamic> json) {
    return PrivateLobby(
      id: json["id"] as String,
      lobbyId: json["lobby_id"] as String,
      username: json["username"] as String,
      userId: json["user_id"] as String,
      host: json["host"] as String,
      sessionStart: json["session_start"] as String,
      joinedAt: DateTime.parse(json["joined_at"] as String),
    );
  }
}