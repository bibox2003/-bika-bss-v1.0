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
  Cart? _cart;
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
      // Try to get full cart object first
      try {
        final cart = await _service.getCart();
        setState(() {
          _cart = cart;
          _items = cart.items;
        });
      } catch (e) {
        // Fallback to fetching items list
        final items = await _service.fetchCartItems();
        setState(() {
          _items = items;
          _cart = Cart(
            id: 0,
            items: items,
            subtotal: _calculateSubtotal(items).toStringAsFixed(2),
            total: _calculateSubtotal(items).toStringAsFixed(2),
            itemCount: items.length,
          );
        });
      }
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

  double _calculateSubtotal(List<CartItem> items) {
    double sum = 0;
    for (final i in items) {
      sum += _toDouble(i.totalPrice);
    }
    return sum;
  }

  double _calculateTotal(Cart cart) {
    if (cart.totalValue > 0) return cart.totalValue;

    double total = 0;
    for (final i in cart.items) {
      total += _toDouble(i.unitPrice) * i.quantity;
    }
    return total;
  }

  double get _subtotal {
    if (_cart != null) return _cart!.subtotalValue;
    return _calculateSubtotal(_items);
  }

  int get _totalQty {
    if (_cart != null) return _cart!.totalItems;

    int n = 0;
    for (final i in _items) {
      n += i.quantity;
    }
    return n;
  }

  Future<void> _changeQty(CartItem item, int newQty) async {
    if (newQty < 1) return;

    // Guard with stock
    final safeQty = min(newQty, max(item.productStock, 1));

    try {
      // Try updateQuantity first (PATCH method)
      try {
        final updated = await _service.updateQuantity(
          itemId: item.id,
          quantity: safeQty,
        );

        setState(() {
          final idx = _items.indexWhere((e) => e.id == item.id);
          if (idx != -1) {
            _items[idx] = updated;
            // Update cart if exists
            if (_cart != null) {
              final cartItems = List<CartItem>.from(_cart!.items);
              final cartIdx = cartItems.indexWhere((e) => e.id == item.id);
              if (cartIdx != -1) {
                cartItems[cartIdx] = updated;
                _cart = Cart(
                  id: _cart!.id,
                  items: cartItems,
                  subtotal: _calculateSubtotal(cartItems).toStringAsFixed(2),
                  total: _calculateSubtotal(cartItems).toStringAsFixed(2),
                );
              }
            }
          }
        });
      } catch (e) {
        // Fallback to add/remove approach
        if (safeQty > item.quantity) {
          // Increase quantity
          final cart = await _service.addToCart(
            productId: item.productId,
            quantity: safeQty - item.quantity,
          );
          setState(() {
            _cart = cart;
            _items = cart.items;
          });
        } else {
          // Decrease quantity
          final cart = await _service.removeFromCart(
            productId: item.productId,
            quantity: item.quantity - safeQty,
          );
          setState(() {
            _cart = cart;
            _items = cart.items;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _removeOne(CartItem item) async {
    try {
      if (item.quantity <= 1) {
        await _removeItem(item);
      } else {
        // Try removeFromCart with quantity first
        try {
          final cart = await _service.removeFromCart(
            productId: item.productId,
            quantity: 1,
          );
          setState(() {
            _cart = cart;
            _items = cart.items;
          });
        } catch (e) {
          // Fallback to updateQuantity
          await _changeQty(item, item.quantity - 1);
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Remove failed: $e')),
      );
    }
  }

  Future<void> _removeAll(CartItem item) async {
    final yes = await _showConfirmDialog(
      title: 'Remove item',
      message: 'Remove "${item.productName}" from cart?',
      confirmText: 'Remove',
    );

    if (yes != true) return;

    try {
      // Try removeFromCart without quantity first
      try {
        final cart = await _service.removeFromCart(
          productId: item.productId,
        );
        setState(() {
          _cart = cart;
          _items = cart.items;
        });
      } catch (e) {
        // Fallback to removeItem by ID
        await _service.removeItem(item.id);
        setState(() {
          _items.removeWhere((e) => e.id == item.id);
          if (_cart != null) {
            final updatedItems = List<CartItem>.from(_cart!.items)
              ..removeWhere((e) => e.id == item.id);
            _cart = Cart(
              id: _cart!.id,
              items: updatedItems,
              subtotal: _calculateSubtotal(updatedItems).toStringAsFixed(2),
              total: _calculateSubtotal(updatedItems).toStringAsFixed(2),
            );
          }
        });
      }

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

  Future<void> _removeItem(CartItem item) async {
    final yes = await _showConfirmDialog(
      title: 'Remove item',
      message: 'Remove "${item.productName}" from cart?',
      confirmText: 'Remove',
    );

    if (yes != true) return;

    try {
      await _service.removeItem(item.id);
      setState(() {
        _items.removeWhere((e) => e.id == item.id);
        if (_cart != null) {
          final updatedItems = List<CartItem>.from(_cart!.items)
            ..removeWhere((e) => e.id == item.id);
          _cart = Cart(
            id: _cart!.id,
            items: updatedItems,
            subtotal: _calculateSubtotal(updatedItems).toStringAsFixed(2),
            total: _calculateSubtotal(updatedItems).toStringAsFixed(2),
          );
        }
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

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
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
            // Header
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Cart',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cart == null
                                ? 'Manage quantities and remove items'
                                : '${_cart!.items.length} items • ${_money(_cart!.totalValue)} total',
                            style: const TextStyle(fontSize: 13),
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

            // Content
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
              ..._items.map(_buildItemCard),
          ],
        ),
      ),
      bottomSheet: _items.isEmpty ? null : _buildSubtotalBar(),
    );
  }

  Widget _buildItemCard(CartItem item) {
    final unit = _toDouble(item.unitPrice);
    final total = _toDouble(item.totalPrice);
    final outOfStock = item.productStock == 0;
    final lowStock = item.productStock < 5 && item.productStock > 0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: outOfStock
                  ? Colors.red.shade100
                  : lowStock
                      ? Colors.orange.shade100
                      : null,
              child: Icon(
                outOfStock ? Icons.error_outline : Icons.inventory_2_outlined,
                color: outOfStock
                    ? Colors.red
                    : lowStock
                        ? Colors.orange
                        : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (outOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Out of stock',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                      else if (lowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Only ${item.productStock} left',
                            style: const TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Unit price: ${_money(unit)}'),
                  Text('Line total: ${_money(total)}'),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${item.productCreatedBy ?? "-"} • Unit: ${item.productUnitName ?? "-"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    'Available stock: ${item.productStock}',
                    style: TextStyle(
                      fontSize: 12,
                      color: outOfStock
                          ? Colors.red
                          : lowStock
                              ? Colors.orange
                              : Colors.grey,
                      fontWeight: outOfStock || lowStock
                          ? FontWeight.w700
                          : FontWeight.normal,
                    ),
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
                      onPressed: outOfStock
                          ? null
                          : () => _changeQty(item, item.quantity - 1),
                      icon: Icon(
                        Icons.remove_circle_outline,
                        color: outOfStock ? Colors.grey : null,
                      ),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 30),
                      child: Text(
                        '${item.quantity}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed:
                          outOfStock || item.quantity >= item.productStock
                              ? null
                              : () => _changeQty(item, item.quantity + 1),
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: outOfStock || item.quantity >= item.productStock
                            ? Colors.grey
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: outOfStock ? null : () => _removeOne(item),
                      icon: const Icon(Icons.remove_shopping_cart_outlined),
                      iconSize: 18,
                      tooltip: 'Remove one',
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _removeAll(item),
                      icon: const Icon(Icons.delete_outline),
                      iconSize: 18,
                      tooltip: 'Remove all',
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtotalBar() {
    final hasOutOfStock = _items.any((item) => item.productStock == 0);

    return Material(
      elevation: 10,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasOutOfStock)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Some items are out of stock',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
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
                    onPressed: hasOutOfStock
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Checkout step comes next in our schedule',
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.payment_outlined),
                    label: const Text('Checkout'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
