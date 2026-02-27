import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import 'inventory_service.dart';
import 'product_model.dart';
import '../cart/cart_service.dart';

enum StockFilter { all, inStock, lowStock }

class InventoryTab extends StatefulWidget {
  const InventoryTab({super.key});

  @override
  State<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends State<InventoryTab> {
  late final InventoryService _inventory;
  late final CartService _cart;

  bool _loading = true;
  bool _mineOnly = false;
  StockFilter _stockFilter = StockFilter.all;
  String _search = '';
  String? _error;
  List<Product> _products = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final api = ApiClient(AuthService());
    _inventory = InventoryService(api);
    _cart = CartService(api);
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _inventory.fetchProducts(mineOnly: _mineOnly);
      if (!mounted) return;
      setState(() => _products = data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  bool _isLowStock(Product p) => p.isInStock && p.stockQuantity <= 5;

  List<Product> get _filteredProducts {
    var list = _products;

    switch (_stockFilter) {
      case StockFilter.all:
        break;
      case StockFilter.inStock:
        list = list.where((p) => p.isInStock).toList();
        break;
      case StockFilter.lowStock:
        list = list.where(_isLowStock).toList();
        break;
    }

    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((p) {
        return p.name.toLowerCase().contains(q) ||
            (p.sku ?? '').toLowerCase().contains(q) ||
            (p.categoryName ?? '').toLowerCase().contains(q) ||
            (p.createdByName ?? '').toLowerCase().contains(q) ||
            (p.unitName ?? '').toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  Future<void> _openCreate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ProductEditorDialog(
        title: 'Add Product',
        onSubmit: (draft) async {
          await _inventory.createProduct(
            name: draft.name,
            sku: draft.sku,
            price: draft.price,
            stockQuantity: draft.stockQuantity,
            status: draft.isActive ? 'active' : 'out_of_stock',
          );
        },
      ),
    );

    if (ok == true) await _load();
  }

  Future<void> _openEdit(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => ProductEditorDialog(
        title: 'Edit Product',
        initial: ProductDraft.fromProduct(p),
        onSubmit: (draft) async {
          await _inventory.updateProduct(
            id: p.id,
            name: draft.name,
            sku: draft.sku,
            price: draft.price,
            stockQuantity: draft.stockQuantity,
            status: draft.isActive ? 'active' : 'out_of_stock',
          );
        },
      ),
    );

    if (ok == true) await _load();
  }

  Future<void> _delete(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('This will delete "${p.name}" permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _inventory.deleteProduct(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted successfully')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _openActions(Product p) async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child:
                        Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'Stock: ${p.stockQuantity} • SKU: ${p.sku ?? "-"} • Price: ${p.price ?? "-"}',
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const Icon(Icons.remove_circle_outline),
                  title: const Text('Decrease Stock'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _adjustStock(p, -1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Increase Stock'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _adjustStock(p, 1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.add_shopping_cart_outlined),
                  title: const Text('Add to Cart'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _addToCart(p);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Product'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _openEdit(p);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('View Details'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _showProductDetails(p.id);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: const Text('Delete Product',
                      style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    await _delete(p);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _adjustStock(Product p, int delta) async {
    try {
      await _inventory.adjustStock(productId: p.id, delta: delta);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock updated for ${p.name}')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stock update failed: $e')),
      );
    }
  }

  Future<void> _addToCart(Product p) async {
    int qty = 1;

    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setLocalState) => AlertDialog(
            title: const Text('Add to Cart'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(p.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed:
                          qty > 1 ? () => setLocalState(() => qty--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$qty',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      onPressed: () => setLocalState(() => qty++),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, qty),
                child: const Text('Add'),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) return;

    try {
      await _cart.addToCart(productId: p.id, quantity: result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${p.name} added to cart (x$result)')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Add to cart failed: $e')),
      );
    }
  }

  Future<void> _showProductDetails(int productId) async {
    try {
      final product = await _inventory.fetchProductDetail(productId);
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(product.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _d('SKU', product.sku ?? '-'),
                _d('Price', product.price ?? '-'),
                _d('Stock', '${product.stockQuantity}'),
                _d('Status', product.status ?? '-'),
                _d('Condition', product.condition ?? '-'),
                _d('Category', product.categoryName ?? '-'),
                _d('Brand', product.brand ?? '-'),
                _d('Model', product.model ?? '-'),
                _d('Color', product.color ?? '-'),
                _d('Size', product.size ?? '-'),
                _d('Material', product.material ?? '-'),
                _d('Added by',
                    product.createdByName ?? product.vendorName ?? '-'),
                _d('Unit', product.unitName ?? '-'),
                _d('Created', _formatDate(product.createdAt)),
                _d('Last Updated', _formatDate(product.updatedAt)),
                const SizedBox(height: 8),
                const Text('Description',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(product.description ?? product.shortDescription ?? '-'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load details: $e')),
      );
    }
  }

  Widget _d(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: [
              TextSpan(
                  text: '$k: ',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: v),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final displayed = _filteredProducts;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 20,
                          child: Icon(Icons.inventory_2_outlined),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Inventory',
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              SizedBox(height: 2),
                              Text('Tap a product for quick actions',
                                  style: TextStyle(fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                onPressed: _openCreate,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              )
            ],
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _search.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _search = '');
                              },
                              icon: const Icon(Icons.clear),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All Team'),
                        selected: !_mineOnly,
                        onSelected: (s) {
                          if (!s) return;
                          setState(() => _mineOnly = false);
                          _load();
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Mine'),
                        selected: _mineOnly,
                        onSelected: (s) {
                          if (!s) return;
                          setState(() => _mineOnly = true);
                          _load();
                        },
                      ),
                      ChoiceChip(
                        label: const Text('All Stock'),
                        selected: _stockFilter == StockFilter.all,
                        onSelected: (s) => s
                            ? setState(() => _stockFilter = StockFilter.all)
                            : null,
                      ),
                      ChoiceChip(
                        label: const Text('In Stock'),
                        selected: _stockFilter == StockFilter.inStock,
                        onSelected: (s) => s
                            ? setState(() => _stockFilter = StockFilter.inStock)
                            : null,
                      ),
                      ChoiceChip(
                        label: const Text('Low Stock'),
                        selected: _stockFilter == StockFilter.lowStock,
                        onSelected: (s) => s
                            ? setState(
                                () => _stockFilter = StockFilter.lowStock)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.error_outline),
                title: const Text('Failed to load products'),
                subtitle: Text(_error!),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _load,
                ),
              ),
            )
          else if (displayed.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.inbox_outlined),
                title: Text('No products match your filters'),
                subtitle:
                    Text('Try changing search/filter or add a new product'),
              ),
            )
          else
            ...displayed.map((p) {
              final outOfStock = p.stockQuantity <= 0;
              final lowStock = p.stockQuantity > 0 && p.stockQuantity < 5;

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  onTap: () => _openActions(p),
                  leading: CircleAvatar(
                    child:
                        Text(p.name.isNotEmpty ? p.name[0].toUpperCase() : '?'),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('SKU: ${p.sku ?? "-"} • Price: ${p.price ?? "-"}'),
                      Text(
                          'Stock: ${p.stockQuantity} • Category: ${p.categoryName ?? "-"}'),
                      Text(
                          'Added by: ${p.createdByName ?? p.vendorName ?? "-"}'),
                      Text('Unit: ${p.unitName ?? "-"}'),
                      Text('Created: ${_formatDate(p.createdAt)}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (outOfStock)
                        const Icon(Icons.remove_shopping_cart_outlined,
                            color: Colors.red)
                      else if (lowStock)
                        const Icon(Icons.warning_amber_outlined,
                            color: Colors.orange),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class ProductDraft {
  final String name;
  final String sku;
  final String price;
  final int stockQuantity;
  final bool isActive;

  const ProductDraft({
    required this.name,
    required this.sku,
    required this.price,
    required this.stockQuantity,
    required this.isActive,
  });

  factory ProductDraft.fromProduct(Product p) => ProductDraft(
        name: p.name,
        sku: p.sku ?? '',
        price: p.price ?? '0',
        stockQuantity: p.stockQuantity,
        isActive: (p.status ?? 'active') == 'active',
      );
}

class ProductEditorDialog extends StatefulWidget {
  final String title;
  final ProductDraft? initial;
  final Future<void> Function(ProductDraft value) onSubmit;

  const ProductEditorDialog({
    super.key,
    required this.title,
    required this.onSubmit,
    this.initial,
  });

  @override
  State<ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<ProductEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _price;
  late final TextEditingController _qty;

  bool _active = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _name = TextEditingController(text: i?.name ?? '');
    _sku = TextEditingController(text: i?.sku ?? '');
    _price = TextEditingController(text: i?.price ?? '0');
    _qty = TextEditingController(text: (i?.stockQuantity ?? 0).toString());
    _active = i?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _price.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final sku = _sku.text.trim();
    final price = _price.text.trim();
    final qty = int.tryParse(_qty.text.trim()) ?? -1;

    if (name.isEmpty || sku.isEmpty || price.isEmpty || qty < 0) {
      setState(() => _error = 'Fill all fields (quantity must be >= 0).');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSubmit(ProductDraft(
        name: name,
        sku: sku,
        price: price,
        stockQuantity: qty,
        isActive: _active,
      ));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sku,
                decoration: const InputDecoration(
                  labelText: 'SKU (unique)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _active,
                onChanged: (v) => setState(() => _active = v),
                title: const Text('Active'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const Text('Saving...') : const Text('Save'),
        ),
      ],
    );
  }
}
