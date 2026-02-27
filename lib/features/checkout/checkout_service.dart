import 'dart:convert';
import '../../services/api_client.dart';
import 'checkout_models.dart';

class CheckoutService {
  final ApiClient _apiClient;
  CheckoutService(this._apiClient);

  String _cleanErrorBody(String body) {
    final trimmed = body.trimLeft();
    if (trimmed.startsWith('<!DOCTYPE html') || trimmed.startsWith('<html')) {
      return 'Endpoint not found or wrong route.';
    }
    return body;
  }

  Future<CheckoutPreview> preview() async {
    final endpoints = [
      '/api/v1/checkout/preview/',
      '/api/checkout/preview/',
      '/api/v1/checkout/',
      '/api/checkout/',
    ];

    String? lastError;

    for (final path in endpoints) {
      try {
        final res = await _apiClient.get(path);

        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            return CheckoutPreview.fromJson(decoded);
          }
          lastError = 'Unexpected checkout preview format on $path';
          continue;
        }

        lastError =
            'Failed to load checkout preview (${res.statusCode}): ${_cleanErrorBody(res.body)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'Failed to load checkout preview');
  }

  Future<Map<String, dynamic>> createOrder({
    required String shippingAddress,
    required String billingAddress,
    required String paymentMethod,
    required String currency,
    String mobileMoneyPhone = '',
    String payerEmail = '',
  }) async {
    final endpoints = [
      '/api/v1/checkout/create-order/',
      '/api/checkout/create-order/',
      '/api/v1/orders/create/',
      '/api/orders/create/',
      '/api/v1/orders/',
      '/api/orders/',
    ];

    final body = {
      'shipping_address': shippingAddress,
      'billing_address': billingAddress,
      'payment_method': paymentMethod,
      'currency': currency,
      'mobile_money_phone': mobileMoneyPhone,
      'payer_email': payerEmail,
    };

    String? lastError;

    for (final path in endpoints) {
      try {
        final res = await _apiClient.post(path, body: body);

        if (res.statusCode == 200 || res.statusCode == 201) {
          final decoded = jsonDecode(res.body);
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
          return {'success': true};
        }

        lastError =
            'Checkout failed (${res.statusCode}): ${_cleanErrorBody(res.body)}';
      } catch (e) {
        lastError = e.toString();
      }
    }

    throw Exception(lastError ?? 'Checkout failed on all endpoints');
  }
}
