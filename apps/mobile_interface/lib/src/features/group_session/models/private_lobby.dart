// lib/src/features/courses/models/course.dart
class PrivateLobby {
  final String id;
  final String lobbyId;
  final String username;
  final String userId;
  final bool host;
  final bool sessionStart;
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
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        return normalized == 'true' || normalized == 't' || normalized == '1';
      }
      return false;
    }

    return PrivateLobby(
      id: json["id"].toString(),
      lobbyId: json["lobby_id"].toString(),
      username: json["username"] as String,
      userId: json["user_id"].toString(),
      host: parseBool(json["host"]),
      sessionStart: parseBool(json["session_start"]),
      joinedAt: json["joined_at"] is String
        ? DateTime.parse(json["joined_at"] as String)
        : (json["joined_at"] as DateTime),
    );
  }
}