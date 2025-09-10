// lib/bloc/payment_event.dart

import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// Fires once on screen load to fetch JWT + clientToken + remember stationId
class InitPaymentFlow extends PaymentEvent {
  final String stationId;

  InitPaymentFlow(this.stationId);

  @override
  List<Object?> get props => [stationId];
}

/// Fires when Apple Pay sheet completes with a nonce + stationId for rentPowerBank
class SubmitApplePay extends PaymentEvent {
  final String paymentNonce;
  final String stationId;

  SubmitApplePay({required this.paymentNonce, required this.stationId});

  @override
  List<Object?> get props => [paymentNonce, stationId];
}
