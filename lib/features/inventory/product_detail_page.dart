import 'package:flutter/material.dart';
import 'product_model.dart';

class ProductDetailPage extends StatelessWidget {
  final Product product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero image placeholder
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
            child: const Center(
              child: Icon(Icons.inventory_2_outlined, size: 70),
            ),
          ),
          const SizedBox(height: 16),

          Text(
            product.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),

          Text(
            "Added by: ${product.createdByName ?? product.vendorName ?? "-"}",
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 6),

          Text(
            "Category: ${product.categoryName ?? "-"}",
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Price",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  Text(
                    product.price ?? "-",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Stock", style: TextStyle(color: Colors.grey.shade700)),
                  Text(
                    "${product.stockQuantity} (${product.isInStock ? "In stock" : "Out"})",
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),

          if ((product.shortDescription ?? "").trim().isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(product.shortDescription!),
              ),
            ),
        ],
      ),
    );
  }
}
