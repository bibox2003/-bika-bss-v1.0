import 'dart:convert';
import '../../services/api_client.dart';
import 'cart_item_model.dart';

class CartService {
  final ApiClient _apiClient;

  CartService(this._apiClient);

  Future<List<CartItem>> fetchCartItems() async {
    final response = await _apiClient.get('/api/v1/cart/');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      // If DRF pagination enabled
      if (decoded is Map<String, dynamic> && decoded['results'] is List) {
        return (decoded['results'] as List)
            .map((e) => CartItem.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    }

    throw Exception(
      'Failed to load cart (${response.statusCode}): ${response.body}',
    );
  }

  Future<CartItem> updateQuantity({
    required int itemId,
    required int quantity,
  }) async {
    final response = await _apiClient.patch(
      '/api/v1/cart/$itemId/',
      body: {'quantity': quantity},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return CartItem.fromJson(decoded);
    }

    throw Exception(
      'Failed to update quantity (${response.statusCode}): ${response.body}',
    );
  }

  Future<void> removeItem(int itemId) async {
    final response = await _apiClient.delete('/api/v1/cart/$itemId/remove/');

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to remove item (${response.statusCode}): ${response.body}',
      );
    }
  }
}
