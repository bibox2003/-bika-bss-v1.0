class CheckoutItem {
  final int cartItemId;
  final int productId;
  final String productName;
  final int quantity;
  final String unitPrice;
  final String totalPrice;

  CheckoutItem({
    required this.cartItemId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory CheckoutItem.fromJson(Map<String, dynamic> json) {
    return CheckoutItem(
      cartItemId: (json['cart_item_id'] as num).toInt(),
      productId: (json['product_id'] as num).toInt(),
      productName: (json['product_name'] ?? '').toString(),
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      unitPrice: (json['unit_price'] ?? '0').toString(),
      totalPrice: (json['total_price'] ?? '0').toString(),
    );
  }
}

class CheckoutPreview {
  final List<CheckoutItem> items;
  final String subtotal;
  final int totalItems;

  CheckoutPreview({
    required this.items,
    required this.subtotal,
    required this.totalItems,
  });

  factory CheckoutPreview.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List? ?? []);
    return CheckoutPreview(
      items: rawItems
          .map((e) => CheckoutItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] ?? '0').toString(),
      totalItems: ((json['total_items'] ?? 0) as num).toInt(),
    );
  }
}
