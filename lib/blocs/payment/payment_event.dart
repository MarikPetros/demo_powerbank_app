// lib/blocs/payment/payment_event.dart
import 'package:equatable/equatable.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class FetchClientToken extends PaymentEvent {}

class AddPaymentMethod extends PaymentEvent {
  final String nonce;
  const AddPaymentMethod(this.nonce);

  @override
  List<Object?> get props => [nonce];
}

class CreateSubscription extends PaymentEvent {
  final String paymentToken;
  final String planId;
  const CreateSubscription(this.paymentToken, this.planId);

  @override
  List<Object?> get props => [paymentToken, planId];
}

class RentPowerBank extends PaymentEvent {
  final String cabinetId;
  final String connectionKey;
  const RentPowerBank(this.cabinetId, this.connectionKey);

  @override
  List<Object?> get props => [cabinetId, connectionKey];
}
