// abstract class PaymentState {}
//
// class PaymentInitial extends PaymentState {}
//
// class PaymentLoading extends PaymentState {}
//
// class PaymentReady extends PaymentState {
//   final String clientToken;
//   PaymentReady({required this.clientToken});
// }
//
// class PaymentSuccess extends PaymentState {}
//
// class PaymentError extends PaymentState {
//   final String message;
//   PaymentError(this.message);
// }
//
// part of 'payment_bloc.dart';
//
// abstract class PaymentState extends Equatable {
//   const PaymentState();
//
//   @override
//   List<Object> get props => [];
// }
//
// class PaymentInitial extends PaymentState {}
//
// class PaymentLoading extends PaymentState {}
//
// class PaymentReady extends PaymentState {
//   final String clientToken; // Braintree Client Token
//   const PaymentReady({required this.clientToken});
//
//   @override
//   List<Object> get props => [clientToken];
// }
//
// class PaymentSuccess extends PaymentState {}
//
// class PaymentError extends PaymentState {
//   final String message;
//   const PaymentError({required this.message});
//
//   @override
//   List<Object> get props => [message];
// }
//&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&
part of 'payment_bloc.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {
  final String? message; // Optional message for loading state
  const PaymentLoading({this.message});
  @override
  List<Object?> get props => [message];
}

class PaymentReady extends PaymentState {
  final String braintreeClientToken;
  // Add a flag to indicate if Apple Pay is viable on this device/setup
  final bool isApplePayAvailable;

  const PaymentReady({
    required this.braintreeClientToken,
    required this.isApplePayAvailable,
  });

  @override
  List<Object> get props => [braintreeClientToken, isApplePayAvailable];
}

class PaymentSuccess extends PaymentState {}

class PaymentError extends PaymentState {
  final String message;
  const PaymentError({required this.message});

  @override
  List<Object> get props => [message];
}

//You might want a specific state if the user cancels
class PaymentCancelled extends PaymentState {}