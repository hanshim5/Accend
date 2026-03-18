import 'package:flutter/foundation.dart';

import 'package:mobile_interface/src/common/services/api_client.dart';
import 'package:mobile_interface/src/common/services/auth_service.dart';
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


  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PrivateLobby> get privateLobby => List.unmodifiable(_privateLobby);
  PrivateLobby? get createPrivateLobby => _createPrivateLobby;
  PrivateLobby? get joinPrivateLobby => _joinPrivateLobby;

  void resetPrivateLobbyState({bool notify = true}) {
    _error = null;
    _privateLobby = [];
    _createPrivateLobby = null;
    _joinPrivateLobby = null;
    if (notify) notifyListeners();
  }



  Future<List<PrivateLobby>> getLobby(String lobbyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

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
      _isLoading = false;
      notifyListeners();
    }
    return _privateLobby;

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
    // Placeholder: realtime subscription can be added later.
  }

  void unsubscribeFromLobby() {
    // Placeholder: realtime unsubscription can be added later.
  }

}