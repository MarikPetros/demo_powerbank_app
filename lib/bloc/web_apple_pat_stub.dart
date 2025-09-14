// web_apple_pay_stub.dart
// This file is used when the platform is not web (e.g., iOS, Android mobile).
// It provides stub implementations so the code compiles.

class WebApplePay {
  Future<String?> startApplePay(String clientToken) {
    print('WebApplePay: startApplePay called on non-web platform. This should not happen for web Apple Pay.');
    // Return a future that completes with an error or null,
    // as web Apple Pay is not applicable here.
    return Future.value(null); // Or Future.error(UnsupportedError('Web Apple Pay not supported on this platform'));
  }
}