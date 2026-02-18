class Product {
  final int id;
  final String name;
  final String? slug;
  final String? sku;
  final String? barcode;
  final String? description;
  final String? shortDescription;
  final String? price;
  final String? comparePrice;
  final int stockQuantity;
  final bool isInStock;
  final String? status;
  final String? condition;
  final String? brand;
  final String? model;
  final String? color;
  final String? size;
  final String? material;
  final String? categoryName;
  final String? primaryImage;
  final String? createdByName;
  final String? vendorName;
  final String? unitName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.slug,
    this.sku,
    this.barcode,
    this.description,
    this.shortDescription,
    this.price,
    this.comparePrice,
    required this.stockQuantity,
    required this.isInStock,
    this.status,
    this.condition,
    this.brand,
    this.model,
    this.color,
    this.size,
    this.material,
    this.categoryName,
    this.primaryImage,
    this.createdByName,
    this.vendorName,
    this.unitName,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      slug: json['slug']?.toString(),
      sku: json['sku']?.toString(),
      barcode: json['barcode']?.toString(),
      description: json['description']?.toString(),
      shortDescription: json['short_description']?.toString(),
      price: json['final_price']?.toString() ?? json['price']?.toString(),
      comparePrice: json['compare_price']?.toString(),
      stockQuantity: ((json['stock_quantity'] ?? 0) as num).toInt(),
      isInStock: (json['is_in_stock'] ?? false) == true,
      status: json['status']?.toString(),
      condition: json['condition']?.toString(),
      brand: json['brand']?.toString(),
      model: json['model']?.toString(),
      color: json['color']?.toString(),
      size: json['size']?.toString(),
      material: json['material']?.toString(),
      categoryName: json['category_name']?.toString(),
      primaryImage: json['primary_image']?.toString(),
      createdByName: json['created_by_name']?.toString(),
      vendorName: json['vendor_name']?.toString(),
      unitName: json['unit_name']?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
}
