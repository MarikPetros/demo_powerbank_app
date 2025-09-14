// payment_bloc.dart
import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb and debugPrint
import 'package:powerbank_app/js_interop_manager.dart';

import '../services/payment_service.dart';
// Conditionally import the web interop or a placeholder for non-web
import 'web_apple_pay_interop.dart'
    if (dart.library.html) 'web_apple_pay_interop.dart'
    if (dart.library.io) 'web_apple_pay_stub.dart';

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService service;
  late String _accessJwt;
  final JSInteropManager jsInteropManager;
  late String _braintreeClientToken;

  // bool _isApplePayAvailableOnWeb = false; // JS will determine this

  // Instance of our interop wrapper
  final WebApplePay _webApplePay = WebApplePay();

  PaymentBloc({required this.service, required this.jsInteropManager})
    : super(PaymentInitial()) {
    on<InitPaymentFlow>(_onInitPaymentFlow);
    on<RequestApplePayPayment>(
      _onRequestApplePayPaymentViaWeb,
    ); // Renamed event handler
    on<RequestCardPayment>(
      _onRequestCardPaymentViaWeb,
    ); // Renamed event handler
    on<ProcessPaymentNonceEvent>(_onProcessPaymentNonce); // New event
  }

  Future<void> _onInitPaymentFlow(
    InitPaymentFlow event,
    Emitter<PaymentState> emit,
  ) async {
    emit(const PaymentLoading(message: 'Initializing payment...'));
    try {
      _accessJwt = await service.generateAccount();
      _braintreeClientToken = await service.getClientToken(_accessJwt);

      if (_braintreeClientToken.isEmpty) {
        throw Exception("Braintree client token is empty.");
      }

      // For web, Apple Pay availability is checked by the JS SDK when payment is attempted.
      // We can assume it *might* be available if on Safari.
      // The `isApplePayAvailable` in PaymentReady can signify if the *option* should be shown.
      // The actual JS call will confirm.
      bool shouldShowApplePayOption = true; // Optimistically show on web
      bool actualApplePayAvailable = false;
      if (kIsWeb) {
        debugPrint(
          "PaymentBloc: Running on Web. Checking Apple Pay availability via JS...",
        );
        try {
          actualApplePayAvailable = await jsInteropManager.checkApplePayAvailability(
            _braintreeClientToken,
          );
        } catch (e) {
          debugPrint(
            "PaymentBloc: Error checking web Apple Pay availability: $e",
          );
          actualApplePayAvailable = false;
        }
      }
      var _isApplePayAvailableOnWeb =
          actualApplePayAvailable; // Store this state

      emit(
        PaymentReady(
          braintreeClientToken: _braintreeClientToken,
          isApplePayAvailable: _isApplePayAvailableOnWeb,
        ),
      );
      // if (kIsWeb) {
      //   // You could try a preliminary JS check here if you want, but
      //   // Braintree's `canMakePaymentsWithActiveCard` is more robust before session.begin()
      //   debugPrint("PaymentBloc: Running on Web. Apple Pay option will be shown.");
      // }
      //
      //
      // emit(PaymentReady(
      //   braintreeClientToken: _braintreeClientToken,
      //   isApplePayAvailable: shouldShowApplePayOption,
      // ));
    } catch (e, s) {
      debugPrint('Error in InitPaymentFlow: $e\n$s');
      emit(PaymentError(message: e.toString()));
    }
  }

  Future<void> _onRequestApplePayPaymentViaWeb(
    RequestApplePayPayment event,
    Emitter<PaymentState> emit,
  ) async {
    if (!kIsWeb) {
      emit(
        const PaymentError(
          message: 'Apple Pay via Web JS is only supported on Flutter Web.',
        ),
      );
      // Potentially revert to PaymentReady state
      await Future.delayed(const Duration(milliseconds: 50));
      emit(
        PaymentReady(
          braintreeClientToken: _braintreeClientToken,
          isApplePayAvailable: false,
        ),
      );
      return;
    }

    if (_braintreeClientToken.isEmpty) {
      emit(const PaymentError(message: 'Braintree client token is missing.'));
      return;
    }

    emit(const PaymentLoading(message: 'Processing Apple Pay via Web...'));
    try {
      // Call the web interop method
      // final String? nonce = await _webApplePay.startApplePay(_braintreeClientToken);
      final String? nonce = await jsInteropManager.triggerApplePay(
        _braintreeClientToken,
        event.amount,
        event.currencyCode,
      );
      if (nonce != null) {
        add(
          ProcessPaymentNonceEvent(
            nonce: nonce,
            stationId: event.stationId,
            isApplePay: true,
            deviceData:
                null /* JS flow might not easily provide deviceData here without dataCollector */,
          ),
        );
      } else if (nonce == null || nonce.isEmpty) {
        // This case is now handled by the completer erroring or completing with null for cancellation
        debugPrint(
          'Apple Pay was cancelled or failed to produce a nonce (web).',
        );
        emit(PaymentCancelled());
        await Future.delayed(const Duration(milliseconds: 50));
        emit(
          PaymentReady(
            braintreeClientToken: _braintreeClientToken,
            isApplePayAvailable: true,
          ),
        ); // Or check again
        return;
      }

      debugPrint('Received Apple Pay Nonce (Web): $nonce');

      // Device data for Apple Pay on the Web is typically collected by Braintree's JS SDK
      // and associated with the transaction on their backend if `dataCollector` is set up.
      // It's not usually passed explicitly with the nonce from this JS flow.
      // If your backend *requires* deviceData, you'd need to set up Braintree's DataCollector.js
      // and send its result alongside the nonce. For now, we'll assume it's not strictly needed
      // or handled by Braintree's JS SDK automatically if configured in your Braintree account.
      // String? deviceDataForBackend = null;
      //
      // await _processPaymentNonce(
      //   nonce: nonce,
      //   stationId: event.stationId,
      //   isApplePay: true,
      //   deviceData: deviceDataForBackend,
      //   emit: emit,
      // );
    } on TimeoutException catch (e, s) {
      debugPrint('Apple Pay Web Request TIMED OUT: $e\n$s');
      emit(const PaymentError(message: 'Apple Pay process timed out.'));
    } catch (e, s) {
      debugPrint('Error during Apple Pay Web request: $e\n$s');
      emit(
        PaymentError(message: e.toString()),
      ); // The completer in WebApplePay will throw
    }
  }

  // _onRequestCardPayment would need a similar web interop if using Braintree.js for cards.
  Future<void> _onRequestCardPaymentViaWeb(RequestCardPayment event, Emitter<PaymentState> emit) async {
    if (!kIsWeb) { /* handle error */ return; }
    emit(PaymentLoading(message: "Processing Card Payment..."));
    try {
      // Similar to Apple Pay, jsInteropManager would trigger Braintree.js Hosted Fields or Card Form
      final String? nonce = await jsInteropManager.triggerCardPayment(_braintreeClientToken /*, other params if needed */);
      if (nonce != null) {
        add(ProcessPaymentNonceEvent(nonce: nonce, stationId: event.stationId, isApplePay: false, deviceData: null /* JS flow might not easily provide deviceData here without dataCollector */));
      } else {
        emit(PaymentCancelled());
        // Re-emit PaymentReady
      }
    } catch (e) {
      emit(PaymentError(message: e.toString()));
      // Re-emit PaymentReady
    }
  }


  Future<void> _onProcessPaymentNonce(ProcessPaymentNonceEvent event, Emitter<PaymentState> emit) async {
    // This method remains the same
    // ... (your existing backend communication logic) ...
    emit(const PaymentLoading(message: "Finalizing payment..."));
    try {
      final methodToken = await service.addPaymentMethod(
        accessJwt: _accessJwt,
        paymentNonce: event.nonce,
        description:  event.isApplePay
            ? 'Apple Pay Recharge (Web)'
            : 'Card Recharge (Web)',
        paymentType: event.isApplePay ? 'APPLE_PAY' : 'CREDIT_CARD',
        // deviceData: deviceData, // Send if you have it and backend expects it
      );

      await service.createSubscription(
        accessJwt: _accessJwt,
        methodToken: methodToken /* planId from event/config */,
      );
      await service.rentPowerBank(
        accessJwt: _accessJwt,
        cabinetId: event.stationId,
        connectionKey: event.stationId,
      );
      emit(PaymentSuccess());
    } catch (e, s) {
      debugPrint('Error processing payment nonce with backend: $e\n$s');
      emit(PaymentError(message: 'Backend Error: ${e.toString()}'));
    }
  }
}

// Define a new event for when a nonce is received from JS
class ProcessPaymentNonceEvent extends PaymentEvent {
  final String nonce;
  final String stationId;
  final bool isApplePay;
  final String? deviceData; // Optional

  const ProcessPaymentNonceEvent({
    required this.nonce,
    required this.stationId,
    required this.isApplePay,
    this.deviceData,
  });

  @override
  List<Object?> get props => [nonce, stationId, isApplePay, deviceData];
}