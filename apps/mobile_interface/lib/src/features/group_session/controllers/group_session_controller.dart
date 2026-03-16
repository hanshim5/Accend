import 'package:flutter/foundation.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/private_lobby.dart';

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

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<PrivateLobby> get privateLobby => List.unmodifiable(_privateLobby);

  Future<void> loadLobby() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final list = await client
          .from('private_lobbies')
          .select('id,lobby_id,username,user_id,host,session_start,joined_at')
          .eq('username', 'test5')
          .limit(10);

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
  }

}