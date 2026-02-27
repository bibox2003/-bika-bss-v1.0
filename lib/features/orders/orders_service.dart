import 'dart:convert';
import '../../services/api_client.dart';
import 'orders_models.dart';

class OrdersService {
  final ApiClient _apiClient;
  OrdersService(this._apiClient);

  String _cleanErrorBody(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html')) {
      return 'Endpoint not found or wrong route.';
    }
    return body;
  }

  Future<List<OrderListItem>> listOrders() async {
    final endpoints = [
      '/api/v1/orders/',
      '/api/orders/',
      '/api/v1/order/',
      '/api/order/',
    ];

    String? lastError;

    for (final path in endpoints) {
      try {
        final res = await _apiClient.get(path);

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);

          if (decoded is List) {
            return decoded
                .map((e) => OrderListItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }

          if (decoded is Map<String, dynamic> && decoded['results'] is List) {
            return (decoded['results'] as List)
                .map((e) => OrderListItem.fromJson(e as Map<String, dynamic>))
                .toList();
          }

          lastError = 'Unexpected orders response format on $path';
          continue;
        }

        lastError =
            'Failed to load orders (${res.statusCode}): ${_cleanErrorBody(res.body)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'Failed to load orders');
  }

  Future<OrderDetail> getOrder(int id) async {
    final endpoints = [
      '/api/v1/orders/$id/',
      '/api/orders/$id/',
      '/api/v1/order/$id/',
      '/api/order/$id/',
    ];

    String? lastError;

    for (final path in endpoints) {
      try {
        final res = await _apiClient.get(path);

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            return OrderDetail.fromJson(decoded);
          }
          lastError = 'Unexpected order detail format on $path';
          continue;
        }

        lastError =
            'Failed to load order #$id (${res.statusCode}): ${_cleanErrorBody(res.body)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'Failed to load order #$id');
  }
}
