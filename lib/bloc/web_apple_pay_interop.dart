// web_apple_pay_interop.dart
@JS()
library;

import 'dart:async';
import 'package:js/js.dart';

typedef ApplePayResultCallback = void Function(String? nonce, String? error);
typedef ApplePayAvailabilityCallback = void Function(bool isAvailable, String? reason);

@JS('window.flutterApplePayResultHandler')
external set flutterApplePayResultHandler(ApplePayResultCallback callback);

// New JS function you'll need to create in index.html
@JS('checkApplePayAvailabilityJS')
external void checkApplePayAvailabilityJS(String clientToken, ApplePayAvailabilityCallback callback);

@JS('initiateApplePayFromFlutter')
external void initiateApplePayFromFlutter(String clientToken);

class WebApplePay {
  Future<bool> checkAvailability(String clientToken) {
    final completer = Completer<bool>();
    try {
      checkApplePayAvailabilityJS(
        clientToken,
        allowInterop((bool isAvailable, String? reason) {
          if (isAvailable) {
            completer.complete(true);
          } else {
            print('Dart: Apple Pay not available via JS. Reason: $reason');
            completer.complete(false);
          }
        }),
      );
    } catch (e) {
      print('Dart: Error calling checkApplePayAvailabilityJS: $e');
      completer.complete(false); // Assume not available if JS call fails
    }
    return completer.future;
  }

  Future<String?> startApplePay(String clientToken) {
    final completer = Completer<String?>();
    flutterApplePayResultHandler = allowInterop((String? nonce, String? error) {
      if (error != null) {
        if (error == "cancelled") {
          print('Dart: Apple Pay cancelled by user.');
          completer.complete(null);
        } else {
          print('Dart: Apple Pay error: $error');
          completer.completeError(Exception('Apple Pay JS Error: $error'));
        }
      } else if (nonce != null) {
        print('Dart: Apple Pay success, nonce: $nonce');
        completer.complete(nonce);
      } else {
        completer.completeError(Exception('Apple Pay JS Error: Unknown result'));
      }
    });

    try {
      initiateApplePayFromFlutter(clientToken);
    } catch (e) {
      completer.completeError(Exception('Failed to call JS initiateApplePayFromFlutter: $e'));
    }
    return completer.future;
  }
}
