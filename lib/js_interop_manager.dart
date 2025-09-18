// // lib/js_interop_manager.dart
//
// import 'dart:async';
// import 'dart:js_interop'; // Main package for JS interop
// // Import the extension methods for JSObject
// import 'dart:js_interop_unsafe'; // For object properties by name, if needed, but setProperty is on JSObjectUtilExtension
//
// import 'package:flutter/foundation.dart' show debugPrint;
//
//
// // --- Define Dart interfaces for JS functions that exist in your index.html ---
// @JS('checkApplePayAvailabilityJS')
// external void _checkApplePayAvailabilityJS(JSString clientToken, JSFunction callback);
//
// @JS('initiateApplePayFromFlutter')
// external void _initiateApplePayFromFlutter(JSString clientToken, JSString amount, JSString currencyCode);
//
// @JS('initiateCardPaymentInJS')
// external void _initiateCardPaymentInJS(JSString clientToken);
//
//
// // --- JSInteropManager Class ---
// class JSInteropManager {
//   Completer<bool>? _applePayAvailabilityCompleter;
//   Completer<String?>? _paymentNonceCompleter;
//
//   JSInteropManager() {
//     _initializeGlobalCallbacks();
//   }
//
//   void _initializeGlobalCallbacks() {
//     // These Dart functions become callable from JS.
//     // allowInterop is a top-level function from dart:js_interop.
//
//     final paymentResultCallback = allowInterop(
//             (JSString? typeJS, JSString? nonceJS, JSString? errorJS) {
//           final type = typeJS?.toDart;
//           final nonce = nonceJS?.toDart;
//           final error = errorJS?.toDart;
//
//           debugPrint('JSInteropManager (dart:js_interop): Received payment result from JS - Type: $type, Nonce: ${nonce != null}, Error: $error');
//           if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
//             if (error != null && error.isNotEmpty) {
//               if (error.toLowerCase() == "cancelled" || error.toLowerCase() == "user cancelled") {
//                 _paymentNonceCompleter!.complete(null);
//               } else {
//                 _paymentNonceCompleter!.completeError(Exception('Payment JS Error ($type): $error'));
//               }
//             } else if (nonce != null && nonce.isNotEmpty) {
//               _paymentNonceCompleter!.complete(nonce);
//             } else {
//               _paymentNonceCompleter!.completeError(Exception('Payment JS Error ($type): Unknown result - no nonce and no error.'));
//             }
//           } else {
//             debugPrint('JSInteropManager (dart:js_interop): Received payment result but no active completer.');
//           }
//         });
//
//     final applePayAvailabilityCallback = allowInterop(
//             (JSBoolean isAvailableJS, JSString? reasonJS) {
//           final isAvailable = isAvailableJS.toDart;
//           final reason = reasonJS?.toDart;
//
//           debugPrint('JSInteropManager (dart:js_interop): Received Apple Pay availability - Available: $isAvailable, Reason: $reason');
//           if (_applePayAvailabilityCompleter != null && !_applePayAvailabilityCompleter!.isCompleted) {
//             _applePayAvailabilityCompleter!.complete(isAvailable);
//           } else {
//             debugPrint('JSInteropManager (dart:js_interop): Received Apple Pay availability but no active completer.');
//           }
//         });
//
//     // Use the setProperty extension method from dart:js_interop on JSObject.
//     // globalContext is a JSObject representing the global JS scope (window).
//     globalContext.setProperty('flutterPaymentResultHandlerGlobal'.toJS, paymentResultCallback.toJS);
//     globalContext.setProperty('flutterApplePayAvailabilityCallbackGlobal'.toJS, applePayAvailabilityCallback.toJS);
//
//     debugPrint("JSInteropManager (dart:js_interop): Global JS callbacks initialized.");
//   }
//
//   Future<bool> checkApplePayAvailability(String clientToken) {
//     if (_applePayAvailabilityCompleter != null && !_applePayAvailabilityCompleter!.isCompleted) {
//       debugPrint("JSInteropManager (dart:js_interop): Apple Pay availability check already in progress.");
//       return _applePayAvailabilityCompleter!.future;
//     }
//     _applePayAvailabilityCompleter = Completer<bool>();
//
//     try {
//       debugPrint('JSInteropManager (dart:js_interop): Calling _checkApplePayAvailabilityJS...');
//       // Get the globally set callback using globalContext.getProperty
//       final jsCallbackForApplePay = globalContext.getProperty('flutterApplePayAvailabilityCallbackGlobal'.toJS);
//
//       if (jsCallbackForApplePay.isA<JSFunction>()) {
//         _checkApplePayAvailabilityJS(clientToken.toJS, jsCallbackForApplePay as JSFunction);
//       } else {
//         final errorMessage = "JSInteropManager (dart:js_interop): flutterApplePayAvailabilityCallbackGlobal is not a JSFunction on window.";
//         debugPrint(errorMessage);
//         if (!_applePayAvailabilityCompleter!.isCompleted) {
//           _applePayAvailabilityCompleter!.completeError(Exception(errorMessage));
//         }
//       }
//     } catch (e, s) {
//       debugPrint('JSInteropManager (dart:js_interop): Error calling _checkApplePayAvailabilityJS: $e\n$s');
//       if (_applePayAvailabilityCompleter != null && !_applePayAvailabilityCompleter!.isCompleted) {
//         _applePayAvailabilityCompleter!.completeError(Exception("Failed to call JS for Apple Pay availability: $e"));
//       }
//     }
//     return _applePayAvailabilityCompleter!.future;
//   }
//
//   Future<String?> triggerApplePay(String clientToken, String amount, String currencyCode) {
//     if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
//       debugPrint("JSInteropManager (dart:js_interop): Payment attempt already in progress.");
//       return _paymentNonceCompleter!.future;
//     }
//     _paymentNonceCompleter = Completer<String?>();
//
//     try {
//       debugPrint('JSInteropManager (dart:js_interop): Calling _initiateApplePayFromFlutter with amount: $amount, currency: $currencyCode');
//       _initiateApplePayFromFlutter(clientToken.toJS, amount.toJS, currencyCode.toJS);
//     } catch (e, s) {
//       debugPrint('JSInteropManager (dart:js_interop): Error calling _initiateApplePayFromFlutter: $e\n$s');
//       if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
//         _paymentNonceCompleter!.completeError(Exception('Failed to call JS for Apple Pay: $e'));
//       }
//     }
//     return _paymentNonceCompleter!.future;
//   }
//
//   Future<String?> triggerCardPayment(String clientToken) {
//     if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
//       debugPrint("JSInteropManager (dart:js_interop): Payment attempt already in progress.");
//       return _paymentNonceCompleter!.future;
//     }
//     _paymentNonceCompleter = Completer<String?>();
//
//     try {
//       debugPrint('JSInteropManager (dart:js_interop): Calling _initiateCardPaymentInJS...');
//       _initiateCardPaymentInJS(clientToken.toJS);
//     } catch (e,s) {
//       debugPrint('JSInteropManager (dart:js_interop): Error calling _initiateCardPaymentInJS: $e\n$s');
//       if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
//         _paymentNonceCompleter!.completeError(Exception('Failed to call JS for Card Payment: $e'));
//       }
//     }
//     return _paymentNonceCompleter!.future;
//   }
//
//   void resetCurrentOperation() {
//     if (_applePayAvailabilityCompleter != null && !_applePayAvailabilityCompleter!.isCompleted) {
//       _applePayAvailabilityCompleter!.completeError(Exception("Operation cancelled by reset"));
//     }
//     _applePayAvailabilityCompleter = null;
//
//     if (_paymentNonceCompleter != null && !_paymentNonceCompleter!.isCompleted) {
//       _paymentNonceCompleter!.completeError(Exception("Operation cancelled by reset"));
//     }
//     _paymentNonceCompleter = null;
//     debugPrint("JSInteropManager (dart:js_interop): Operations reset.");
//   }
// }
//
