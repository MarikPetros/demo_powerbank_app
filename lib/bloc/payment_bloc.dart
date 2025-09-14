import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;

// Assuming these are your service and JS interop manager paths
import '../services/payment_service.dart';
import '../js_interop_manager.dart'; // Your JS Interop Manager

part 'payment_event.dart';
part 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _paymentService;
  final JSInteropManager _jsInteropManager;

  String? _accessJwt;
  String? _braintreeClientToken;
  String? _currentStationId; // To store stationId for processing nonce

  // Constants for payment details (could also come from event or config)
  static const String paymentAmount = "4.99";
  static const String currencyCode = "USD"; // Example, ensure this matches Braintree setup

  PaymentBloc({
    required PaymentService paymentService,
    required JSInteropManager jsInteropManager,
  })  : _paymentService = paymentService,
        _jsInteropManager = jsInteropManager,
        super(PaymentInitial()) {
    on<InitPaymentFlow>(_onInitPaymentFlow);
    on<RequestApplePayPaymentViaWeb>(_onRequestApplePayPaymentViaWeb);
    on<RequestCardPaymentViaWeb>(_onRequestCardPaymentViaWeb);
    on<ProcessPaymentNonce>(_onProcessPaymentNonce);
  }

  Future<void> _onInitPaymentFlow(
      InitPaymentFlow event,
      Emitter<PaymentState> emit,
      ) async {
    emit(const PaymentLoading(message: 'Initializing...'));
    _currentStationId = event.stationId; // Store station ID
    try {
      _accessJwt = await _paymentService.generateAccount();
      if (_accessJwt == null || _accessJwt!.isEmpty) {
        throw Exception("Failed to generate account (JWT is missing).");
      }

      _braintreeClientToken = await _paymentService.getClientToken(_accessJwt!);
      if (_braintreeClientToken == null || _braintreeClientToken!.isEmpty) {
        throw Exception("Braintree client token is empty.");
      }

      bool applePayAvailable = false;
      if (kIsWeb) {
        try {
          debugPrint("PaymentBloc: Checking Apple Pay availability via JS...");
          applePayAvailable = await _jsInteropManager.checkApplePayAvailability(_braintreeClientToken!);
          debugPrint("PaymentBloc: Apple Pay available (JS Check): $applePayAvailable");
        } catch (e) {
          debugPrint("PaymentBloc: Error checking web Apple Pay availability: $e");
          // Proceed with applePayAvailable = false
        }
      }

      emit(PaymentReady(
        clientToken: _braintreeClientToken!,
        isApplePayAvailable: applePayAvailable,
      ));
    } catch (e, s) {
      debugPrint('Error in InitPaymentFlow: $e\n$s');
      emit(PaymentError(message: "Initialization failed: ${e.toString()}"));
    }
  }

  Future<void> _onRequestApplePayPaymentViaWeb(
      RequestApplePayPaymentViaWeb event,
      Emitter<PaymentState> emit,
      ) async {
    if (!kIsWeb) {
      emit(const PaymentError(message: 'Apple Pay (Web) is only supported on Flutter Web.'));
      _reEmitPaymentReady(emit, isApplePayAvailable: false); // Re-emit ready state
      return;
    }

    if (_braintreeClientToken == null) {
      emit(const PaymentError(message: 'Braintree client token is missing. Please initialize first.'));
      return;
    }
    _currentStationId = event.stationId; // Update station ID if necessary

    emit(const PaymentProcessing(message: 'Contacting Apple Pay...'));
    try {
      final String? nonce = await _jsInteropManager.triggerApplePay(
        _braintreeClientToken!,
        event.amount, // Use amount from event
        event.currencyCode, // Use currency from event
      );

      if (nonce != null && nonce.isNotEmpty) {
        debugPrint('PaymentBloc: Received Apple Pay Nonce (Web): $nonce');
        add(ProcessPaymentNonce(
          nonce: nonce,
          stationId: _currentStationId!, // Use stored stationId
          isApplePay: true,
        ));
      } else {
        debugPrint('PaymentBloc: Apple Pay was cancelled or failed to produce a nonce (web).');
        emit(PaymentCancelled());
        _reEmitPaymentReady(emit, isApplePayAvailable: (state is PaymentReady) ? (state as PaymentReady).isApplePayAvailable : false);
      }
    } catch (e, s) {
      debugPrint('Error during Apple Pay Web request: $e\n$s');
      emit(PaymentError(message: "Apple Pay failed: ${e.toString()}"));
      _reEmitPaymentReady(emit, isApplePayAvailable: (state is PaymentReady) ? (state as PaymentReady).isApplePayAvailable : false);
    }
  }

  Future<void> _onRequestCardPaymentViaWeb(
      RequestCardPaymentViaWeb event,
      Emitter<PaymentState> emit,
      ) async {
    if (!kIsWeb) {
      emit(const PaymentError(message: 'Card Payment (Web) is only supported on Flutter Web.'));
      _reEmitPaymentReady(emit, isApplePayAvailable: (state is PaymentReady) ? (state as PaymentReady).isApplePayAvailable : false);
      return;
    }
    if (_braintreeClientToken == null) {
      emit(const PaymentError(message: 'Braintree client token is missing. Please initialize first.'));
      return;
    }
    _currentStationId = event.stationId; // Update station ID

    emit(const PaymentProcessing(message: 'Processing Card Details...'));
    try {
      // Amount and currency might not be directly passed to triggerCardPayment if
      // your JS card form (e.g., Hosted Fields) doesn't need them for initiation.
      // The actual transaction amount is usually set on the server-side when using the nonce.
      final String? nonce = await _jsInteropManager.triggerCardPayment(_braintreeClientToken!);

      if (nonce != null && nonce.isNotEmpty) {
        debugPrint('PaymentBloc: Received Card Nonce (Web): $nonce');
        add(ProcessPaymentNonce(
          nonce: nonce,
          stationId: _currentStationId!,
          isApplePay: false,
        ));
      } else {
        debugPrint('PaymentBloc: Card payment was cancelled or failed to produce a nonce (web).');
        emit(PaymentCancelled());
        _reEmitPaymentReady(emit, isApplePayAvailable: (state is PaymentReady) ? (state as PaymentReady).isApplePayAvailable : false);
      }
    } catch (e, s) {
      debugPrint('Error during Card Payment Web request: $e\n$s');
      emit(PaymentError(message: "Card payment failed: ${e.toString()}"));
      _reEmitPaymentReady(emit, isApplePayAvailable: (state is PaymentReady) ? (state as PaymentReady).isApplePayAvailable : false);
    }
  }

  Future<void> _onProcessPaymentNonce(
      ProcessPaymentNonce event,
      Emitter<PaymentState> emit,
      ) async {
    emit(const PaymentProcessing(message: 'Finalizing payment...'));
    try {
      if (_accessJwt == null) {
        throw Exception("Authentication token is missing.");
      }
      if (_currentStationId == null) { // Ensure stationId is available
        throw Exception("Station ID is missing for processing payment.");
      }

      final methodToken = await _paymentService.addPaymentMethod(
        accessJwt: _accessJwt!,
        paymentNonce: event.nonce,
        description: event.isApplePay ? 'Apple Pay Subscription (Web)' : 'Card Subscription (Web)',
        paymentType: event.isApplePay ? 'APPLE_PAY' : 'CREDIT_CARD',
        // deviceData: event.deviceData, // Pass if available and needed
      );

      // Assuming planId "tss2" is fixed for this flow as per requirements
      await _paymentService.createSubscription(
        accessJwt: _accessJwt!,
        methodToken: methodToken,
        planId: "tss2", // Fixed plan ID from requirements
      );

      // Assuming cabinetId and connectionKey are the same as stationId for rentPowerBank
      await _paymentService.rentPowerBank(
        accessJwt: _accessJwt!,
        cabinetId: _currentStationId!, // Use stored stationId
        connectionKey: _currentStationId!, // Use stored stationId
      );

      emit(PaymentSuccess());
    } catch (e, s) {
      debugPrint('Error processing payment nonce with backend: $e\n$s');
      emit(PaymentError(message: 'Payment finalization failed: ${e.toString()}'));
    }
  }

  // Helper to re-emit PaymentReady state, useful after errors or cancellations
  void _reEmitPaymentReady(Emitter<PaymentState> emit, {required bool isApplePayAvailable}) {
    if (_braintreeClientToken != null) {
      emit(PaymentReady(
        clientToken: _braintreeClientToken!,
        isApplePayAvailable: isApplePayAvailable,
      ));
    } else {
      // If client token is somehow lost, go back to initial or error
      emit(PaymentInitial());
      // Or: emit(const PaymentError(message: "Critical error: Client token lost. Please restart."));
    }
  }
}
