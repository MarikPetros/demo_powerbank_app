import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:powerbank_app/models/auth_response.dart';

class ApiService {
  final String baseUrl = 'https://goldfish-app-3lf7u.ondigitalocean.app/api/v1';

  Future<AuthResponse> generateAppleAccount() async {
    final response = await http.get(Uri.parse('$baseUrl/auth/apple/generate-account'));
    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to generate account');
    }
  }

  Future<String> getBraintreeToken(String authToken) async {
    final response = await http.get(
      Uri.parse('$baseUrl/payments/generate-and-save-braintree-client-token'),
      headers: {'Authorization': authToken},
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to get Braintree token');
    }
  }

  Future<String> addPaymentMethod(String authToken, String nonce, String description, String paymentType) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/add-payment-method'),
      headers: {
        'Authorization': authToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'paymentNonceFromTheClient': nonce,
        'description': description,
        'paymentType': paymentType,
      }),
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to add payment method');
    }
  }

  Future<void> createSubscription(String authToken, String paymentToken, String planId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/subscription/create-subscription-transaction-v2?disableWelcomeDiscount=false&welcomeDiscount=10'),
      headers: {
        'Authorization': authToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'paymentToken': paymentToken,
        'thePlanId': planId,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to create subscription');
    }
  }

  Future<String> rentPowerBank(String authToken, String cabinetId, String connectionKey) async {
    final response = await http.post(
      Uri.parse('$baseUrl/payments/rent-power-bank'),
      headers: {
        'Authorization': authToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'cabinetId': cabinetId,
        'connectionKey': connectionKey,
      }),
    );
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Failed to rent power bank');
    }
  }

  Future<Map<String, dynamic>> validateMerchant() async {
    // Replace with actual endpoint to validate Apple Pay merchant session
    final response = await http.post(
      Uri.parse('$baseUrl/auth/apple/validate-merchant'), // Hypothetical endpoint
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'merchantIdentifier': 'merchant.com.marikpetros'}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to validate merchant');
    }
  }
}