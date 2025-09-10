// import 'package:bloc/bloc.dart';
//
// import '../services/payment_service.dart';
// import 'payment_event.dart';
// import 'payment_state.dart';
//
// class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
//   final PaymentService _service;
//   late String _accessJwt;
//   late String _clientToken;
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
//       // 1) Add payment method
//       final methodToken = await _service.addPaymentMethod(
//         accessJwt: _accessJwt,
//         paymentNonce: event.paymentNonce,
//       );
//
//       // 2) Create subscription
//       await _service.createSubscription(
//         accessJwt: _accessJwt,
//         methodToken: methodToken,
//       );
//
//       // 3) Rent the power bank
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

// lib/bloc/payment_bloc.dart

import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter_braintree/flutter_braintree.dart';

import '../services/payment_service.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService _service;
  late String _accessJwt;
  late String _clientToken; // from your backend

  PaymentBloc(this._service) : super(PaymentInitial()) {
    on<InitPaymentFlow>(_onInit);
    on<SubmitApplePay>(_onSubmitApplePay);
  }

  Future<void> _onInit(
    InitPaymentFlow event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      _accessJwt = await _service.generateAccount();
      _clientToken = await _service.getClientToken(_accessJwt);
      emit(PaymentReady(clientToken: _clientToken));
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }

  Future<void> _onSubmitApplePay(
    SubmitApplePay event,
    Emitter<PaymentState> emit,
  ) async {
    emit(PaymentLoading());
    try {
      // 1) First tokenize the Apple Pay token into a Braintree nonce
      final applePayJsonString = event.paymentNonce;
      final applePayData =
          jsonDecode(applePayJsonString) as Map<String, dynamic>;

      final request = BraintreeApplePayRequest(
        paymentSummaryItems: applePayData['paymentSummaryItems'],
        displayName: applePayData['displayName'],
        currencyCode: applePayData['currencyCode'],
        countryCode: applePayData['countryCode'],
        merchantIdentifier: applePayData['merchantIdentifier'],
        supportedNetworks: applePayData['supportedNetworks'],
      );

      final tokenizationResult = await Braintree.tokenizeApplePayPayment(
        clientToken: _clientToken,
        applePayRequest: request,
      );

      if (tokenizationResult == null) {
        throw Exception('Apple Pay authorization was canceled by user.');
      }

      final braintreeNonce = tokenizationResult.nonce;

      // 2) Vault that nonce on your backend
      final methodToken = await _service.addPaymentMethod(
        accessJwt: _accessJwt,
        paymentNonce: braintreeNonce,
      );

      // 3) Create the subscription
      await _service.createSubscription(
        accessJwt: _accessJwt,
        methodToken: methodToken,
      );

      // 4) Rent the power bank
      await _service.rentPowerBank(
        accessJwt: _accessJwt,
        cabinetId: event.stationId,
        connectionKey: event.stationId,
      );

      emit(PaymentSuccess());
    } catch (e) {
      emit(PaymentError(e.toString()));
    }
  }
}
