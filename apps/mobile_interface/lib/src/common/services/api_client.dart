import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Minimal gateway HTTP client.
/// Uses .env GATEWAY_URL if provided, otherwise picks a sensible default
/// per-platform:
///   - web: Uri.base.origin
///   - android: http://10.0.2.2:8080
///   - other: http://localhost:8080
class ApiClient {
  ApiClient({
    String? baseUrl,
    http.Client? client,
  })  : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _determineBaseUrl();

  final http.Client _client;
  final String baseUrl;

  static String _determineBaseUrl() {
    // 1) prefer explicit env var if present
    final envUrl = dotenv.env['GATEWAY_URL'];
    if (envUrl != null && envUrl.isNotEmpty) return envUrl;

    // 2) web: use the page origin (works in dev + deployed sites)
    if (kIsWeb) {
      // Uri.base.origin works for web and will be something like "http://localhost:xxxx"
      final origin = Uri.base.origin;
      if (origin.isNotEmpty) return origin;
    }

    // 3) android emulator default mapping to host machine
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }

    // 4) iOS simulator / desktop / fallback
    return 'http://localhost:8080';
  }

  Uri _uri(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$p').replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri(path, query),
      headers: _headers(accessToken: accessToken),
    );

    return _handleJson(res);
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Object? body,
    String? accessToken,
  }) async {
    final res = await _client.post(
      _uri(path),
      headers: _headers(accessToken: accessToken, contentJson: true),
      body: body == null ? null : jsonEncode(body),
    );

    return _handleJson(res);
  }

  Future<Map<String, dynamic>> patchJson(
    String path, {
    Object? body,
    String? accessToken,
  }) async {
    final res = await _client.patch(
      _uri(path),
      headers: _headers(accessToken: accessToken, contentJson: true),
      body: body == null ? null : jsonEncode(body),
    );

    return _handleJson(res);
  }

  Future<Map<String, dynamic>> deleteJson(
    String path, {
    Map<String, String>? query,
    String? accessToken,
  }) async {
    final res = await _client.delete(
      _uri(path, query),
      headers: _headers(accessToken: accessToken),
    );

    return _handleJson(res);
  }

  /// DELETE that expects no response body (204 No Content).
  Future<void> deleteVoid(
    String path, {
    Map<String, String>? query,
    String? accessToken,
  }) async {
    final res = await _client.delete(
      _uri(path, query),
      headers: _headers(accessToken: accessToken),
    );

    if (res.statusCode >= 400) {
      throw ApiException(statusCode: res.statusCode, body: res.body);
    }
  }

  Map<String, String> _headers({
    String? accessToken,
    bool contentJson = false,
  }) {
    final h = <String, String>{};
    if (contentJson) h['Content-Type'] = 'application/json';
    if (accessToken != null && accessToken.isNotEmpty) {
      h['Authorization'] = 'Bearer $accessToken';
    }
    return h;
  }

  Map<String, dynamic> _handleJson(http.Response res) {
    if (res.statusCode >= 400) {
      throw ApiException(
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    if (res.body.isEmpty) {
      throw ApiException(statusCode: 502, body: 'Empty response body');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;

    throw ApiException(
      statusCode: 502,
      body: 'Expected JSON object but got: ${res.body}',
    );
  }

  Future<List<dynamic>> postList(
    String path, {
    Object? body,
    String? accessToken,
  }) async {
    final res = await _client.post(
      _uri(path),
      headers: _headers(accessToken: accessToken, contentJson: true),
      body: body == null ? null : jsonEncode(body),
    );

    if (res.statusCode >= 400) {
      throw ApiException(statusCode: res.statusCode, body: res.body);
    }

    if (res.body.isEmpty) {
      throw ApiException(statusCode: 502, body: 'Empty response body');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;

    throw ApiException(
      statusCode: 502,
      body: 'Expected JSON list but got: ${res.body}',
    );
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, String>? query,
    String? accessToken,
  }) async {
    final res = await _client.get(
      _uri(path, query),
      headers: _headers(accessToken: accessToken),
    );

    if (res.statusCode >= 400) {
      throw ApiException(
        statusCode: res.statusCode,
        body: res.body,
      );
    }

    if (res.body.isEmpty) {
      throw ApiException(statusCode: 502, body: 'Empty response body');
    }

    final decoded = jsonDecode(res.body);
    if (decoded is List) return decoded;

    throw ApiException(
      statusCode: 502,
      body: 'Expected JSON list but got: ${res.body}',
    );
  }

  void dispose() => _client.close();
}

class ApiException implements Exception {
  ApiException({required this.statusCode, required this.body});

  final int statusCode;
  final String body;

  /// Extract the innermost "detail" string from the response body, handling
  /// both single-encoded and double-encoded JSON from the gateway.
  String get detail {
    try {
      var decoded = jsonDecode(body);
      // Unwrap up to two levels of {"detail": ...} nesting.
      for (var i = 0; i < 2; i++) {
        if (decoded is Map<String, dynamic> && decoded.containsKey('detail')) {
          final d = decoded['detail'];
          if (d is String) {
            try {
              decoded = jsonDecode(d);
            } catch (_) {
              return d;
            }
          } else {
            decoded = d;
          }
        } else {
          break;
        }
      }
      if (decoded is String) return decoded;
      if (decoded is Map<String, dynamic>) return decoded.toString();
    } catch (_) {}
    return body;
  }

  @override
  String toString() => 'ApiException($statusCode): $body';
}