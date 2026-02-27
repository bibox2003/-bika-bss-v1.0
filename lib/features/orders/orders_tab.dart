import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import 'orders_models.dart';
import 'orders_service.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  late final OrdersService _service;

  bool _loading = true;
  String? _error;
  List<OrderListItem> _orders = [];

  @override
  void initState() {
    super.initState();
    _service = OrdersService(ApiClient(AuthService()));
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await _service.listOrders();
      setState(() => _orders = data);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(String v) {
    final n = double.tryParse(v) ?? 0.0;
    return n.toStringAsFixed(2);
  }

  Future<void> _openDetail(int id) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OrderDetailSheet(
        orderId: id,
        service: _service,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
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
                  title: const Text('Failed to load orders'),
                  subtitle: Text(_error!),
                ),
              )
            else if (_orders.isEmpty)
              const Card(
                child: ListTile(
                  leading: Icon(Icons.inbox_outlined),
                  title: Text('No orders yet'),
                  subtitle:
                      Text('Place an order from Checkout to see it here.'),
                ),
              )
            else
              ..._orders.map((o) {
                return Card(
                  elevation: 0,
                  child: ListTile(
                    onTap: () => _openDetail(o.id),
                    leading: CircleAvatar(
                      child: Text(o.itemsCount.toString()),
                    ),
                    title: Text(o.orderNumber),
                    subtitle:
                        Text('Status: ${o.status} • Items: ${o.itemsCount}'),
                    trailing: Text(_money(o.totalAmount)),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final int orderId;
  final OrdersService service;

  const _OrderDetailSheet({
    required this.orderId,
    required this.service,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  bool _loading = true;
  String? _error;
  OrderDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final d = await widget.service.getOrder(widget.orderId);
      setState(() => _detail = d);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _money(String v) {
    final n = double.tryParse(v) ?? 0.0;
    return n.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final d = _detail;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order Details',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
                ],
              ),
              const SizedBox(height: 10),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )
              else if (_error != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.error_outline),
                    title: const Text('Failed to load order'),
                    subtitle: Text(_error!),
                  ),
                )
              else if (d != null) ...[
                Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(d.orderNumber),
                    subtitle: Text('Status: ${d.status}'),
                    trailing: Text(_money(d.totalAmount)),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Addresses',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        Text('Shipping:\n${d.shippingAddress}'),
                        const SizedBox(height: 8),
                        Text('Billing:\n${d.billingAddress}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Items',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ...d.items.map((it) => ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              title: Text(it.productName),
                              subtitle: Text(
                                  'Qty: ${it.quantity} • Unit: ${_money(it.price)}'),
                              trailing: Text(_money(it.totalPrice)),
                            )),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Payments',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        if (d.payments.isEmpty)
                          const Text('No payments recorded yet.')
                        else
                          ...d.payments.map((p) => ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                leading: const Icon(Icons.payments_outlined),
                                title: Text('${p.paymentMethod} • ${p.status}'),
                                subtitle: Text(
                                    'Amount: ${_money(p.amount)} ${p.currency}'
                                    '${p.transactionId == null || p.transactionId!.isEmpty ? "" : "\nTx: ${p.transactionId}"}'),
                              )),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
