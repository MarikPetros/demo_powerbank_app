part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {
  final String message;
  const PaymentLoading({this.message = 'Loading...'});

  @override
  List<Object?> get props => [message];
}

class PaymentReady extends PaymentState {
  final String clientToken; // Braintree client token
  final bool isApplePayAvailable; // True if Apple Pay (Web) is likely available
  // You could add flags for card payment readiness if needed

  const PaymentReady({
    required this.clientToken,
    required this.isApplePayAvailable,
  });

  @override
  List<Object?> get props => [clientToken, isApplePayAvailable];
}

class PaymentProcessing extends PaymentState {
  final String message;
  const PaymentProcessing({this.message = 'Processing Payment...'});
  @override
  List<Object?> get props => [message];
}


class PaymentSuccess extends PaymentState {}

class PaymentCancelled extends PaymentState {}


class PaymentError extends PaymentState {
  final String message;
  const PaymentError({required this.message});

  @override
  List<Object?> get props => [message];
}
