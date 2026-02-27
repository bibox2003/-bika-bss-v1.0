class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final String unitPrice; // Price per unit
  final String totalPrice; // Total price for this item (unitPrice * quantity)
  final int productStock; // Available stock for this product
  final String? productCreatedBy;
  final String? productUnitName;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.productStock,
    this.productCreatedBy,
    this.productUnitName,
  });

  // ---------------------------
  // Safe converters
  // ---------------------------
  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    // Backend can return:
    // 1) flat fields: product_id, product_name, unit_price...
    // 2) nested product object: "product": {id, name, price, ...}
    final productRaw = json['product'];
    final Map<String, dynamic> product =
        productRaw is Map<String, dynamic> ? productRaw : <String, dynamic>{};

    final qty = _asInt(json['quantity']);

    // product_id may be:
    // - flat number
    // - nested under product.id
    // - sometimes product itself if backend returns product as int
    final int resolvedProductId = () {
      if (json['product_id'] != null) return _asInt(json['product_id']);
      if (product['id'] != null) return _asInt(product['id']);
      if (productRaw is num || productRaw is String) return _asInt(productRaw);
      return 0;
    }();

    final String resolvedProductName =
        _asString(json['product_name'] ?? json['name'] ?? product['name']);

    final dynamic unitPriceRaw = json['unit_price'] ??
        json['price'] ??
        product['price'] ??
        product['final_price'];

    final String resolvedUnitPrice = _asString(unitPriceRaw, fallback: '0');

    final String resolvedTotalPrice = _asString(
      json['total_price'] ?? json['total'],
      fallback: '',
    ).isNotEmpty
        ? _asString(json['total_price'] ?? json['total'])
        : (_asDouble(unitPriceRaw) * qty).toStringAsFixed(2);

    final int resolvedProductStock = _asInt(
      json['product_stock'] ??
          json['stock'] ??
          json['stock_quantity'] ??
          product['stock_quantity'],
    );

    final String? resolvedProductImage = (() {
      final val = json['product_image'] ??
          json['image'] ??
          json['image_url'] ??
          product['product_image'] ??
          product['image'] ??
          product['image_url'];
      if (val == null) return null;
      final s = val.toString().trim();
      return s.isEmpty ? null : s;
    })();

    final String? resolvedProductCreatedBy = (() {
      final val = json['product_created_by'] ??
          json['created_by'] ??
          product['created_by'] ??
          product['created_by_name'];
      if (val == null) return null;

      // If backend returns nested creator object, extract a readable field
      if (val is Map<String, dynamic>) {
        return _asString(
          val['username'] ?? val['name'] ?? val['full_name'] ?? val['email'],
          fallback: '',
        ).isEmpty
            ? null
            : _asString(
                val['username'] ??
                    val['name'] ??
                    val['full_name'] ??
                    val['email'],
              );
      }

      final s = val.toString().trim();
      return s.isEmpty ? null : s;
    })();

    final String? resolvedProductUnitName = (() {
      final val = json['product_unit_name'] ??
          json['unit_name'] ??
          product['unit_name'] ??
          product['unit'];

      if (val == null) return null;

      // If unit is nested object
      if (val is Map<String, dynamic>) {
        final s = _asString(val['name'] ?? val['title'], fallback: '');
        return s.isEmpty ? null : s;
      }

      final s = val.toString().trim();
      return s.isEmpty ? null : s;
    })();

    return CartItem(
      id: _asInt(json['id']),
      productId: resolvedProductId,
      productName: resolvedProductName,
      productImage: resolvedProductImage,
      quantity: qty,
      unitPrice: resolvedUnitPrice,
      totalPrice: resolvedTotalPrice,
      productStock: resolvedProductStock,
      productCreatedBy: resolvedProductCreatedBy,
      productUnitName: resolvedProductUnitName,
    );
  }

  // Calculate total price if not provided by API
  String get calculatedTotalPrice {
    final unit = double.tryParse(unitPrice) ?? 0;
    return (unit * quantity).toStringAsFixed(2);
  }

  // Check if item is in stock
  bool get isInStock =>
      quantity <= productStock || productStock <= 0 ? productStock > 0 : true;

  // Check if item is low stock (less than 5 units available after this purchase)
  bool get isLowStock =>
      (productStock - quantity) < 5 && (productStock - quantity) > 0;

  // Check if item is out of stock
  bool get isOutOfStock => productStock == 0;

  // Maximum quantity that can be added based on stock
  int get maxAvailableQuantity => productStock;

  Map<String, dynamic> toJson() => {
        'id': id,
        'product_id': productId,
        'product_name': productName,
        'product_image': productImage,
        'quantity': quantity,
        'unit_price': unitPrice,
        'total_price': totalPrice,
        'product_stock': productStock,
        'product_created_by': productCreatedBy,
        'product_unit_name': productUnitName,
      };

  // Simplified version for API requests (add/update cart)
  Map<String, dynamic> toRequestJson() => {
        'product_id': productId,
        'quantity': quantity,
      };
}

class Cart {
  final int id;
  final List<CartItem> items;
  final String? subtotal; // Optional: total before tax/discount
  final String? total; // Optional: final total
  final int? itemCount; // Optional: total number of items

  const Cart({
    required this.id,
    required this.items,
    this.subtotal,
    this.total,
    this.itemCount,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    // Parse items list safely
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final items = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => CartItem.fromJson(e))
        .toList();

    // Calculate derived values if backend doesn't provide them
    final computedSubtotal = items.fold<double>(0.0, (sum, item) {
      final itemTotal = double.tryParse(item.totalPrice) ??
          (double.tryParse(item.unitPrice) ?? 0) * item.quantity;
      return sum + itemTotal;
    });

    final subtotalStr =
        json['subtotal']?.toString() ?? computedSubtotal.toStringAsFixed(2);

    return Cart(
      id: (json['id'] as num?)?.toInt() ?? 0,
      items: items,
      subtotal: subtotalStr,
      total: json['total']?.toString() ??
          json['grand_total']?.toString() ??
          subtotalStr,
      itemCount: (json['item_count'] as num?)?.toInt() ?? items.length,
    );
  }

  // Computed properties
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotalValue => double.tryParse(subtotal ?? '0') ?? 0;

  double get totalValue => double.tryParse(total ?? '0') ?? 0;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  // Get item by product ID
  CartItem? getItemByProductId(int productId) {
    try {
      return items.firstWhere((item) => item.productId == productId);
    } catch (_) {
      return null;
    }
  }

  // Check if cart contains a specific product
  bool containsProduct(int productId) => getItemByProductId(productId) != null;

  // Get all items that are out of stock
  List<CartItem> get outOfStockItems =>
      items.where((item) => item.isOutOfStock).toList();

  // Get all items that are low stock
  List<CartItem> get lowStockItems =>
      items.where((item) => item.isLowStock).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'items': items.map((item) => item.toJson()).toList(),
        'subtotal': subtotal,
        'total': total,
        'item_count': itemCount,
      };
}
