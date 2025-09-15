@JS() // Sets the context for JS interop
library; // Can be any unique name for the JS library context

import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:js/js.dart'; // Imports the js package

// --- Callbacks from JavaScript to Dart ---

// Type definition for the generic payment result callback from JavaScript
// It can be used for Apple Pay, Card payments, etc.
// Parameters:
// - type: A string to identify the payment type (e.g., "applePay", "card") - optional, but can be useful
// - nonce: The payment method nonce if successful.
// - error: An error message string if failed or cancelled.
typedef PaymentResultJsCallback = void Function(String? type, String? nonce, String? error);

// Type definition for the Apple Pay availability callback from JavaScript
typedef ApplePayAvailabilityJsCallback = void Function(bool isAvailable, String? reason);


// Expose Dart functions to JavaScript by annotating them with @JS().
// These functions will be set as global properties on `window` in JS.

// This Dart function will be assigned to `window.flutterPaymentResultHandler` in JavaScript.
// It will be called by your JS code when a payment attempt (Apple Pay, Card) completes.
// `allowInterop` makes a Dart function callable from JS.
@JS('window.flutterPaymentResultHandlerGlobal') // Give it a distinct name for clarity
external set jsPaymentResultHandlerGlobal(PaymentResultJsCallback callback);

// This Dart function will be assigned to `window.flutterApplePayAvailabilityCallbackGlobal`
@JS('window.flutterApplePayAvailabilityCallbackGlobal')
external set jsApplePayAvailabilityCallbackGlobal(ApplePayAvailabilityJsCallback callback);


// --- Calls from Dart to JavaScript ---

// Allows Dart to call the global JS function `checkApplePayAvailabilityJS`.
// This JS function should exist in your web/index.html.
@JS('checkApplePayAvailabilityJS')
external void _checkApplePayAvailabilityJS(String clientToken, ApplePayAvailabilityJsCallback callback);

// Allows Dart to call the global JS function `initiateApplePayInJS`.
// This JS function should exist in your web/index.html.
// (You might have named it `initiateApplePayFromFlutter` in index.html, ensure names match)
@JS('initiateApplePayFromFlutter') // Assuming this is the name in your index.html
external void _triggerApplePayInJS(String clientToken, String amount, String currencyCode);


// Placeholder for triggering card payment via JS.
// You'll need to define `initiateCardPaymentInJS` in your web/index.html
// which would set up Braintree Hosted Fields or a Card Form.
@JS('initiateCardPaymentInJS')
external void _triggerCardPaymentInJS(String clientToken /*, other params like amount if form needs it */);


// --- JSInteropManager Class ---

class JSInteropManager {
  // Completers to manage asynchronous results from JavaScript for specific operations
  Completer<bool>? _applePayAvailabilityCompleter;
  Completer<String?>? _paymentNonceCompleter;

  JSInteropManager() {
    _initializeGlobalCallbacks();
  }

  void _initializeGlobalCallbacks() {
    // Assign Dart functions (wrapped by allowInterop) to the global JS handlers.
    // These global handlers will then delegate to the active completers.

    jsPaymentResultHandlerGlobal = allowInterop((String? type, String? nonce, String? error) {
      debugPrint('JSInteropManager: Received payment result from JS - Type: $type, Nonce: ${nonce != null}, Error: $error');
      if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
        if (error != null) {
          if (error.toLowerCase() == "cancelled" || error.toLowerCase() == "user cancelled") {
            _paymentNonceCompleter!.complete(null); // Indicates cancellation
          } else {
            _paymentNonceCompleter!.completeError(Exception('Payment JS Error ($type): $error'));
          }
        } else if (nonce != null) {
          _paymentNonceCompleter!.complete(nonce);
        } else {
          // Should not happen if JS sends either nonce or error
          _paymentNonceCompleter!.completeError(Exception('Payment JS Error ($type): Unknown result - no nonce and no error.'));
        }
      } else {
        debugPrint('JSInteropManager: Received payment result but no active completer or completer already completed.');
      }
    });

    jsApplePayAvailabilityCallbackGlobal = allowInterop((bool isAvailable, String? reason) {
      debugPrint('JSInteropManager: Received Apple Pay availability from JS - Available: $isAvailable, Reason: $reason');
      if (_applePayAvailabilityCompleter != null && !_applePayAvailabilityCompleter!.isCompleted) {
        if (isAvailable) {
          _applePayAvailabilityCompleter!.complete(true);
        } else {
          _applePayAvailabilityCompleter!.complete(false);
        }
      } else {
        debugPrint('JSInteropManager: Received Apple Pay availability but no active completer or completer already completed.');
      }
    });
  }


  /// Checks if Apple Pay is available by calling a JavaScript function.
  Future<bool> checkApplePayAvailability(String clientToken) {
    if (_applePayAvailabilityCompleter != null && !_applePayAvailabilityCompleter!.isCompleted) {
      // Avoid starting a new check if one is already in progress
      return _applePayAvailabilityCompleter!.future;
    }
    _applePayAvailabilityCompleter = Completer<bool>();

    try {
      debugPrint('JSInteropManager: Calling _checkApplePayAvailabilityJS...');
      // The JS function `checkApplePayAvailabilityJS` will eventually call `jsApplePayAvailabilityCallbackGlobal`
      _checkApplePayAvailabilityJS(clientToken, allowInterop((bool isAvailable, String? reason) {
        if (!_applePayAvailabilityCompleter!.isCompleted) { // Check again before completing
          if (isAvailable) {
            _applePayAvailabilityCompleter!.complete(true);
          } else {
            debugPrint('JSInteropManager (checkApplePayAvailability callback): Apple Pay not available. Reason: $reason');
            _applePayAvailabilityCompleter!.complete(false);
          }
        }
      }));
    } catch (e) {
      debugPrint('JSInteropManager: Error calling _checkApplePayAvailabilityJS: $e');
      if (!_applePayAvailabilityCompleter!.isCompleted) {
        _applePayAvailabilityCompleter!.complete(false); // Assume not available if JS call itself fails
      }
    }
    return _applePayAvailabilityCompleter!.future;
  }

  /// Triggers the Apple Pay flow via JavaScript.
  /// Returns a Future that completes with the nonce string if successful,
  /// null if cancelled, or throws an error if failed.
  Future<String?> triggerApplePay(String clientToken, String amount, String currencyCode) {
    if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
      // Avoid starting a new payment if one is already in progress
      // Or, you might choose to cancel the previous one and start a new one
      debugPrint("JSInteropManager: Payment attempt already in progress.");
      return _paymentNonceCompleter!.future; // Or throw an error
    }
    _paymentNonceCompleter = Completer<String?>();

    try {
      debugPrint('JSInteropManager: Calling _triggerApplePayInJS with amount: $amount, currency: $currencyCode');
      // The JS function `initiateApplePayFromFlutter` (or `_triggerApplePayInJS`)
      // will eventually lead to `jsPaymentResultHandlerGlobal` being called.
      _triggerApplePayInJS(clientToken, amount, currencyCode);
    } catch (e) {
      debugPrint('JSInteropManager: Error calling _triggerApplePayInJS: $e');
      if (!_paymentNonceCompleter!.isCompleted) {
        _paymentNonceCompleter!.completeError(Exception('Failed to call JS for Apple Pay: $e'));
      }
    }
    return _paymentNonceCompleter!.future;
  }

  /// Triggers the Card Payment flow via JavaScript.
  /// (Conceptual - JS implementation for cards is needed in index.html)
  /// Returns a Future that completes with the nonce string if successful,
  /// null if cancelled, or throws an error if failed.
  Future<String?> triggerCardPayment(String clientToken /*, other card parameters if needed */) {
    if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
      debugPrint("JSInteropManager: Payment attempt already in progress.");
      return _paymentNonceCompleter!.future;
    }
    _paymentNonceCompleter = Completer<String?>();

    try {
      debugPrint('JSInteropManager: Calling _triggerCardPaymentInJS...');
      // The JS function `initiateCardPaymentInJS`
      // will eventually lead to `jsPaymentResultHandlerGlobal` being called.
      _triggerCardPaymentInJS(clientToken);
    } catch (e) {
      debugPrint('JSInteropManager: Error calling _triggerCardPaymentInJS: $e');
      if (!_paymentNonceCompleter!.isCompleted) {
        _paymentNonceCompleter!.completeError(Exception('Failed to call JS for Card Payment: $e'));
      }
    }
    return _paymentNonceCompleter!.future;
  }

  // Optional: A method to reset/cancel ongoing operations if needed
  void resetCurrentOperation() {
    if (_applePayAvailabilityCompleter != null && !_applePayAvailabilityCompleter!.isCompleted) {
      _applePayAvailabilityCompleter!.completeError(Exception("Operation cancelled by reset"));
    }
    _applePayAvailabilityCompleter = null;

    if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
      _paymentNonceCompleter!.completeError(Exception("Operation cancelled by reset"));
    }
    _paymentNonceCompleter = null;
    debugPrint("JSInteropManager: Operations reset.");
  }
}
