import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import 'checkout_models.dart';
import 'checkout_service.dart';

class CheckoutTab extends StatefulWidget {
  const CheckoutTab({super.key});

  @override
  State<CheckoutTab> createState() => _CheckoutTabState();
}

class _CheckoutTabState extends State<CheckoutTab> {
  late final CheckoutService _service;

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  CheckoutPreview? _preview;

  final _shippingCtrl = TextEditingController();
  final _billingCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  String _paymentMethod = 'mtn_rw';
  String _currency = 'RWF';

  @override
  void initState() {
    super.initState();
    _service = CheckoutService(ApiClient(AuthService()));
    _load();
  }

  @override
  void dispose() {
    _shippingCtrl.dispose();
    _billingCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.preview();
      setState(() => _preview = data);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_preview == null || _preview!.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add items first.')),
      );
      return;
    }

    final shipping = _shippingCtrl.text.trim();
    final billing =
        _billingCtrl.text.trim().isEmpty ? shipping : _billingCtrl.text.trim();

    if (shipping.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shipping address is required.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final result = await _service.createOrder(
        shippingAddress: shipping,
        billingAddress: billing,
        paymentMethod: _paymentMethod,
        currency: _currency,
        mobileMoneyPhone: _phoneCtrl.text.trim(),
        payerEmail: _emailCtrl.text.trim(),
      );

      if (!mounted) return;
      final order = (result['order'] ?? {}) as Map<String, dynamic>;
      final payment = (result['payment'] ?? {}) as Map<String, dynamic>;

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Order created ✅'),
          content: Text(
            'Order #: ${order['order_number'] ?? '-'}\n'
            'Total: ${order['total_amount'] ?? '-'}\n'
            'Payment: ${payment['method'] ?? '-'} (${payment['status'] ?? '-'})',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      _shippingCtrl.clear();
      _billingCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Checkout failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
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
                  title: const Text('Failed to load checkout'),
                  subtitle: Text(_error!),
                ),
              )
            else ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Order Summary',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text('Items: ${preview?.totalItems ?? 0}'),
                      Text('Subtotal: ${preview?.subtotal ?? "0"}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _shippingCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Shipping Address'),
                        minLines: 2,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _billingCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Billing Address (optional)'),
                        minLines: 2,
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _paymentMethod,
                        decoration:
                            const InputDecoration(labelText: 'Payment Method'),
                        items: const [
                          DropdownMenuItem(
                              value: 'mtn_rw',
                              child: Text('MTN Mobile Money (RW)')),
                          DropdownMenuItem(
                              value: 'airtel_rw',
                              child: Text('Airtel Money (RW)')),
                          DropdownMenuItem(
                              value: 'bank_transfer',
                              child: Text('Bank Transfer')),
                          DropdownMenuItem(value: 'visa', child: Text('Visa')),
                          DropdownMenuItem(
                              value: 'mastercard', child: Text('MasterCard')),
                          DropdownMenuItem(
                              value: 'paypal', child: Text('PayPal')),
                        ],
                        onChanged: (v) =>
                            setState(() => _paymentMethod = v ?? 'mtn_rw'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Mobile Money Phone (optional)'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Payer Email (optional)'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ],
        ),
      ),
      bottomSheet: (_loading || _error != null)
          ? null
          : SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.payment_outlined),
                  label: Text(_submitting ? 'Processing...' : 'Place Order'),
                ),
              ),
            ),
    );
  }
}
