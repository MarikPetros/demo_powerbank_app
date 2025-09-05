// lib/services/mock_payment_service.dart
import 'payment_service.dart';

class MockPaymentService extends PaymentService {
  @override
  Future<Map<String, String>> generateAppleAccount() async {
    // simulate network latency
    await Future.delayed(const Duration(milliseconds: 200));
    return {'accessJwt': 'mock-jwt-token'};
  }

  @override
  Future<String> getClientToken(String jwt) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 'mock-client-token';
  }

  @override
  Future<String> addPaymentMethod(String jwt,
      String nonce,
      String name,
      String type,) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return 'mock-method-token';
  }

  @override
  Future<void> createSubscription(String methodToken) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }

  @override
  Future<void> rentPowerBank(String jwt,
      String stationId,
      String connectionKey,) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
