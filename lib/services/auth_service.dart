import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AuthService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _baseUrl = AppConfig.baseUrl;

  // Secure storage keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';

  // ---------------------------------------------------------------------------
  // Token storage helpers
  // ---------------------------------------------------------------------------
  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: accessTokenKey, value: access);
    await _storage.write(key: refreshTokenKey, value: refresh);
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
  }

  // ---------------------------------------------------------------------------
  // Native login (optional, still useful for fallback)
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/token/');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final access = data['access']?.toString();
      final refresh = data['refresh']?.toString();

      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        throw Exception('Invalid token response from server.');
      }

      await saveTokens(access: access, refresh: refresh);
      return data;
    } else if (response.statusCode == 401) {
      throw Exception('Invalid username or password.');
    } else {
      throw Exception(
        'Login failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Refresh access token
  // ---------------------------------------------------------------------------
  Future<bool> refreshAccessToken() async {
    final refresh = await getRefreshToken();
    if (refresh == null || refresh.isEmpty) return false;

    final uri = Uri.parse('$_baseUrl/api/token/refresh/');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh': refresh}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final newAccess = data['access']?.toString();

      if (newAccess != null && newAccess.isNotEmpty) {
        await _storage.write(key: accessTokenKey, value: newAccess);
        return true;
      }
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // Generic authorized GET helper (retries once after refresh on 401)
  // ---------------------------------------------------------------------------
  Future<http.Response> authorizedGet(String endpoint) async {
    String? access = await getAccessToken();
    if (access == null || access.isEmpty) {
      throw Exception('No access token found. Please login.');
    }

    final uri = Uri.parse('$_baseUrl$endpoint');

    http.Response response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $access',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (!refreshed) {
        throw Exception('Session expired. Please login again.');
      }

      access = await getAccessToken();
      response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $access',
          'Content-Type': 'application/json',
        },
      );
    }

    return response;
  }

  // ---------------------------------------------------------------------------
  // Profile endpoint
  // ---------------------------------------------------------------------------
  Future<Map<String, dynamic>> getMe() async {
    final response = await authorizedGet('/api/v1/me/');

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception(
      'Failed to fetch profile (${response.statusCode}): ${response.body}',
    );
  }

  // ---------------------------------------------------------------------------
  // Session state
  // ---------------------------------------------------------------------------
  Future<bool> isLoggedIn() async {
    final access = await getAccessToken();
    if (access == null || access.isEmpty) return false;

    // Optional stronger check: ping /me endpoint
    try {
      final res = await authorizedGet('/api/v1/me/');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await clearTokens();
  }
}
