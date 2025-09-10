abstract class PaymentState {}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentReady extends PaymentState {
  final String clientToken;
  PaymentReady({required this.clientToken});
}

class PaymentSuccess extends PaymentState {}

class PaymentError extends PaymentState {
  final String message;
  PaymentError(this.message);
}
