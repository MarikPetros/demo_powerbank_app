import 'package:dio/dio.dart';

class PaymentService {
  final Dio dio = Dio(BaseOptions(baseUrl: 'https://goldfish-app-3lf7u.ondigitalocean.app'));

  Future<Map<String, dynamic>> generateAppleAccount() async {
    final res = await dio.get('/api/v1/auth/apple/generate-account');
    return res.data;
  }

  Future<String> getClientToken(String jwt) async {
    final res = await dio.get(
      '/api/v1/payments/generate-and-save-braintree-client-token',
      options: Options(headers: {'Authorization': jwt}),
    );
    return res.data;
  }

  Future<String> addPaymentMethod(String jwt, String nonce, String desc, String type) async {
    final res = await dio.post(
      '/api/v1/payments/add-payment-method',
      data: {
        'paymentNonceFromTheClient': nonce,
        'description': desc,
        'paymentType': type,
      },
      options: Options(headers: {'Authorization': jwt}),
    );
    return res.data;
  }

  Future<void> createSubscription(String token) async {
    await dio.post(
      '/api/v1/payments/subscription/create-subscription-transaction-v2?disableWelcomeDiscount=false&welcomeDiscount=10',
      data: {
        'paymentToken': token,
        'thePlanId': 'tss2',
      },
    );
  }

  Future<void> rentPowerBank(String jwt, String cabinetId, String connectionKey) async {
    await dio.post(
      '/api/v1/payments/rent-power-bank',
      data: {
        'cabinetId': cabinetId,
        'connectionKey': connectionKey,
      },
      options: Options(headers: {'Authorization': jwt}),
    );
  }
}
