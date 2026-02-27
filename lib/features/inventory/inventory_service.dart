import 'dart:convert';
import '../../services/api_client.dart';
import 'product_model.dart';

class InventoryService {
  final ApiClient _api;
  InventoryService(this._api);

  Future<List<Product>> fetchProducts({bool mineOnly = false}) async {
    final q = mineOnly ? '?mine=1' : '';
    final res = await _api.get('/api/v1/products/$q');

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);

      if (decoded is List) {
        return decoded
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      if (decoded is Map<String, dynamic> && decoded['results'] is List) {
        return (decoded['results'] as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      }

      return [];
    }

    throw Exception('Fetch products failed (${res.statusCode}): ${res.body}');
  }

  Future<Product> fetchProductDetail(int id) async {
    final res = await _api.get('/api/v1/products/$id/');

    if (res.statusCode == 200) {
      return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }

    throw Exception(
      'Fetch product detail failed (${res.statusCode}): ${res.body}',
    );
  }

  Future<Product> createProduct({
    required String name,
    required String sku,
    required String price,
    required int stockQuantity,
    required String status,
  }) async {
    final res = await _api.post(
      '/api/v1/products/create/',
      body: {
        'name': name,
        'sku': sku,
        'price': price,
        'stock_quantity': stockQuantity,
        'status': status,
      },
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }

    throw Exception('Create product failed (${res.statusCode}): ${res.body}');
  }

  Future<Product> updateProduct({
    required int id,
    required String name,
    required String sku,
    required String price,
    required int stockQuantity,
    required String status,
  }) async {
    final res = await _api.patch(
      '/api/v1/products/$id/update/',
      body: {
        'name': name,
        'sku': sku,
        'price': price,
        'stock_quantity': stockQuantity,
        'status': status,
      },
    );

    if (res.statusCode == 200) {
      return Product.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }

    throw Exception('Update product failed (${res.statusCode}): ${res.body}');
  }

  Future<void> deleteProduct(int id) async {
    final res = await _api.delete('/api/v1/products/$id/delete/');

    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Delete product failed (${res.statusCode}): ${res.body}');
    }
  }

  Future<void> adjustStock({
    required int productId,
    required int delta,
  }) async {
    final res = await _api.patch(
      '/api/v1/products/$productId/stock/',
      body: {'delta': delta},
    );

    if (res.statusCode != 200) {
      throw Exception('Adjust stock failed (${res.statusCode}): ${res.body}');
    }
  }
}
