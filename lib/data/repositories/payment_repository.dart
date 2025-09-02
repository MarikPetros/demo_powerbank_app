// lib/data/repositories/payment_repository.dart
import 'package:dio/dio.dart';

class PaymentRepository {
  final Dio _dio;

  PaymentRepository(Dio dio) : _dio = dio;

  /// 1. Generate & save client token on server
  Future<String> fetchClientToken() async {
    final resp = await _dio.get('/payments/generate-and-save-braintree-client-token');
    return resp.data['clientToken'] as String;
  }

  /// 2. Send the payment nonce from client to server
  Future<String> addPaymentMethod(String nonce) async {
    final resp = await _dio.post(
      '/payments/add-payment-method',
      data: {
        'paymentNonceFromTheClient': nonce,
        'description': 'Flutter rent',
        'paymentType': 'CARD',
      },
    );
    return resp.data['paymentMethodNonce'] as String; // server-stored token
  }

  /// 3. Create subscription transaction
  Future<void> createSubscription({
    required String paymentToken,
    required String planId,
  }) async {
    await _dio.post(
      '/payments/subscription/create-subscription-transaction-v2',
      queryParameters: {
        'disableWelcomeDiscount': false,
        'welcomeDiscount': 10,
      },
      data: {
        'paymentToken': paymentToken,
        'thePlanId': planId,
      },
    );
  }

  /// 4. Rent a power bank
  Future<void> rentPowerBank({
    required String cabinetId,
    required String connectionKey,
  }) async {
    await _dio.post(
      '/payments/rent-power-bank',
      data: {
        'cabinetId': cabinetId,
        'connectionKey': connectionKey,
      },
    );
  }
}
