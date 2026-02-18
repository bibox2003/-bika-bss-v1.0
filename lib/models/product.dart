class Product {
  final int id;
  final String name;
  final String slug;
  final String sku;
  final String shortDescription;
  final String price;
  final String? comparePrice;
  final String finalPrice;
  final num discountPercentage;
  final int stockQuantity;
  final String status;
  final String condition;
  final bool isFeatured;
  final bool isInStock;
  final String? primaryImage;
  final String? categoryName;

  Product({
    required this.id,
    required this.name,
    required this.slug,
    required this.sku,
    required this.shortDescription,
    required this.price,
    this.comparePrice,
    required this.finalPrice,
    required this.discountPercentage,
    required this.stockQuantity,
    required this.status,
    required this.condition,
    required this.isFeatured,
    required this.isInStock,
    this.primaryImage,
    this.categoryName,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    return Product(
      id: json['id'] ?? 0,
      name: (json['name'] ?? '').toString(),
      slug: (json['slug'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      shortDescription: (json['short_description'] ?? '').toString(),
      price: (json['price'] ?? '0').toString(),
      comparePrice: json['compare_price']?.toString(),
      finalPrice: (json['final_price'] ?? json['price'] ?? '0').toString(),
      discountPercentage: json['discount_percentage'] ?? 0,
      stockQuantity: json['stock_quantity'] ?? 0,
      status: (json['status'] ?? '').toString(),
      condition: (json['condition'] ?? '').toString(),
      isFeatured: json['is_featured'] ?? false,
      isInStock: json['is_in_stock'] ?? false,
      primaryImage: json['primary_image']?.toString(),
      categoryName: category is Map<String, dynamic>
          ? category['name']?.toString()
          : null,
    );
  }
}
