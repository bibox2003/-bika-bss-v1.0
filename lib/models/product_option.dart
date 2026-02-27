class ProductOption {
  final int id;
  final String name;

  const ProductOption({
    required this.id,
    required this.name,
  });

  factory ProductOption.fromJson(Map<String, dynamic> json) {
    return ProductOption(
      id: (json['id'] as num).toInt(),
      name: (json['name'] ?? '').toString(),
    );
  }
}
