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

  static const Set<String> validOnboardingLearningGoals = {
    'travel',
    'career',
    'culture',
    'brain_training',
  };

  /// Parses profile `learning_goal` (comma-separated) into ordered known keys.
  static List<String> orderedOnboardingLearningGoals(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim().toLowerCase().replaceAll(' ', '_'))
        .where(
          (s) => s.isNotEmpty && validOnboardingLearningGoals.contains(s),
        )
        .toList();
  }

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

      // Sort: incomplete first, completed last
      _courses.sort((a, b) {
        final aComplete = a.status == "COMPLETE";
        final bComplete = b.status == "COMPLETE";

        if (aComplete == bComplete) return 0;
        if (aComplete) return 1;  // a goes after b
        return -1;                // a goes before b
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generate a course from the user's lowest-accuracy phonemes.
  ///
  /// Calls POST /ai/generate-course-from-metrics — no prompt needed.
  /// The backend reads user_phoneme_metrics and builds a targeted course.
  ///
  /// Returns null and sets [generateError] if generation fails.
  /// A 422 response means the user has no phoneme practice data yet.
  Future<GeneratedCourseResult?> generateCourseFromMetrics() async {
    _isGenerating = true;
    _generateError = null;
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null) throw Exception('User not authenticated');

      final res = await _api.postJson(
        '/ai/generate-course-from-metrics',
        accessToken: token,
      );

      final rawCourse = res['course'];
      if (rawCourse is! Map<String, dynamic>) {
        throw Exception('Invalid generate-course-from-metrics response: missing course');
      }

      final rawLessons = res['lessons'] as List<dynamic>? ?? const [];

      final createdCourse = Course.fromJson(rawCourse);
      final createdLessons = rawLessons
          .cast<Map<String, dynamic>>()
          .map((e) => Lesson.fromJson(e))
          .toList();

      await loadCourses();

      return GeneratedCourseResult(
        course: createdCourse,
        lessons: createdLessons,
      );
    } catch (e) {
      _generateError = e is ApiException ? 'ApiException(${e.statusCode}): ${e.detail}' : e.toString();
      return null;
    } finally {
      _isGenerating = false;
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
      _generateError = e is ApiException ? 'ApiException(${e.statusCode}): ${e.detail}' : e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Creates one onboarding seed course for [learningGoal] (travel, career, culture, brain_training).
  ///
  /// [focusAreasCsv] uses the same comma/semicolon format as profile `focus_areas`.
  /// Refreshes [loadCourses] on success. On failure returns `null` and sets [generateError].
  Future<GeneratedCourseResult?> seedSingleOnboardingCourse({
    required String learningGoal,
    String? focusAreasCsv,
  }) async {
    _isGenerating = true;
    _generateError = null;
    notifyListeners();

    try {
      final token = _auth.accessToken;
      if (token == null) throw Exception('User not authenticated');

      final g = learningGoal.trim().toLowerCase();
      if (!validOnboardingLearningGoals.contains(g)) {
        throw Exception('Invalid learning goal for seeding: $learningGoal');
      }

      final focusAreas = _parseFocusAreasCsv(focusAreasCsv);

      final res = await _api.postJson(
        '/ai/seed-onboarding-course',
        accessToken: token,
        body: {
          'learning_goal': g,
          'focus_areas': focusAreas,
        },
        timeout: const Duration(seconds: 90),
      );

      final rawCourse = res['course'];
      if (rawCourse is! Map<String, dynamic>) {
        throw Exception('Invalid seed-onboarding-course response: missing course');
      }

      final rawLessons = res['lessons'] as List<dynamic>? ?? const [];

      final createdCourse = Course.fromJson(rawCourse);
      final createdLessons = rawLessons
          .cast<Map<String, dynamic>>()
          .map((e) => Lesson.fromJson(e))
          .toList();

      await loadCourses();

      return GeneratedCourseResult(
        course: createdCourse,
        lessons: createdLessons,
      );
    } catch (e) {
      _generateError =
          e is ApiException ? 'ApiException(${e.statusCode}): ${e.detail}' : e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  List<String> _parseFocusAreasCsv(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(RegExp(r'[,;]'))
        .map((s) => s.trim().toLowerCase().replaceAll(' ', '_'))
        .where((s) => s.isNotEmpty)
        .toList();
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

  /// Delete a course owned by the authenticated user.
  ///
  /// Optimistically removes the course from the local list before the server
  /// call so the UI updates immediately. If the server call fails, the course
  /// is restored and the error is rethrown for the caller to surface.
  Future<void> deleteCourse(String courseId) async {
    final token = _auth.accessToken;
    if (token == null) throw Exception('User not authenticated');

    final removed = _courses.firstWhere(
      (c) => c.id == courseId,
      orElse: () => throw Exception('Course not found locally'),
    );
    _courses.removeWhere((c) => c.id == courseId);
    notifyListeners();

    try {
      await _api.deleteVoid('/courses/$courseId', accessToken: token);
    } catch (e) {
      _courses.add(removed);
      notifyListeners();
      rethrow;
    }
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