class DashboardProductStats {
  final int total;
  final int active;
  final int outOfStock;
  final int lowStock;

  DashboardProductStats({
    required this.total,
    required this.active,
    required this.outOfStock,
    required this.lowStock,
  });

  factory DashboardProductStats.fromJson(Map<String, dynamic> json) {
    return DashboardProductStats(
      total: ((json['total'] ?? 0) as num).toInt(),
      active: ((json['active'] ?? 0) as num).toInt(),
      outOfStock: ((json['out_of_stock'] ?? 0) as num).toInt(),
      lowStock: ((json['low_stock'] ?? 0) as num).toInt(),
    );
  }
}

class DashboardCartStats {
  final int itemsCount;
  final int totalQuantity;
  final String totalValue;

  DashboardCartStats({
    required this.itemsCount,
    required this.totalQuantity,
    required this.totalValue,
  });

  factory DashboardCartStats.fromJson(Map<String, dynamic> json) {
    return DashboardCartStats(
      itemsCount: ((json['items_count'] ?? 0) as num).toInt(),
      totalQuantity: ((json['total_quantity'] ?? 0) as num).toInt(),
      totalValue: (json['total_value'] ?? '0').toString(),
    );
  }
}

class DashboardRecentProduct {
  final int id;
  final String name;
  final int stockQuantity;
  final String status;
  final String price;
  final String createdAt;

  DashboardRecentProduct({
    required this.id,
    required this.name,
    required this.stockQuantity,
    required this.status,
    required this.price,
    required this.createdAt,
  });

  factory DashboardRecentProduct.fromJson(Map<String, dynamic> json) {
    return DashboardRecentProduct(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
      stockQuantity: ((json['stock_quantity'] ?? 0) as num).toInt(),
      status: (json['status'] ?? '').toString(),
      price: (json['price'] ?? '0').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
    );
  }
}

class DashboardSummary {
  final DashboardProductStats products;
  final DashboardCartStats cart;
  final List<DashboardRecentProduct> recentProducts;

  DashboardSummary({
    required this.products,
    required this.cart,
    required this.recentProducts,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final recent = (json['recent_products'] as List? ?? [])
        .map((e) => DashboardRecentProduct.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardSummary(
      products: DashboardProductStats.fromJson(
        (json['products'] ?? {}) as Map<String, dynamic>,
      ),
      cart: DashboardCartStats.fromJson(
        (json['cart'] ?? {}) as Map<String, dynamic>,
      ),
      recentProducts: recent,
    );
  }
}
