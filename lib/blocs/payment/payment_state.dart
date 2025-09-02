// lib/blocs/payment/payment_state.dart
import 'package:equatable/equatable.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();
  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class ClientTokenLoaded extends PaymentState {
  final String clientToken;
  const ClientTokenLoaded(this.clientToken);

  @override
  List<Object?> get props => [clientToken];
}

class PaymentMethodAdded extends PaymentState {
  final String paymentToken; // server-returned token
  const PaymentMethodAdded(this.paymentToken);

  @override
  List<Object?> get props => [paymentToken];
}

class SubscriptionCreated extends PaymentState {}

class PowerBankRented extends PaymentState {}

class PaymentFailure extends PaymentState {
  final String message;
  const PaymentFailure(this.message);

  @override
  List<Object?> get props => [message];
}
