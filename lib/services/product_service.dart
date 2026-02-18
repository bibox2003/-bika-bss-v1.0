import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/product.dart';
import 'auth_service.dart';

class ProductService {
  final AuthService _authService = AuthService();
  final String _baseUrl = AppConfig.baseUrl;

  Future<List<Product>> fetchProducts() async {
    final response = await _authService.authorizedGet('/api/v1/products/');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is List) {
        return decoded.map((e) => Product.fromJson(e)).toList();
      }
      if (decoded is Map<String, dynamic> && decoded['results'] is List) {
        return (decoded['results'] as List)
            .map((e) => Product.fromJson(e))
            .toList();
      }
      throw Exception('Unexpected response format for products.');
    }

    throw Exception(
      'Failed to load products (${response.statusCode}): ${response.body}',
    );
  }

  Future<Product> fetchProductDetail(int id) async {
    final response = await _authService.authorizedGet('/api/v1/products/$id/');

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    }
    if (response.statusCode == 404) {
      throw Exception('Product not found.');
    }

    throw Exception(
      'Failed to load product detail (${response.statusCode}): ${response.body}',
    );
  }

  Future<void> addToCart({required int productId, int quantity = 1}) async {
    String? token = await _authService.getAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('No access token found.');
    }

    final uri = Uri.parse('$_baseUrl/api/v1/cart/add/');
    http.Response response = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'product_id': productId, 'quantity': quantity}),
    );

    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshAccessToken();
      if (!refreshed) {
        throw Exception('Session expired. Please login again.');
      }

      token = await _authService.getAccessToken();
      response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'product_id': productId, 'quantity': quantity}),
      );
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Add to cart failed (${response.statusCode}): ${response.body}',
      );
    }
  }
}
