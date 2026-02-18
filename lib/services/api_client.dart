import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'auth_service.dart';

class ApiClient {
  final AuthService _authService;
  final String _baseUrl = AppConfig.baseUrl;

  ApiClient(this._authService);

  Uri _uri(String endpoint) {
    final normalized = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$_baseUrl$normalized');
  }

  Future<Map<String, String>> _headers() async {
    final access = await _authService.getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      if (access != null && access.isNotEmpty)
        'Authorization': 'Bearer $access',
    };
  }

  Future<http.Response> get(String endpoint) async {
    return _sendWithRefreshRetry(
      method: 'GET',
      endpoint: endpoint,
    );
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _sendWithRefreshRetry(
      method: 'POST',
      endpoint: endpoint,
      body: body,
    );
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _sendWithRefreshRetry(
      method: 'PATCH',
      endpoint: endpoint,
      body: body,
    );
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    return _sendWithRefreshRetry(
      method: 'PUT',
      endpoint: endpoint,
      body: body,
    );
  }

  Future<http.Response> delete(String endpoint) async {
    return _sendWithRefreshRetry(
      method: 'DELETE',
      endpoint: endpoint,
    );
  }

  Future<http.Response> _sendWithRefreshRetry({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    // First attempt
    var response = await _rawRequest(
      method: method,
      endpoint: endpoint,
      body: body,
    );

    // Retry once if unauthorized
    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshAccessToken(); // bool
      if (refreshed) {
        response = await _rawRequest(
          method: method,
          endpoint: endpoint,
          body: body,
        );
      }
    }

    return response;
  }

  Future<http.Response> _rawRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(endpoint);
    final headers = await _headers();

    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);

      case 'POST':
        return http.post(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );

      case 'PATCH':
        return http.patch(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );

      case 'PUT':
        return http.put(
          uri,
          headers: headers,
          body: body == null ? null : jsonEncode(body),
        );

      case 'DELETE':
        return http.delete(uri, headers: headers);

      default:
        throw Exception('Unsupported method: $method');
    }
  }
}
