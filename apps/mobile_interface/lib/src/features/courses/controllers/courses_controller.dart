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

  // NEW: generate state (handy for disabling buttons / showing spinner)
  bool _isGenerating = false;
  String? _generateError;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Course> get courses => List.unmodifiable(_courses);

  // NEW
  bool get isGenerating => _isGenerating;
  String? get generateError => _generateError;

  Future<void> loadCourses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = _auth.accessToken;
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

  /// NEW: Create a course via AI through the Gateway, then refresh the list.
  /// Returns true on success (so the popup can close).
  Future<bool> generateCourse(String prompt) async {
    _isGenerating = true;
    _generateError = null;
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null) {
        throw Exception("User not authenticated");
      }

      await _api.postJson(
        "/ai/generate-course",
        accessToken: token,
        body: {"prompt": prompt},
      );

      // Refresh so new card appears
      await loadCourses();
      return true;
    } catch (e) {
      _generateError = e.toString();
      return false;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }
}