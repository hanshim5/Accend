// lib/src/features/courses/controllers/courses_controller.dart

import 'package:flutter/foundation.dart';
import '../../../common/services/api_client.dart';
import '../../../common/services/auth_service.dart';
import '../models/course.dart';
import '../models/lesson.dart';

class GeneratedCourseResult {
  GeneratedCourseResult({
    required this.course,
    required this.lessons,
  });

  final Course course;
  final List<Lesson> lessons;
}

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

  bool _isGenerating = false;
  String? _generateError;

  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Course> get courses => List.unmodifiable(_courses);

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

  /// Generate a course through the Gateway and return the created course
  /// plus persisted lessons so the UI can transition into a success state
  /// and immediately offer "Start Course".
  Future<GeneratedCourseResult?> generateCourse(String prompt) async {
    _isGenerating = true;
    _generateError = null;
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null) {
        throw Exception("User not authenticated");
      }

      final res = await _api.postJson(
        "/ai/generate-course",
        accessToken: token,
        body: {"prompt": prompt},
      );

      final rawCourse = res['course'];
      if (rawCourse is! Map<String, dynamic>) {
        throw Exception('Invalid generate-course response: missing course');
      }

      final rawLessons = res['lessons'] as List<dynamic>? ?? const [];

      final createdCourse = Course.fromJson(rawCourse);
      final createdLessons = rawLessons
          .cast<Map<String, dynamic>>()
          .map((e) => Lesson.fromJson(e))
          .toList();

      // Refresh course list so the new card appears in the grid too.
      await loadCourses();

      return GeneratedCourseResult(
        course: createdCourse,
        lessons: createdLessons,
      );
    } catch (e) {
      _generateError = e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<List<Lesson>> fetchLessons(String courseId) async {
    final token = _auth.accessToken;
    if (token == null) {
      throw Exception('User not authenticated');
    }

    final list = await _api.getList(
      '/courses/$courseId/lessons',
      accessToken: token,
    );

    return list
        .cast<Map<String, dynamic>>()
        .map((e) => Lesson.fromJson(e))
        .toList();
  }

  /// Mark a lesson as complete on the server.
  ///
  /// Best-effort: errors are swallowed so the caller's UI flow is never blocked.
  /// The server endpoint is idempotent — calling it on an already-completed
  /// lesson is safe.
  Future<void> completeLesson(String courseId, String lessonId) async {
    final token = _auth.accessToken;
    if (token == null) return;

    try {
      await _api.postJson(
        '/courses/$courseId/lessons/$lessonId/complete',
        accessToken: token,
      );
    } catch (_) {
      // Silently swallow — completion is best-effort and must not disrupt UX.
    }
  }
}