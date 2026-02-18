import 'dart:convert';
import '../../services/api_client.dart';
import 'product_model.dart';

class InventoryService {
  final ApiClient _apiClient;

  InventoryService(this._apiClient);

  Future<List<Product>> fetchProducts({required bool mineOnly}) async {
    final endpoint =
        mineOnly ? '/api/v1/products/?mine=1' : '/api/v1/products/';

    final response = await _apiClient.get(endpoint);

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (decoded is Map<String, dynamic> && decoded['results'] is List) {
        final items = decoded['results'] as List;
        return items
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    }

    throw Exception(
      'Failed to load products (${response.statusCode}): ${response.body}',
    );
  }

  Future<Product> fetchProductDetail(int id) async {
    final response = await _apiClient.get('/api/v1/products/$id/');
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return Product.fromJson(decoded);
    }
    throw Exception(
      'Failed to load product detail (${response.statusCode}): ${response.body}',
    );
  }

  /// Adds product to cart via your existing backend endpoint.
  Future<void> addToCart({
    required int productId,
    required int quantity,
  }) async {
    final response = await _apiClient.post(
      '/api/v1/cart/add/',
      body: {
        'product_id': productId,
        'quantity': quantity,
      },
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Add to cart failed (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Quick stock adjustment endpoint (you'll need backend support for this route if not present).
  /// If your backend doesn't have it yet, keep this method for now; we'll wire backend next.
  Future<void> adjustStock({
    required int productId,
    required int delta,
  }) async {
    final response = await _apiClient.patch(
      '/api/v1/products/$productId/stock/',
      body: {'delta': delta},
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Adjust stock failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
