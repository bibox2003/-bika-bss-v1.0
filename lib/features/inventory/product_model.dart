class Product {
  final int id;
  final String name;

  final String? sku;
  final String? price; // keep as String to avoid Decimal/double issues

  final int stockQuantity;
  final String? status;

  final String? categoryName;
  final String? createdByName;
  final String? vendorName;
  final String? unitName;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? description;
  final String? shortDescription;

  final String? condition;
  final String? brand;
  final String? model;
  final String? color;
  final String? size;
  final String? material;

  /// Prefer backend boolean if provided; otherwise derive.
  final bool? isInStockRaw;

  const Product({
    required this.id,
    required this.name,
    required this.stockQuantity,
    this.sku,
    this.price,
    this.status,
    this.categoryName,
    this.createdByName,
    this.vendorName,
    this.unitName,
    this.createdAt,
    this.updatedAt,
    this.description,
    this.shortDescription,
    this.condition,
    this.brand,
    this.model,
    this.color,
    this.size,
    this.material,
    this.isInStockRaw,
  });

  bool get isInStock {
    if (isInStockRaw != null) return isInStockRaw!;
    if ((status ?? 'active') == 'out_of_stock') return false;
    return stockQuantity > 0;
  }

  static int _asInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? fallback;
  }

  static String? _asString(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static DateTime? _asDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    // Handle a few common backend shapes safely.
    final category = json['category'];
    final createdBy = json['created_by'];
    final vendor = json['vendor'];
    final unit = json['unit'];

    return Product(
      id: _asInt(json['id']),
      name: _asString(json['name']) ?? '',

      sku: _asString(json['sku']),
      // Backend might send: final_price, price, unit_price etc.
      price: _asString(json['final_price']) ?? _asString(json['price']),

      // Backend might send: stock_quantity or quantity
      stockQuantity: _asInt(json['stock_quantity'] ?? json['quantity']),
      status: _asString(json['status']),

      categoryName: category is Map<String, dynamic>
          ? _asString(category['name'])
          : _asString(json['category_name']),

      createdByName: createdBy is Map<String, dynamic>
          ? _asString(createdBy['username']) ??
              _asString(createdBy['full_name']) ??
              _asString(createdBy['name'])
          : _asString(json['created_by_name']),

      vendorName: vendor is Map<String, dynamic>
          ? _asString(vendor['username']) ??
              _asString(vendor['name']) ??
              _asString(vendor['company'])
          : _asString(json['vendor_name']),

      unitName: unit is Map<String, dynamic>
          ? _asString(unit['name'])
          : _asString(json['unit_name']),

      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),

      description: _asString(json['description']),
      shortDescription: _asString(json['short_description']),

      condition: _asString(json['condition']),
      brand: _asString(json['brand']),
      model: _asString(json['model']),
      color: _asString(json['color']),
      size: _asString(json['size']),
      material: _asString(json['material']),

      isInStockRaw:
          json['is_in_stock'] is bool ? json['is_in_stock'] as bool : null,
    );
  }
}
