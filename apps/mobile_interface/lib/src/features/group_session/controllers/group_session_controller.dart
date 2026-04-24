import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';
import 'package:mobile_interface/src/features/courses/models/lesson_item.dart';
import 'package:mobile_interface/src/features/group_session/models/private_lobby.dart';

class GroupSessionController extends ChangeNotifier {
  GroupSessionController({
    required ApiClient api,
    required AuthService auth,
  })  : _api = api,
        _auth = auth;

  final ApiClient _api;
  final AuthService _auth;

  bool _isLoading = false;
  String? _error;
  List<PrivateLobby> _privateLobby = [];
  PrivateLobby? _createPrivateLobby;
  PrivateLobby? _joinPrivateLobby;
  RealtimeChannel? _lobbyChannel;
  String? _subscribedLobbyId;
  bool _isRealtimeSyncing = false;
  List<LessonItem> _sessionItems = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PrivateLobby> get privateLobby => List.unmodifiable(_privateLobby);
  String? get myUserId => _auth.currentUser?.id;

  PrivateLobby? get createPrivateLobby => _createPrivateLobby;
  PrivateLobby? get joinPrivateLobby => _joinPrivateLobby;

  /// The AI-generated lesson items for the current group session.
  List<LessonItem> get sessionItems => List.unmodifiable(_sessionItems);

  void resetPrivateLobbyState({bool notify = true}) {
    _error = null;
    _privateLobby = [];
    _createPrivateLobby = null;
    _joinPrivateLobby = null;
    _sessionItems = [];
    if (notify) notifyListeners();
  }

  Future<String> getCurrentUsername() async {
    final user = _auth.currentUser;
    final metadataUsername = (user?.userMetadata?['username'] as String?)?.trim();
    if (metadataUsername != null && metadataUsername.isNotEmpty) {
      return metadataUsername;
    }

    final token = _auth.accessToken;
    if (token != null && token.isNotEmpty) {
      try {
        final profile = await _api.getJson('/profile', accessToken: token);
        final profileUsername = (profile['username'] as String?)?.trim();
        if (profileUsername != null && profileUsername.isNotEmpty) {
          return profileUsername;
        }
      } catch (_) {
        // Fallback below if profile lookup fails.
      }
    }

    final emailPrefix = user?.email?.split('@').first.trim();
    if (emailPrefix != null && emailPrefix.isNotEmpty) {
      return emailPrefix;
    }

    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Unknown';
  }



  Future<List<PrivateLobby>> getLobby(String lobbyId, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final token = _auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated');
      }

      final list = await _api.getList(
        '/private_lobbies/$lobbyId',
        accessToken: token,
      );
      _privateLobby = list
          .cast<Map<String, dynamic>>()
          .map((e) => PrivateLobby.fromJson(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
    return _privateLobby;

  }

  Future<List<PrivateLobby>> getPublicLobby(String lobbyId, {bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final token = _auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated');
      }

      final list = await _api.getList(
        '/public_lobbies/$lobbyId',
        accessToken: token,
      );
      _privateLobby = list
          .cast<Map<String, dynamic>>()
          .map((e) => PrivateLobby.fromJson(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
    return _privateLobby;
  }

  Future<PrivateLobby?> matchmakePublicLobby() async {
    _isLoading = true;
    _error = null;
    _joinPrivateLobby = null;
    _privateLobby = [];
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated');
      }

      final userId = _auth.currentUser?.id ?? '';
      final username = await getCurrentUsername();

      final row = await _api.postJson(
        '/public_lobbies/match',
        accessToken: token,
        body: {
          'username': username,
          'user_id': userId,
        },
      );
      _joinPrivateLobby = PrivateLobby.fromJson(row);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _joinPrivateLobby;
  }

  Future<bool> leavePublicLobby() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated');
      }

      await _api.deleteJson(
        '/public_lobbies/leave',
        accessToken: token,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _privateLobby = [];
      _createPrivateLobby = null;
      _joinPrivateLobby = null;
      unsubscribeFromLobby();
      notifyListeners();
    }
    return true;
  }


  Future<PrivateLobby?> createLobby(String userId, String name) async {
    _isLoading = true;
    _error = null;
    _createPrivateLobby = null;
    _privateLobby = [];
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated');
      }

      final row = await _api.postJson(
        '/private_lobbies/create',
        accessToken: token,
        body: {
          "username": name,
          "user_id": userId,
        },
      );
      _createPrivateLobby = PrivateLobby.fromJson(row);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _createPrivateLobby;
  }

  Future<PrivateLobby?> joinLobby(String userId, int lobbyId, String name) async {
    _isLoading = true;
    _error = null;
    _joinPrivateLobby = null;
    _privateLobby = [];
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated');
      }

      final row = await _api.postJson(
        '/private_lobbies/join',
        accessToken: token,
        body: {
          "username": name,
          "lobby_id": lobbyId,
          "user_id": userId,
          // TODO need to remove userID. Its already passed this is redundant and unsafe, but it works rn so im not touching it
        },
      );
      _joinPrivateLobby = PrivateLobby.fromJson(row);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return _joinPrivateLobby;
  }

  Future<bool> leaveLobby() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated');
      }

      await _api.deleteJson(
        '/private_lobbies/leave',
        accessToken: token,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _privateLobby = [];
      _createPrivateLobby = null;
      _joinPrivateLobby = null;
      unsubscribeFromLobby();
      notifyListeners();
    }
    return true;
  }


  Future<void> loadMyLobby() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated');
      }

      final list = await _api.getList(
        '/private_lobbies/me',
        accessToken: token,
      );

      _privateLobby = list
          .cast<Map<String, dynamic>>()
          .map(PrivateLobby.fromJson)
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deletePrivateLobbyRow(String rowId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null || token.isEmpty) {
        throw StateError('Not authenticated');
      }

      final res = await _api.deleteJson(
        '/private_lobbies/$rowId',
        accessToken: token,
      );

      final deleted = res['deleted'] == true;
      if (deleted) {
        _privateLobby = _privateLobby.where((e) => e.id != rowId).toList();
      }
      return deleted;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> subscribeToLobby(String lobbyId) async {
    if (lobbyId.isEmpty) return;

    unsubscribeFromLobby();
    _subscribedLobbyId = 'private:$lobbyId';

    final channelName = 'private_lobby_$lobbyId';
    _lobbyChannel = _auth.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'private_lobbies',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'lobby_id',
            value: lobbyId,
          ),
          callback: (_) async {
            if (_isRealtimeSyncing) return;
            _isRealtimeSyncing = true;
            try {
              await getLobby(lobbyId, showLoading: false);
            } finally {
              _isRealtimeSyncing = false;
            }
          },
        )
        .subscribe();
  }

  Future<void> subscribeToPublicLobby(String lobbyId) async {
    if (lobbyId.isEmpty) return;

    unsubscribeFromLobby();
    _subscribedLobbyId = 'public:$lobbyId';

    final channelName = 'public_lobby_$lobbyId';
    _lobbyChannel = _auth.client
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'public_lobbies',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'lobby_id',
            value: lobbyId,
          ),
          callback: (_) async {
            if (_isRealtimeSyncing) return;
            _isRealtimeSyncing = true;
            try {
              await getPublicLobby(lobbyId, showLoading: false);
            } finally {
              _isRealtimeSyncing = false;
            }
          },
        )
        .subscribe();
  }

  void unsubscribeFromLobby() {
    if (_lobbyChannel != null) {
      _auth.client.removeChannel(_lobbyChannel!);
    }
    _lobbyChannel = null;
    _subscribedLobbyId = null;
    _isRealtimeSyncing = false;
  }

  /// LiveKit WebRTC (audio). [lobbyKind] is `private` or `public` (must match DB membership).
  Future<Map<String, dynamic>> getLiveKitToken({
    required String lobbyId,
    required String lobbyKind,
  }) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Not authenticated');
    }
    return _api.postJson(
      '/voice/livekit/token',
      accessToken: token,
      body: {
        'lobby_id': lobbyId,
        'lobby_kind': lobbyKind,
      },
    );
  }

  Future<Map<String, dynamic>> getLobbyTurnState({
    required int lobbyId,
    required String lobbyKind,
  }) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Not authenticated');
    }
    final base = lobbyKind == 'public' ? '/public_lobbies' : '/private_lobbies';
    return _api.getJson(
      '$base/$lobbyId/turn_state',
      accessToken: token,
    );
  }

  Future<Map<String, dynamic>> submitLobbyTurnScore({
    required int lobbyId,
    required String lobbyKind,
    required double score,
  }) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Not authenticated');
    }
    final base = lobbyKind == 'public' ? '/public_lobbies' : '/private_lobbies';
    return _api.postJson(
      '$base/$lobbyId/turn_state/score',
      accessToken: token,
      body: {
        'score': score,
      },
    );
  }

  Future<Map<String, dynamic>> voteLobbyNextRound({
    required int lobbyId,
    required String lobbyKind,
  }) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) {
      throw StateError('Not authenticated');
    }
    final base = lobbyKind == 'public' ? '/public_lobbies' : '/private_lobbies';
    return _api.postJson(
      '$base/$lobbyId/turn_state/vote_next_round',
      accessToken: token,
      body: const <String, dynamic>{},
    );
  }

  /// Generate 20 session items from the AI service for the given topic.
  ///
  /// Stores the result in [sessionItems]. Throws on network or API failure.
  Future<void> generateSessionItems(String topic) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) throw StateError('Not authenticated');

    final response = await _api.postJson(
      '/ai/generate-session-items',
      accessToken: token,
      body: {'topic': topic},
    );

    final rawItems = response['items'] as List<dynamic>? ?? [];
    _sessionItems = rawItems
        .cast<Map<String, dynamic>>()
        .map(LessonItem.fromSessionJson)
        .toList();
  }

  /// Persist [sessionItems] to the lobby so all members can fetch them.
  ///
  /// Called once by the host immediately after [generateSessionItems].
  Future<void> setLobbyItems({
    required String lobbyKind,
    required String lobbyId,
  }) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) throw StateError('Not authenticated');

    final base = lobbyKind == 'public' ? '/public_lobbies' : '/private_lobbies';
    await _api.postList(
      '$base/$lobbyId/items',
      accessToken: token,
      body: {
        'items': _sessionItems
            .map((item) => {
                  'position': item.position,
                  'text': item.text,
                  'ipa': item.ipa,
                  'hint': item.hint,
                })
            .toList(),
      },
    );
  }

  /// Fetch session items from the lobby (used by joiners).
  ///
  /// Stores the result in [sessionItems]. Throws on network or API failure.
  Future<void> fetchLobbyItems({
    required String lobbyKind,
    required String lobbyId,
  }) async {
    final token = _auth.accessToken;
    if (token == null || token.isEmpty) throw StateError('Not authenticated');

    final base = lobbyKind == 'public' ? '/public_lobbies' : '/private_lobbies';
    final list = await _api.getList(
      '$base/$lobbyId/items',
      accessToken: token,
    );

    _sessionItems = list
        .cast<Map<String, dynamic>>()
        .map(LessonItem.fromSessionJson)
        .toList();
  }

  @override
  void dispose() {
    unsubscribeFromLobby();
    super.dispose();
  }

}