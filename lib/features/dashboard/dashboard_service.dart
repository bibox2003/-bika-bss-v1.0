import 'dart:convert';
import '../../services/api_client.dart';
import 'dashboard_models.dart';

class DashboardService {
  final ApiClient _apiClient;
  DashboardService(this._apiClient);

  String _cleanErrorBody(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html')) {
      return 'Endpoint not found or wrong route.';
    }
    return body;
  }

  Future<DashboardSummary> fetchSummary() async {
    final endpoints = [
      '/api/v1/dashboard/summary/',
      '/api/dashboard/summary/',
      '/api/v1/dashboard/',
      '/api/dashboard/',
      '/dashboard/summary/',
    ];

    String? lastError;

    for (final path in endpoints) {
      try {
        final res = await _apiClient.get(path);

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            return DashboardSummary.fromJson(decoded);
          }
          lastError = 'Unexpected dashboard response format on $path';
          continue;
        }

        lastError =
            'Failed to load dashboard summary (${res.statusCode}): ${_cleanErrorBody(res.body)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'Failed to load dashboard summary');
  }
}
