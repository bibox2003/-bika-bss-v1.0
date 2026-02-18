class CartItem {
  final int id;
  final int productId;
  final String productName;
  final String? productImage;
  final int quantity;
  final String unitPrice;
  final String totalPrice;
  final int productStock;
  final String? productCreatedBy;
  final String? productUnitName;

  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.productStock,
    required this.productCreatedBy,
    required this.productUnitName,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: (json['id'] as num).toInt(),
      productId: (json['product'] as num).toInt(),
      productName: (json['product_name'] ?? '').toString(),
      productImage: json['product_image']?.toString(),
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      unitPrice: (json['unit_price'] ?? '0').toString(),
      totalPrice: (json['total_price'] ?? '0').toString(),
      productStock: ((json['product_stock'] ?? 0) as num).toInt(),
      productCreatedBy: json['product_created_by']?.toString(),
      productUnitName: json['product_unit_name']?.toString(),
    );
  }
}
