// // lib/services/payment_service.dart
//
// import 'dart:convert';
// import 'package:dio/dio.dart';
// import 'package:flutter/cupertino.dart';
//
// class PaymentService {
//   final Dio _dio;
//
//   PaymentService({
//     Dio? dio,
//   }) : _dio = dio ??
//       Dio(BaseOptions(
//         baseUrl: 'https://goldfish-app-3lf7u.ondigitalocean.app',
//         responseType: ResponseType.json,
//         headers: {
//           'Content-Type': 'application/json',
//         },
//       ));
//
//   /// 1) /api/v1/auth/apple/generate-account → returns JSON with accessJwt
//   Future<String> generateAccount() async {
//     final resp = await _dio.get('/api/v1/auth/apple/generate-account');
//     if (resp.statusCode != 200) {
//       throw Exception(
//           'generateAccount failed: ${resp.statusCode} ${resp.data}');
//     }
//     final data = resp.data as Map<String, dynamic>;
//     return data['accessJwt'] as String;
//   }
//
//   /// 2) /api/v1/payments/generate-and-save-braintree-client-token → returns plain string
//   Future<String> getClientToken(String accessJwt) async {
//     final resp = await _dio.get(
//       '/api/v1/payments/generate-and-save-braintree-client-token',
//       options: Options(
//         headers: { 'Authorization': accessJwt },
//         responseType: ResponseType.plain,
//       ),
//     );
//     final status = resp.statusCode ?? 0;
//     if (status < 200 || status >= 300)
//     {
//       throw Exception(
//           'getClientToken failed: ${resp.statusCode} ${resp.data}');
//     }
//     return resp.data.toString().trim();
//   }
//
//   /// 3) /api/v1/payments/add-payment-method
//   Future<String> addPaymentMethod({
//     required String accessJwt,
//     required String paymentNonce,
//     String description = 'Apple Pay recharge',
//     String paymentType = 'APPLE_PAY',
//   }) async {
//     final body = {
//       'paymentNonceFromTheClient': paymentNonce,
//       'description': description,
//       'paymentType': paymentType,
//     };
//     final resp = await _dio.post(
//       '/api/v1/payments/add-payment-method',
//       data: jsonEncode(body),
//       options: Options (
//         headers: { 'Authorization': accessJwt },
//         responseType: ResponseType.plain,
//       // ),
//       validateStatus: (_) => true,  // prevent Dio from throwing on 500
//     ),
//
//     );
//     if (resp.statusCode != 200) {
//       throw Exception(
//           'addPaymentMethod failed: ${resp.statusCode} ${resp.data}');
//     }
//     return resp.data.toString().trim();
//   }
//
//   /// 4) /api/v1/payments/subscription/create-subscription-transaction-v2
//   Future<void> createSubscription({
//     required String accessJwt,
//     required String methodToken,
//     String planId = 'tss2',
//     bool disableWelcomeDiscount = false,
//     int welcomeDiscount = 10,
//   }) async {
//     final resp = await _dio.post(
//       '/api/v1/payments/subscription/create-subscription-transaction-v2',
//       queryParameters: {
//         'disableWelcomeDiscount': disableWelcomeDiscount,
//         'welcomeDiscount': welcomeDiscount,
//       },
//       data: {
//         'paymentToken': methodToken,
//         'thePlanId': planId,
//       },
//       options: Options(
//         headers: { 'Authorization': accessJwt },
//       ),
//     );
//     if (resp.statusCode != 200) {
//       debugPrint('⚠️ addPaymentMethod 500 body → ${resp.data}');
//
//       throw Exception(
//           'createSubscription failed: ${resp.statusCode} ${resp.data}');
//     }
//   }
//
//   /// 5) /api/v1/payments/rent-power-bank
//   Future<void> rentPowerBank({
//     required String accessJwt,
//     required String cabinetId,
//     required String connectionKey,
//   }) async {
//     final resp = await _dio.post(
//       '/api/v1/payments/rent-power-bank',
//       data: {
//         'cabinetId': cabinetId,
//         'connectionKey': connectionKey,
//       },
//       options: Options(
//         headers: { 'Authorization': accessJwt },
//       ),
//     );
//     if (resp.statusCode != 200) {
//       throw Exception(
//           'rentPowerBank failed: ${resp.statusCode} ${resp.data}');
//     }
//   }
// }

/////////////////
library;

// lib/services/payment_service.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart'; // Consider removing if not used directly

class PaymentService {
  final Dio _dio;

  PaymentService({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: 'https://goldfish-app-3lf7u.ondigitalocean.app',
              // Ensure this is correct
              responseType: ResponseType.json,
              // Default, but getClientToken overrides
              headers: {'Content-Type': 'application/json'},
            ),
          );

  /// 1) /api/v1/auth/apple/generate-account → returns JSON with accessJwt
  Future<String> generateAccount() async {
    final resp = await _dio.get('/api/v1/auth/apple/generate-account');
    if (resp.statusCode != 200) {
      throw Exception(
        'generateAccount failed: ${resp.statusCode} ${resp.data}',
      );
    }
    final data = resp.data as Map<String, dynamic>;
    return data['accessJwt'] as String;
  }

  /// 2) /api/v1/payments/generate-and-save-braintree-client-token → returns plain string (Braintree Client Token)
  Future<String> getClientToken(String accessJwt) async {
    // This method is called to get the BRAINTREE CLIENT TOKEN
    final resp = await _dio.get(
      '/api/v1/payments/generate-and-save-braintree-client-token',
      options: Options(
        headers: {'Authorization': accessJwt}, // Correctly uses accessJwt
        responseType:
            ResponseType.plain, // Expects plain text Braintree client token
      ),
    );
    final status = resp.statusCode ?? 0;
    if (status < 200 || status >= 300) {
      throw Exception('getClientToken failed: ${resp.statusCode} ${resp.data}');
    }
    // The response data should be the Braintree Client Token string
    return resp.data.toString().trim();
  }

  /// 3) /api/v1/payments/add-payment-method - Expects a BRAINTREE Payment Method Nonce
  Future<String> addPaymentMethod({
    required String accessJwt,
    required String
    paymentNonce, // This MUST be a Braintree Payment Method Nonce
    String description = 'Apple Pay recharge',
    String paymentType = 'APPLE_PAY',
  }) async {
    final body = {
      // 'paymentNonceFromTheClient' is the Braintree Payment Method Nonce
      'paymentNonceFromTheClient': paymentNonce,
      'description': description,
      'paymentType': paymentType,
    };
    final resp = await _dio.post(
      '/api/v1/payments/add-payment-method',
      data: jsonEncode(body),
      options: Options(
        headers: {'Authorization': accessJwt},
        responseType: ResponseType.plain,
        // Assuming it returns a method token string
        validateStatus: (_) => true,
      ),
    );
    if (resp.statusCode != 200) {
      debugPrint('⚠️ addPaymentMethod 500 body → ${resp.statusCode} ${resp.data}');
      throw Exception(
        'addPaymentMethod failed: ${resp.statusCode} ${resp.data}',
      );
    }
    return resp.data.toString().trim();
  }

  /// 4) /api/v1/payments/subscription/create-subscription-transaction-v2
  Future<void> createSubscription({
    required String accessJwt,
    required String methodToken, // Token from addPaymentMethod
    String planId = 'tss2',
    bool disableWelcomeDiscount = false,
    int welcomeDiscount = 10,
  }) async {
    final resp = await _dio.post(
      '/api/v1/payments/subscription/create-subscription-transaction-v2',
      queryParameters: {
        'disableWelcomeDiscount': disableWelcomeDiscount,
        'welcomeDiscount': welcomeDiscount,
      },
      data: {'paymentToken': methodToken, 'thePlanId': planId},
      options: Options(headers: {'Authorization': accessJwt}),
    );
    if (resp.statusCode != 200) {
      debugPrint('⚠️ createSubscription 500 body → ${resp.data}');
      throw Exception(
        'createSubscription failed: ${resp.statusCode} ${resp.data}',
      );
    }
  }

  /// 5) /api/v1/payments/rent-power-bank
  Future<void> rentPowerBank({
    required String accessJwt,
    required String cabinetId,
    required String connectionKey,
  }) async {
    final resp = await _dio.post(
      '/api/v1/payments/rent-power-bank',
      data: {'cabinetId': cabinetId, 'connectionKey': connectionKey},
      options: Options(headers: {'Authorization': accessJwt}),
    );
    if (resp.statusCode != 200) {
      debugPrint('⚠️ rentPowerBank 500 body → ${resp.statusCode} ${resp.data}');
      throw Exception('rentPowerBank failed: ${resp.statusCode} ${resp.data}');
    }
  }
}
