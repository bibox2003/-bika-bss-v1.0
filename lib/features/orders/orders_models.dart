class OrderListItem {
  final int id;
  final String orderNumber;
  final String totalAmount;
  final String status;
  final String createdAt;
  final int itemsCount;

  OrderListItem({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.itemsCount,
  });

  factory OrderListItem.fromJson(Map<String, dynamic> json) {
    return OrderListItem(
      id: (json['id'] as num).toInt(),
      orderNumber: (json['order_number'] ?? '').toString(),
      totalAmount: (json['total_amount'] ?? '0').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      itemsCount: ((json['items_count'] ?? 0) as num).toInt(),
    );
  }
}

class OrderItem {
  final int id;
  final int product;
  final String productName;
  final int quantity;
  final String price;
  final String totalPrice;

  OrderItem({
    required this.id,
    required this.product,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.totalPrice,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: (json['id'] as num).toInt(),
      product: (json['product'] as num).toInt(),
      productName: (json['product_name'] ?? '').toString(),
      quantity: ((json['quantity'] ?? 0) as num).toInt(),
      price: (json['price'] ?? '0').toString(),
      totalPrice: (json['total_price'] ?? '0').toString(),
    );
  }
}

class PaymentMini {
  final int id;
  final String paymentMethod;
  final String amount;
  final String currency;
  final String status;
  final String? transactionId;

  PaymentMini({
    required this.id,
    required this.paymentMethod,
    required this.amount,
    required this.currency,
    required this.status,
    required this.transactionId,
  });

  factory PaymentMini.fromJson(Map<String, dynamic> json) {
    return PaymentMini(
      id: (json['id'] as num).toInt(),
      paymentMethod: (json['payment_method'] ?? '').toString(),
      amount: (json['amount'] ?? '0').toString(),
      currency: (json['currency'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      transactionId: json['transaction_id']?.toString(),
    );
  }
}

class OrderDetail {
  final int id;
  final String orderNumber;
  final String totalAmount;
  final String status;
  final String shippingAddress;
  final String billingAddress;
  final String createdAt;
  final List<OrderItem> items;
  final List<PaymentMini> payments;

  OrderDetail({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    required this.status,
    required this.shippingAddress,
    required this.billingAddress,
    required this.createdAt,
    required this.items,
    required this.payments,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final itemsRaw = (json['items'] as List? ?? []);
    final paysRaw = (json['payments'] as List? ?? []);

    return OrderDetail(
      id: (json['id'] as num).toInt(),
      orderNumber: (json['order_number'] ?? '').toString(),
      totalAmount: (json['total_amount'] ?? '0').toString(),
      status: (json['status'] ?? '').toString(),
      shippingAddress: (json['shipping_address'] ?? '').toString(),
      billingAddress: (json['billing_address'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      items: itemsRaw
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: paysRaw
          .map((e) => PaymentMini.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
