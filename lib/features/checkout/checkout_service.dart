import 'dart:convert';
import '../../services/api_client.dart';
import 'checkout_models.dart';

class CheckoutService {
  final ApiClient _apiClient;
  CheckoutService(this._apiClient);

  Future<CheckoutPreview> preview() async {
    final res = await _apiClient.get('/api/v1/checkout/preview/');
    if (res.statusCode == 200) {
      return CheckoutPreview.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception(
        'Failed to load checkout preview (${res.statusCode}): ${res.body}');
  }

  Future<Map<String, dynamic>> createOrder({
    required String shippingAddress,
    required String billingAddress,
    required String paymentMethod,
    required String currency,
    String mobileMoneyPhone = '',
    String payerEmail = '',
  }) async {
    final res = await _apiClient.post(
      '/api/v1/checkout/create-order/',
      body: {
        'shipping_address': shippingAddress,
        'billing_address': billingAddress,
        'payment_method': paymentMethod,
        'currency': currency,
        'mobile_money_phone': mobileMoneyPhone,
        'payer_email': payerEmail,
      },
    );

    if (res.statusCode == 201) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Checkout failed (${res.statusCode}): ${res.body}');
  }
}
