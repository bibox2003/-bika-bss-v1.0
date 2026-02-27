import 'dart:convert';
import '../../services/api_client.dart';
import 'cart_item_model.dart';

class CartService {
  final ApiClient _apiClient;

  CartService(this._apiClient);

  String _cleanErrorBody(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html')) {
      return 'Endpoint not found or wrong route.';
    }
    return body;
  }

  Future<dynamic> _getFromCandidates(List<String> paths) async {
    String? lastError;

    for (final path in paths) {
      try {
        final response = await _apiClient.get(path);
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
        lastError =
            'GET $path failed (${response.statusCode}): ${_cleanErrorBody(response.body)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'GET failed on all cart endpoints');
  }

  Future<dynamic> _postToCandidates(
    List<String> paths, {
    required Map<String, dynamic> body,
  }) async {
    String? lastError;

    for (final path in paths) {
      try {
        final response = await _apiClient.post(path, body: body);
        if (response.statusCode == 200 || response.statusCode == 201) {
          return jsonDecode(response.body);
        }
        lastError =
            'POST $path failed (${response.statusCode}): ${_cleanErrorBody(response.body)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'POST failed on all cart endpoints');
  }

  Future<dynamic> _patchToCandidates(
    List<String> paths, {
    required Map<String, dynamic> body,
  }) async {
    String? lastError;

    for (final path in paths) {
      try {
        final response = await _apiClient.patch(path, body: body);
        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        }
        lastError =
            'PATCH $path failed (${response.statusCode}): ${_cleanErrorBody(response.body)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'PATCH failed on all cart endpoints');
  }

  Future<void> _deleteFromCandidates(List<String> paths) async {
    String? lastError;

    for (final path in paths) {
      try {
        final response = await _apiClient.delete(path);
        if (response.statusCode == 200 || response.statusCode == 204) {
          return;
        }
        lastError =
            'DELETE $path failed (${response.statusCode}): ${_cleanErrorBody(response.body)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'DELETE failed on all cart endpoints');
  }

  // ============== FETCH CART ==============

  Future<List<CartItem>> fetchCartItems() async {
    final decoded = await _getFromCandidates([
      '/api/v1/cart/',
      '/api/cart/',
      '/api/v1/cart/items/',
      '/api/cart/items/',
    ]);

    // Case 1: direct list
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => CartItem.fromJson(e))
          .toList();
    }

    // Case 2: paginated list -> {"results": [...]}
    if (decoded is Map<String, dynamic> && decoded['results'] is List) {
      return (decoded['results'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => CartItem.fromJson(e))
          .toList();
    }

    // Case 3: cart object -> {"id":..., "items":[...]}
    if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      return (decoded['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => CartItem.fromJson(e))
          .toList();
    }

    // Case 4: single cart item object (rare)
    if (decoded is Map<String, dynamic>) {
      final hasDirectCartItemShape = decoded.containsKey('product_id') ||
          decoded.containsKey('product') ||
          decoded.containsKey('quantity');

      if (hasDirectCartItemShape) {
        return [CartItem.fromJson(decoded)];
      }
    }

    return [];
  }

  Future<Cart> getCart() async {
    final decoded = await _getFromCandidates([
      '/api/v1/cart/',
      '/api/cart/',
      '/api/v1/cart/items/',
      '/api/cart/items/',
    ]);

    // If backend returns full cart object
    if (decoded is Map<String, dynamic> && decoded['items'] is List) {
      return Cart.fromJson(decoded);
    }

    // Otherwise normalize from list/paginated/single-item
    final items = await fetchCartItems();
    return Cart(id: 0, items: items);
  }

  // ============== ADD TO CART ==============

  Future<Cart> addToCart({
    required int productId,
    required int quantity,
  }) async {
    await _postToCandidates(
      [
        '/api/v1/cart/add/',
        '/api/cart/add/',
        '/api/v1/cart/items/add/',
        '/api/cart/items/add/',
      ],
      body: {
        'product_id': productId,
        'quantity': quantity,
      },
    );

    // backend may return a cart item, but we normalize by reloading cart
    return await getCart();
  }

  // Alias so old UI code `_cart.add(...)` still works
  Future<Cart> add({
    required int productId,
    required int quantity,
  }) {
    return addToCart(productId: productId, quantity: quantity);
  }

  // ============== UPDATE QUANTITY ==============

  Future<CartItem> updateQuantity({
    required int itemId,
    required int quantity,
  }) async {
    final decoded = await _patchToCandidates(
      [
        '/api/v1/cart/$itemId/',
        '/api/cart/$itemId/',
        '/api/v1/cart/items/$itemId/',
        '/api/cart/items/$itemId/',
      ],
      body: {'quantity': quantity},
    );

    return CartItem.fromJson(decoded as Map<String, dynamic>);
  }

  Future<Cart> updateCartQuantity({
    required int productId,
    required int quantity,
  }) async {
    final cart = await getCart();
    final item = cart.getItemByProductId(productId);

    if (item == null) {
      return addToCart(productId: productId, quantity: quantity);
    }

    await updateQuantity(itemId: item.id, quantity: quantity);
    return getCart();
  }

  // ============== REMOVE FROM CART ==============

  Future<void> removeItem(int itemId) async {
    await _deleteFromCandidates([
      '/api/v1/cart/$itemId/remove/',
      '/api/cart/$itemId/remove/',
      '/api/v1/cart/$itemId/',
      '/api/cart/$itemId/',
      '/api/v1/cart/items/$itemId/',
      '/api/cart/items/$itemId/',
    ]);
  }

  Future<Cart> removeFromCart({
    required int productId,
    int? quantity,
  }) async {
    final cart = await getCart();
    final item = cart.getItemByProductId(productId);

    if (item == null) {
      return cart;
    }

    if (quantity == null || quantity >= item.quantity) {
      await removeItem(item.id);
      return getCart();
    }

    final newQty = item.quantity - quantity;
    await updateQuantity(itemId: item.id, quantity: newQty);
    return getCart();
  }

  // ============== CONVENIENCE METHODS ==============

  Future<Cart> decrementQuantity(int productId) async {
    final cart = await getCart();
    final item = cart.getItemByProductId(productId);

    if (item == null) {
      throw Exception('Item not found in cart');
    }

    if (item.quantity <= 1) {
      await removeItem(item.id);
      return getCart();
    }

    await updateQuantity(itemId: item.id, quantity: item.quantity - 1);
    return getCart();
  }

  Future<Cart> incrementQuantity(int productId) async {
    return addToCart(
      productId: productId,
      quantity: 1,
    );
  }

  Future<Cart> clearCart() async {
    final cart = await getCart();

    for (final item in cart.items) {
      await removeItem(item.id);
    }

    return getCart();
  }

  Future<Map<String, dynamic>> getCartSummary() async {
    final cart = await getCart();

    return {
      'total_items': cart.totalItems,
      'unique_items': cart.items.length,
      'subtotal': cart.subtotalValue,
      'total': cart.totalValue,
      'out_of_stock_items': cart.outOfStockItems.length,
      'low_stock_items': cart.lowStockItems.length,
    };
  }

  Future<bool> isInCart(int productId) async {
    final cart = await getCart();
    return cart.containsProduct(productId);
  }

  Future<int> getProductQuantity(int productId) async {
    final cart = await getCart();
    final item = cart.getItemByProductId(productId);
    return item?.quantity ?? 0;
  }
}
