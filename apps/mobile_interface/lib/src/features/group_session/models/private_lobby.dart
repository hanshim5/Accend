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
      id: json["id"].toString(),
      lobbyId: json["lobby_id"].toString(),
      username: json["username"] as String,
      userId: json["user_id"].toString(),
      host: json["host"].toString(),
      sessionStart: json["session_start"].toString(),
      joinedAt: json["joined_at"] is String
        ? DateTime.parse(json["joined_at"] as String)
        : (json["joined_at"] as DateTime),
    );
  }
}