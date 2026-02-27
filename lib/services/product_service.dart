import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/product.dart';
import '../models/product_option.dart';

class ProductService {
  static const _storage = FlutterSecureStorage();
  final String _baseUrl = AppConfig.baseUrl;

  Future<String?> _getToken() async {
    return _storage.read(key: 'access_token');
  }

  Uri _uri(String endpoint) {
    final base = _baseUrl.endsWith('/')
        ? _baseUrl.substring(0, _baseUrl.length - 1)
        : _baseUrl;
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return Uri.parse('$base$path');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  String _cleanErrorBody(http.Response res) {
    final contentType = res.headers['content-type'] ?? '';
    if (contentType.contains('text/html')) {
      return 'Endpoint not found or wrong route.';
    }

    final body = res.body.trimLeft();
    if (body.startsWith('<!DOCTYPE html') || body.startsWith('<html')) {
      return 'Endpoint not found or wrong route.';
    }

    return res.body;
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  // ----------------------------
  // PRODUCTS
  // ----------------------------
  Future<List<Product>> fetchProducts() async {
    final endpoints = [
      '/api/v1/products/', // ✅ your confirmed working endpoint
      '/api/products/',
      '/api/v1/inventory/products/',
      '/api/inventory/products/',
    ];

    String? lastError;

    for (final endpoint in endpoints) {
      try {
        final res = await http.get(_uri(endpoint), headers: await _headers());

        if (res.statusCode != 200) {
          lastError =
              'Failed to load products (${res.statusCode}): ${_cleanErrorBody(res)}';
          continue;
        }

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

        lastError = 'Unexpected product response format on $endpoint';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'Failed to load products.');
  }

  // ----------------------------
  // CATEGORIES (dropdown)
  // ----------------------------
  Future<List<ProductOption>> fetchCategories() async {
    final endpoints = [
      '/api/v1/categories/', // ✅ confirmed working
      '/api/v1/product-categories/',
      '/api/categories/',
      '/api/product-categories/',
      '/api/v1/inventory/categories/',
      '/api/inventory/categories/',
    ];

    for (final endpoint in endpoints) {
      try {
        final res = await http.get(_uri(endpoint), headers: await _headers());
        if (res.statusCode != 200) continue;

        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          return decoded
              .map((e) => ProductOption.fromJson(e as Map<String, dynamic>))
              .toList();
        }

        if (decoded is Map<String, dynamic> && decoded['results'] is List) {
          return (decoded['results'] as List)
              .map((e) => ProductOption.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      } catch (_) {}
    }

    return [];
  }

  // ----------------------------
  // VENDORS (dropdown)
  // ----------------------------
  Future<List<ProductOption>> fetchVendors() async {
    final endpoints = [
      '/api/v1/vendors/', // ✅ confirmed working
      '/api/v1/users/vendors/',
      '/api/vendors/',
      '/api/users/vendors/',
      '/api/v1/inventory/vendors/',
      '/api/inventory/vendors/',
    ];

    for (final endpoint in endpoints) {
      try {
        final res = await http.get(_uri(endpoint), headers: await _headers());
        if (res.statusCode != 200) continue;

        final decoded = jsonDecode(res.body);

        if (decoded is List) {
          return decoded.map((e) {
            final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
            if ((!m.containsKey('name') || '${m['name']}'.trim().isEmpty) &&
                m.containsKey('username')) {
              m['name'] = m['username'];
            }
            return ProductOption.fromJson(m);
          }).toList();
        }

        if (decoded is Map<String, dynamic> && decoded['results'] is List) {
          return (decoded['results'] as List).map((e) {
            final m = Map<String, dynamic>.from(e as Map<String, dynamic>);
            if ((!m.containsKey('name') || '${m['name']}'.trim().isEmpty) &&
                m.containsKey('username')) {
              m['name'] = m['username'];
            }
            return ProductOption.fromJson(m);
          }).toList();
        }
      } catch (_) {}
    }

    return [];
  }

  // ----------------------------
  // CREATE PRODUCT
  // ----------------------------
  Future<Map<String, dynamic>> createProduct({
    required String name,
    required String sku,
    required double price,
    required int stockQuantity,
    required bool active,
    required String description,
    String? slug,
    int? categoryId,
    int? vendorId,
  }) async {
    final endpoints = [
      '/api/v1/products/', // ✅ TRY THIS FIRST (your working endpoint)
      '/api/products/',
      '/api/v1/inventory/products/',
      '/api/inventory/products/',
      // fallback guesses last (not first)
      '/api/v1/products/create/',
      '/api/products/create/',
      '/api/v1/inventory/products/create/',
      '/api/inventory/products/create/',
    ];

    final computedSlug =
        (slug != null && slug.trim().isNotEmpty) ? slug.trim() : _slugify(name);

    // ✅ Use "status" because your backend product uses status='active'/'draft'
    final payload = <String, dynamic>{
      'name': name.trim(),
      'slug': computedSlug,
      'sku': sku.trim(),
      'description': description.trim(),
      'short_description': description.trim(),
      'price': price,
      'stock_quantity': stockQuantity,
      'track_inventory': true,
      'status': active ? 'active' : 'draft',
      'condition': 'new',
    };

    if (categoryId != null) payload['category'] = categoryId;
    if (vendorId != null) payload['vendor'] = vendorId;

    String? lastError;

    for (final endpoint in endpoints) {
      try {
        final res = await http.post(
          _uri(endpoint),
          headers: await _headers(),
          body: jsonEncode(payload),
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) return decoded;
          return {'success': true};
        }

        // Better duplicate SKU message
        if (res.statusCode == 400 ||
            res.statusCode == 409 ||
            res.statusCode == 500) {
          final body = _cleanErrorBody(res).toLowerCase();
          if (body.contains('sku') && body.contains('unique')) {
            throw Exception('SKU already exists. Use a different SKU.');
          }
          if (body.contains('integrityerror')) {
            throw Exception('Duplicate data (likely SKU). Use a unique SKU.');
          }
        }

        // If endpoint exists but POST not allowed, keep trying next
        if (res.statusCode == 405) {
          lastError = 'POST not allowed on $endpoint';
          continue;
        }

        lastError =
            'Create product failed (${res.statusCode}): ${_cleanErrorBody(res)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'Create product failed on all endpoints.');
  }

  // ----------------------------
  // DELETE PRODUCT
  // ----------------------------
  Future<void> deleteProduct(int productId) async {
    final endpoints = [
      '/api/v1/products/$productId/',
      '/api/products/$productId/',
      '/api/v1/inventory/products/$productId/',
      '/api/inventory/products/$productId/',
    ];

    String? lastError;

    for (final endpoint in endpoints) {
      try {
        final res =
            await http.delete(_uri(endpoint), headers: await _headers());

        if (res.statusCode == 200 ||
            res.statusCode == 202 ||
            res.statusCode == 204) {
          return;
        }

        lastError =
            'Delete product failed (${res.statusCode}): ${_cleanErrorBody(res)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'Delete product failed on all endpoints.');
  }

  // ----------------------------
  // UPDATE PRODUCT
  // ----------------------------
  Future<Map<String, dynamic>> updateProduct({
    required int productId,
    required String name,
    required String sku,
    required double price,
    required int stockQuantity,
    required bool active,
    required String description,
    String? slug,
    int? categoryId,
    int? vendorId,
  }) async {
    final endpoints = [
      '/api/v1/products/$productId/',
      '/api/products/$productId/',
      '/api/v1/inventory/products/$productId/',
      '/api/inventory/products/$productId/',
    ];

    final computedSlug =
        (slug != null && slug.trim().isNotEmpty) ? slug.trim() : _slugify(name);

    final payload = <String, dynamic>{
      'name': name.trim(),
      'slug': computedSlug,
      'sku': sku.trim(),
      'description': description.trim(),
      'short_description': description.trim(),
      'price': price,
      'stock_quantity': stockQuantity,
      'track_inventory': true,
      'status': active ? 'active' : 'draft',
      'condition': 'new',
    };

    if (categoryId != null) payload['category'] = categoryId;
    if (vendorId != null) payload['vendor'] = vendorId;

    String? lastError;

    for (final endpoint in endpoints) {
      try {
        // Try PUT first
        var res = await http.put(
          _uri(endpoint),
          headers: await _headers(),
          body: jsonEncode(payload),
        );

        // If PUT is not allowed, try PATCH
        if (res.statusCode == 405) {
          res = await http.patch(
            _uri(endpoint),
            headers: await _headers(),
            body: jsonEncode(payload),
          );
        }

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) return decoded;
          return {'success': true};
        }

        lastError =
            'Update product failed (${res.statusCode}): ${_cleanErrorBody(res)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'Update product failed on all endpoints.');
  }
}
