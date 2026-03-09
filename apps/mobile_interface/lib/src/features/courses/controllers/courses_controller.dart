import 'package:flutter/foundation.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/auth_service.dart';
import '../models/course.dart';

class CoursesController extends ChangeNotifier {
  CoursesController({
    required ApiClient api,
    required AuthService auth,
  })  : _api = api,
        _auth = auth;

  final ApiClient _api;
  final AuthService _auth;

  bool _isLoading = false;
  String? _error;
  List<Course> _courses = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Course> get courses => List.unmodifiable(_courses);

  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _auth.accessToken; //?? "eyJhbGciOiJFUzI1NiIsImtpZCI6IjgwNGFhYTMwLTMwMGItNGI0OC04ZTU5LWJhOThmZGU4MTcxYSIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2llbHN4Y2lha2JraGVramJkc2t0LnN1cGFiYXNlLmNvL2F1dGgvdjEiLCJzdWIiOiI3YTliYzBiNS00ZTEyLTQ1OTUtODM3MC04YTNiYTY3NmE2MmIiLCJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzcyODYyMjgxLCJpYXQiOjE3NzI4NTg2ODEsImVtYWlsIjoic2lnbmVzZXNAYnJvc2tpLmNvbSIsInBob25lIjoiIiwiYXBwX21ldGFkYXRhIjp7InByb3ZpZGVyIjoiZW1haWwiLCJwcm92aWRlcnMiOlsiZW1haWwiXX0sInVzZXJfbWV0YWRhdGEiOnsiZW1haWwiOiJzaWduZXNlc0Bicm9za2kuY29tIiwiZW1haWxfdmVyaWZpZWQiOnRydWUsInBob25lX3ZlcmlmaWVkIjpmYWxzZSwic3ViIjoiN2E5YmMwYjUtNGUxMi00NTk1LTgzNzAtOGEzYmE2NzZhNjJiIn0sInJvbGUiOiJhdXRoZW50aWNhdGVkIiwiYWFsIjoiYWFsMSIsImFtciI6W3sibWV0aG9kIjoicGFzc3dvcmQiLCJ0aW1lc3RhbXAiOjE3NzI4NTg2ODF9XSwic2Vzc2lvbl9pZCI6IjkwODIxZjM4LTk5ZWEtNDNiMS1hODAwLTI1ZThjODAyZWQ1YSIsImlzX2Fub255bW91cyI6ZmFsc2V9.q5gq718O-BZKApCaOtQjvpdAc5_MIByV4yXR7rb8uE04CMCHMkXD-1Z4S6H5dGju_FpnNwOu8-fVWEaNybZ4bg";
      if (token == null) {
        throw Exception("User not authenticated");
      }

      final list = await _api.getList(
        "/courses",
        accessToken: token,
      );

      _courses = list
          .cast<Map<String, dynamic>>()
          .map((e) => Course.fromJson(e))
          .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}