import 'dart:math';
import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import 'cart_item_model.dart';
import 'cart_service.dart';

class CartTab extends StatefulWidget {
  const CartTab({super.key});

  @override
  State<CartTab> createState() => _CartTabState();
}

class _CartTabState extends State<CartTab> {
  late final CartService _service;

  bool _loading = true;
  String? _error;
  List<CartItem> _items = [];

  @override
  void initState() {
    super.initState();
    _service = CartService(ApiClient(AuthService()));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.fetchCartItems();
      setState(() => _items = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double _toDouble(String value) {
    return double.tryParse(value.replaceAll(',', '').trim()) ?? 0.0;
  }

  String _money(double v) {
    return v.toStringAsFixed(2);
  }

  double get _subtotal {
    double sum = 0;
    for (final i in _items) {
      sum += _toDouble(i.totalPrice);
    }
    return sum;
  }

  int get _totalQty {
    int n = 0;
    for (final i in _items) {
      n += i.quantity;
    }
    return n;
  }

  Future<void> _changeQty(CartItem item, int newQty) async {
    if (newQty < 1) return;

    // Optional guard with stock
    final safeQty = min(newQty, max(item.productStock, 1));

    try {
      final updated = await _service.updateQuantity(
        itemId: item.id,
        quantity: safeQty,
      );

      setState(() {
        final idx = _items.indexWhere((e) => e.id == item.id);
        if (idx != -1) _items[idx] = updated;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _removeItem(CartItem item) async {
    try {
      await _service.removeItem(item.id);
      setState(() {
        _items.removeWhere((e) => e.id == item.id);
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.productName} removed')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: $e')),
      );
    }
  }

  Future<void> _confirmRemove(CartItem item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove item'),
        content: Text('Remove "${item.productName}" from cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (yes == true) {
      await _removeItem(item);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
          children: [
            Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.shopping_cart_outlined),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cart',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Manage quantities and remove items',
                            style: TextStyle(fontSize: 13),
                          ),
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
                  title: const Text('Failed to load cart'),
                  subtitle: Text(_error!),
                  trailing: IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _load,
                  ),
                ),
              )
            else if (_items.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.inbox_outlined),
                  title: Text('Your cart is empty'),
                  subtitle: Text('Add products from inventory'),
                ),
              )
            else
              ..._items.map(_itemCard),
          ],
        ),
      ),
      bottomSheet: _items.isEmpty ? null : _subtotalBar(),
    );
  }

  Widget _itemCard(CartItem item) {
    final unit = _toDouble(item.unitPrice);
    final total = _toDouble(item.totalPrice);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 22,
              child: Icon(Icons.inventory_2_outlined),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Unit price: ${_money(unit)}'),
                  Text('Line total: ${_money(total)}'),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${item.productCreatedBy ?? "-"} • Unit: ${item.productUnitName ?? "-"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Available stock: ${item.productStock}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: item.quantity > 1
                          ? () => _changeQty(item, item.quantity - 1)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '${item.quantity}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: item.quantity < item.productStock
                          ? () => _changeQty(item, item.quantity + 1)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _confirmRemove(item),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _subtotalBar() {
    return Material(
      elevation: 10,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Items: $_totalQty'),
                    const SizedBox(height: 2),
                    Text(
                      'Subtotal: ${_money(_subtotal)}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checkout step comes next in our schedule'),
                    ),
                  );
                },
                icon: const Icon(Icons.payment_outlined),
                label: const Text('Checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
