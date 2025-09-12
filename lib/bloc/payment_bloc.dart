// // import 'package:bloc/bloc.dart';
// //
// // import '../services/payment_service.dart';
// // import 'payment_event.dart';
// // import 'payment_state.dart';
// //
// // class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
// //   final PaymentService _service;
// //   late String _accessJwt;
// //   late String _clientToken;
// //
// //   PaymentBloc(this._service) : super(PaymentInitial()) {
// //     on<InitPaymentFlow>(_onInit);
// //     on<SubmitApplePay>(_onSubmitApplePay);
// //   }
// //
// //   Future<void> _onInit(
// //     InitPaymentFlow event,
// //     Emitter<PaymentState> emit,
// //   ) async {
// //     emit(PaymentLoading());
// //     try {
// //       _accessJwt = await _service.generateAccount();
// //       _clientToken = await _service.getClientToken(_accessJwt);
// //       emit(PaymentReady(clientToken: _clientToken));
// //     } catch (e) {
// //       emit(PaymentError(e.toString()));
// //     }
// //   }
// //
// //   Future<void> _onSubmitApplePay(
// //     SubmitApplePay event,
// //     Emitter<PaymentState> emit,
// //   ) async {
// //     emit(PaymentLoading());
// //     try {
// //       // 1) Add payment method
// //       final methodToken = await _service.addPaymentMethod(
// //         accessJwt: _accessJwt,
// //         paymentNonce: event.paymentNonce,
// //       );
// //
// //       // 2) Create subscription
// //       await _service.createSubscription(
// //         accessJwt: _accessJwt,
// //         methodToken: methodToken,
// //       );
// //
// //       // 3) Rent the power bank
// //       await _service.rentPowerBank(
// //         accessJwt: _accessJwt,
// //         cabinetId: event.stationId,
// //         connectionKey: event.stationId,
// //       );
// //
// //       emit(PaymentSuccess());
// //     } catch (e) {
// //       emit(PaymentError(e.toString()));
// //     }
// //   }
// // }
//
// // lib/bloc/payment_bloc.dart
//
// import 'dart:convert';
//
// import 'package:bloc/bloc.dart';
// import 'package:flutter_braintree/flutter_braintree.dart';
//
// import '../services/payment_service.dart';
// import 'payment_event.dart';
// import 'payment_state.dart';
//
// class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
//   final PaymentService _service;
//   late String _accessJwt;
//   late String _clientToken; // from your backend
//
//   PaymentBloc(this._service) : super(PaymentInitial()) {
//     on<InitPaymentFlow>(_onInit);
//     on<SubmitApplePay>(_onSubmitApplePay);
//   }
//
//   Future<void> _onInit(
//     InitPaymentFlow event,
//     Emitter<PaymentState> emit,
//   ) async {
//     emit(PaymentLoading());
//     try {
//       _accessJwt = await _service.generateAccount();
//       _clientToken = await _service.getClientToken(_accessJwt);
//       emit(PaymentReady(clientToken: _clientToken));
//     } catch (e) {
//       emit(PaymentError(e.toString()));
//     }
//   }
//
//   Future<void> _onSubmitApplePay(
//     SubmitApplePay event,
//     Emitter<PaymentState> emit,
//   ) async {
//     emit(PaymentLoading());
//     try {
//       // 1) First tokenize the Apple Pay token into a Braintree nonce
//       final applePayJsonString = event.paymentNonce;
//       final applePayData =
//           jsonDecode(applePayJsonString) as Map<String, dynamic>;
//
//       final request = BraintreeApplePayRequest(
//         paymentSummaryItems: applePayData['paymentSummaryItems'],
//         displayName: applePayData['displayName'],
//         currencyCode: applePayData['currencyCode'],
//         countryCode: applePayData['countryCode'],
//         merchantIdentifier: applePayData['merchantIdentifier'],
//         supportedNetworks: applePayData['supportedNetworks'],
//       );
//
//       final tokenizationResult = await Braintree.showCreditCardForm(
//         clientToken: _clientToken,
//         applePayRequest: request,
//       );
//
//       if (tokenizationResult == null) {
//         throw Exception('Apple Pay authorization was canceled by user.');
//       }
//
//       final braintreeNonce = tokenizationResult.nonce;
//
//       // 2) Vault that nonce on your backend
//       final methodToken = await _service.addPaymentMethod(
//         accessJwt: _accessJwt,
//         paymentNonce: braintreeNonce,
//       );
//
//       // 3) Create the subscription
//       await _service.createSubscription(
//         accessJwt: _accessJwt,
//         methodToken: methodToken,
//       );
//
//       // 4) Rent the power bank
//       await _service.rentPowerBank(
//         accessJwt: _accessJwt,
//         cabinetId: event.stationId,
//         connectionKey: event.stationId,
//       );
//
//       emit(PaymentSuccess());
//     } catch (e) {
//       emit(PaymentError(e.toString()));
//     }
//   }
// }

//******************

// lib/bloc/payment_bloc.dart


import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
// Ensure you have this import for BraintreeDropIn and related classes
import 'package:flutter_braintree/flutter_braintree.dart';
import 'package:equatable/equatable.dart';

import '../services/payment_service.dart';
part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _service;
  late String _accessJwt;
  late String _braintreeClientToken;

  PaymentBloc(this._service) : super(PaymentInitial()) {
    on<InitPaymentFlow>(_onInit);
    on<SubmitPaymentViaBraintreeDropIn>(
      _onSubmitPaymentViaBraintreeDropIn,
    ); // Renamed for clarity
  }

  Future<void> _onInit(
    InitPaymentFlow event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      _accessJwt = await _service.generateAccount();
      _braintreeClientToken = await _service.getClientToken(_accessJwt);
      if (_braintreeClientToken.isEmpty) {
        throw Exception("Received an empty Braintree client token.");
      }
      debugPrint('Received Braintree client token: $_braintreeClientToken'); //////////
      emit(PaymentReady(clientToken: _braintreeClientToken));
    } catch (e) {
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onSubmitPaymentViaBraintreeDropIn(
    SubmitPaymentViaBraintreeDropIn event,
    // Contains stationId, amount, currency
    Emitter<PaymentState> emit,
  ) async {
    if (_accessJwt.isEmpty || _braintreeClientToken.isEmpty) {
      emit(
        PaymentError(message: 'Access JWT or Braintree client token is empty.'),
      );
      return;
    }

    emit(PaymentLoading());
    try {
      // 1. Configure the BraintreeDropInRequest
      // This request includes Apple Pay configuration if you want it to be available
      final dropInRequest = BraintreeDropInRequest(
        clientToken: _braintreeClientToken,
        collectDeviceData: false, // Recommended for fraud prevention
        applePayRequest: BraintreeApplePayRequest(
          // Configure Apple Pay specific details
          paymentSummaryItems: [
            ApplePaySummaryItem(
              label: 'PowerBank Recharge',
              amount: double.parse(event.amount),
              type: ApplePaySummaryItemType.final_,
            ),
          ],
          displayName: 'PowerBank App',
          currencyCode: event.currencyCode,
          countryCode: 'US',
          // Or make dynamic
          merchantIdentifier: 'merchant.com.marikpetros',
          // CRITICAL
          supportedNetworks: [
            ApplePaySupportedNetworks.visa,
            ApplePaySupportedNetworks.masterCard,
            ApplePaySupportedNetworks.amex,
          ], // Optional
        ),
        // googlePayRequest: null, // Disable
        paypalRequest: null,    // Disable
        venmoEnabled: false,    // Disable
        cardEnabled: false,     // Disable
      );
                                                                 /// stex hasel a  amount-y null a
      // 2. Show Braintree Drop-in UI
      final BraintreeDropInResult? result = await BraintreeDropIn.start(
        dropInRequest,
      );

      debugPrint('🔔 BraintreeDropInResult: $result');

      if (result == null ||
          result.paymentMethodNonce.nonce.isEmpty) {
        // User cancelled or an error occurred
        emit(
          PaymentReady(clientToken: _braintreeClientToken),
        ); // Or a specific cancelled state
        return;
      }

      final String braintreePaymentMethodNonce =
          result.paymentMethodNonce.nonce;
      // final String? deviceData = result.deviceData; // Useful for fraud tools

      // 3. Add payment method using the Braintree Nonce
      final methodToken = await _service.addPaymentMethod(
        accessJwt: _accessJwt,
        paymentNonce: braintreePaymentMethodNonce,
        // Potentially add deviceData to your backend call if Braintree recommends it
      );

      // 4. Create subscription
      await _service.createSubscription(
        accessJwt: _accessJwt,
        methodToken: methodToken,
      );

      // 5. Rent the power bank
      await _service.rentPowerBank(
        accessJwt: _accessJwt,
        cabinetId: event.stationId,
        connectionKey: event.stationId,
      );

      emit(PaymentSuccess());
    } on TimeoutException catch (e, s) {
      debugPrint('PaymentBloc: BraintreeDropIn.start() TIMED OUT: $e');
      debugPrint('PaymentBloc: Timeout STACKTRACE: $s');
      emit(PaymentError(message: 'Payment process timed out. Please check your connection and try again.'));
    }
    catch (e, stackTrace) {
      // Add stackTrace
      debugPrint(
        ' PaymentBloc ERROR during backend processing: $e',
      ); // Make the print distinctive
      debugPrint(' PaymentBloc STACKTRACE: $stackTrace');
      emit(PaymentError(message: e.toString()));
    }
  }
}
//^&*(^&*&(*&*&^&^%^$$^&%#####################################
// import 'dart:async';
// import 'package:bloc/bloc.dart';
// import 'package:equatable/equatable.dart';
// import 'package:flutter/foundation.dart'; // For debugPrint
// // Import from the new package
// import 'package:braintree_flutter_plus/braintree_flutter_plus.dart';
//
// import '../services/payment_service.dart';
// // Assuming payment_event.dart and payment_state.dart are in the same directory or adjust path
// part 'payment_event.dart';
// part 'payment_state.dart';
//
// class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
//   final PaymentService _service;
//   late String _accessJwt;
//   late String _braintreeClientToken;
//   bool _isApplePayAvailable = false; // Store Apple Pay availability
//
//   PaymentBloc(this._service) : super(PaymentInitial()) {
//     on<InitPaymentFlow>(_onInitPaymentFlow);
//     on<RequestApplePayPayment>(_onRequestApplePayPayment);
//     on<RequestCardPayment>(_onRequestCardPayment);
//     // on<StartBraintreePayment>(_onStartBraintreePayment); // General event if needed
//   }
//
//   Future<void> _onInitPaymentFlow(
//       InitPaymentFlow event,
//       Emitter<PaymentState> emit,
//       ) async {
//     emit(const PaymentLoading(message: 'Initializing payment...'));
//     try {
//       _accessJwt = await _service.generateAccount();
//       _braintreeClientToken = await _service.getClientToken(_accessJwt);
//
//       if (_braintreeClientToken.isEmpty) {
//         throw Exception("Received an empty Braintree client token.");
//       }
//
//       // Check for Apple Pay availability using braintree_flutter_plus
//       // This is usually a synchronous check or a quick async check
//       try {
//         // braintree_flutter_plus might have a method like this.
//         // The exact method name might vary, check package docs.
//         // It might not need the client token for this check.
//         _isApplePayAvailable = await Braintree.isApplePayAvailable();
//         debugPrint('Apple Pay Available (braintree_flutter_plus): $_isApplePayAvailable');
//       } catch (e) {
//         debugPrint('Error checking Apple Pay availability: $e');
//         _isApplePayAvailable = false; // Assume not available if check fails
//       }
//
//       emit(PaymentReady(
//         braintreeClientToken: _braintreeClientToken,
//         isApplePayAvailable: _isApplePayAvailable,
//       ));
//     } catch (e) {
//       debugPrint('Error in InitPaymentFlow: $e');
//       emit(PaymentError(message: e.toString()));
//     }
//   }
//
//   Future<void> _onRequestApplePayPayment(
//       RequestApplePayPayment event,
//       Emitter<PaymentState> emit,
//       ) async {
//     if (!_isApplePayAvailable) {
//       emit(const PaymentError(message: 'Apple Pay is not available on this device or not configured.'));
//       // Re-emit PaymentReady so UI can show alternatives
//       await Future.delayed(const Duration(milliseconds: 50)); // Small delay to allow error state to be processed
//       emit(PaymentReady(braintreeClientToken: _braintreeClientToken, isApplePayAvailable: _isApplePayAvailable));
//       return;
//     }
//     if (_braintreeClientToken.isEmpty) {
//       emit(const PaymentError(message: 'Braintree client token is missing. Please initialize first.'));
//       return;
//     }
//
//     emit(const PaymentLoading(message: 'Processing Apple Pay...'));
//     try {
//       // 1. Create the Apple Pay request for braintree_flutter_plus
//       final applePayRequest = BraintreeApplePayRequest(
//         currencyCode: event.currencyCode,
//         countryCode: 'US', // Or make dynamic if necessary
//         displayName: 'PowerBank App', // Your company name
//         merchantIdentifier: 'merchant.com.marikpetros', // CRITICAL: Your registered Merchant ID
//         paymentSummaryItems: [
//           ApplePaySummaryItem(
//             label: 'PowerBank Recharge', // Or a more descriptive label
//             amount: double.parse(event.amount), // braintree_flutter_plus might want double
//             type: ApplePaySummaryItemType.final_, // Or other types as needed
//           ),
//         ],
//         supportedNetworks: [ // Usually not needed, Braintree determines from capabilities
//           ApplePaySupportedNetworks.visa,
//           ApplePaySupportedNetworks.masterCard,
//         ],
//       );
//
//       // 2. Request Apple Pay payment
//       // The method name in `braintree_flutter_plus` might be `Braintree.requestApplePayNonce`
//       // or similar. It will likely take the clientToken (authorization) and the request.
//       // The exact API might differ, consult `braintree_flutter_plus` documentation.
//       // Example based on common patterns:
//       final BraintreePaymentMethodNonce? nonceResult =
//       await Braintree.requestApplePayNonce(
//         authorization: _braintreeClientToken, // or clientToken:
//         request: applePayRequest,
//       );
//
//
//       if (nonceResult == null || nonceResult.nonce.isEmpty) {
//         debugPrint('Apple Pay was cancelled or failed to produce a nonce.');
//         emit(PaymentCancelled()); // Or emit PaymentReady again
//         // Re-emit PaymentReady so UI can recover
//         await Future.delayed(const Duration(milliseconds: 50));
//         emit(PaymentReady(braintreeClientToken: _braintreeClientToken, isApplePayAvailable: _isApplePayAvailable));
//         return;
//       }
//
//       final String braintreeNonce = nonceResult.nonce;
//       debugPrint('Received Apple Pay Nonce (braintree_flutter_plus): $braintreeNonce');
//
//       await _processPaymentNonce(
//         nonce: braintreeNonce,
//         stationId: event.stationId,
//         isApplePay: true,
//         // deviceData: nonceResult.deviceData, // Check if deviceData is available in this package's result
//         emit: emit,
//       );
//
//     } on TimeoutException catch (e, s) {
//       debugPrint('Apple Pay Request TIMED OUT: $e\n$s');
//       emit(const PaymentError(message: 'Apple Pay process timed out. Please try again.'));
//     } catch (e, s) {
//       debugPrint('Error during Apple Pay request: $e\n$s');
//       emit(PaymentError(message: e.toString()));
//     }
//   }
//
//   Future<void> _onRequestCardPayment(
//       RequestCardPayment event,
//       Emitter<PaymentState> emit,
//       ) async {
//     if (_braintreeClientToken.isEmpty) {
//       emit(const PaymentError(message: 'Braintree client token is missing. Please initialize first.'));
//       return;
//     }
//     emit(const PaymentLoading(message: 'Processing Card Payment...'));
//     try {
//       // 1. Create a card request.
//       // `braintree_flutter_plus` might use `BraintreeCreditCardRequest` or similar.
//       // This often just involves showing a form and getting the details.
//       // The actual tokenization usually happens when the form is submitted.
//       // Or it might be a direct call if you have card details (not recommended for PCI).
//       //
//       // Let's assume `braintree_flutter_plus` has a method to show a card form:
//       // This is a common pattern for such libraries.
//       // Example: Braintree.showCardForm() or similar.
//       //
//       // `braintree_flutter_plus` often uses `Braintree.tokenizeCreditCard`
//       // after you've collected card details using your own UI or a provided form.
//       // For simplicity here, let's assume it has a method to pop up a Braintree card form
//       // similar to how Drop-in works but just for cards.
//       // If not, you'd build your own card form and use `Braintree.tokenizeCreditCard`.
//
//       // A common way with `braintree_flutter_plus` is to use `Braintree.showCreditCardForm`
//       final BraintreePaymentMethodNonce? nonceResult = await Braintree.showCreditCardForm(
//         authorization: _braintreeClientToken, // or clientToken:
//         amount: '4.99',
//         // You might need to pass a BraintreeCardRequest for 3DS or other options
//         // request: BraintreeCardRequest( /* ... card details if you have them, or for 3DS setup ... */ )
//       );
//
//       if (nonceResult == null || nonceResult.nonce.isEmpty) {
//         debugPrint('Card payment was cancelled or failed to produce a nonce.');
//         emit(PaymentCancelled());
//         // Re-emit PaymentReady so UI can recover
//         await Future.delayed(const Duration(milliseconds: 50));
//         emit(PaymentReady(braintreeClientToken: _braintreeClientToken, isApplePayAvailable: _isApplePayAvailable));
//         return;
//       }
//
//       final String braintreeNonce = nonceResult.nonce;
//       debugPrint('Received Card Nonce (braintree_flutter_plus): $braintreeNonce');
//
//       await _processPaymentNonce(
//         nonce: braintreeNonce,
//         stationId: event.stationId,
//         isApplePay: false,
//         deviceData: nonceResult.deviceData,
//         emit: emit,
//       );
//
//     } on TimeoutException catch (e, s) {
//       debugPrint('Card Payment Request TIMED OUT: $e\n$s');
//       emit(const PaymentError(message: 'Card payment process timed out. Please try again.'));
//     } catch (e, s) {
//       debugPrint('Error during Card Payment request: $e\n$s');
//       emit(PaymentError(message: e.toString()));
//     }
//   }
//
//   // Helper method to process the nonce with your backend
//   Future<void> _processPaymentNonce({
//     required String nonce,
//     required String stationId,
//     required bool isApplePay,
//     String? deviceData, // Optional device data
//     required Emitter<PaymentState> emit,
//   }) async {
//     try {
//       final methodToken = await _service.addPaymentMethod(
//         accessJwt: _accessJwt,
//         paymentNonce: nonce,
//         description: isApplePay ? 'Apple Pay Recharge' : 'Card Recharge',
//         paymentType: isApplePay ? 'APPLE_PAY' : 'CREDIT_CARD', // Adjust paymentType if needed
//         // You might want to send deviceData to your backend if your Braintree setup uses it
//       );
//
//       await _service.createSubscription(
//         accessJwt: _accessJwt,
//         methodToken: methodToken,
//         // Potentially add planId from an event or config
//       );
//
//       await _service.rentPowerBank(
//         accessJwt: _accessJwt,
//         cabinetId: stationId,
//         connectionKey: stationId, // Assuming this is correct
//       );
//
//       emit(PaymentSuccess());
//     } catch (e, s) {
//       // Catch specific DioErrors if you want to inspect statusCode or response data
//       debugPrint('Error processing payment nonce with backend: $e\n$s');
//       emit(PaymentError(message: 'Backend processing failed: ${e.toString()}'));
//     }
//   }
// }
