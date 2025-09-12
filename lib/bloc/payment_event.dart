// lib/bloc/payment_event.dart



// abstract class PaymentEvent extends Equatable {
//   @override
//   List<Object?> get props => [];
// }
//
// /// Fires once on screen load to fetch JWT + clientToken + remember stationId
// class InitPaymentFlow extends PaymentEvent {
//   final String stationId;
//
//   InitPaymentFlow(this.stationId);
//
//   @override
//   List<Object?> get props => [stationId];
// }
//
// /// Fires when Apple Pay sheet completes with a nonce + stationId for rentPowerBank
// class SubmitApplePay extends PaymentEvent {
//   final String paymentNonce;
//   final String stationId;
//
//   SubmitApplePay({required this.paymentNonce, required this.stationId});
//
//   @override
//   List<Object?> get props => [paymentNonce, stationId];
// }

// lib/bloc/payment_event.dart
part of 'payment_bloc.dart'; // If you use part/part of

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object> get props => [];
}

class InitPaymentFlow extends PaymentEvent {
  final String stationId; // If needed during init
  const InitPaymentFlow({required this.stationId});

  @override
  List<Object> get props => [stationId];
}

// Event used by the modified PaymentScreen
class SubmitPaymentViaBraintreeDropIn extends PaymentEvent {
  final String stationId;
  final String amount;
  final String currencyCode;

  const SubmitPaymentViaBraintreeDropIn({
    required this.stationId,
    required this.amount,
    required this.currencyCode,
  });

  @override
  List<Object> get props => [stationId, amount, currencyCode];
}
// part of 'payment_bloc.dart';
//*****************************************************
// part of 'payment_bloc.dart';
//
// abstract class PaymentEvent extends Equatable {
//   const PaymentEvent();
//
//   @override
//   List<Object?> get props => [];
// }
//
// class InitPaymentFlow extends PaymentEvent {
//   final String stationId;
//   const InitPaymentFlow({required this.stationId});
//
//   @override
//   List<Object> get props => [stationId];
// }
//
// // Event for initiating payment process (could be Apple Pay or Card)
// class StartBraintreePayment extends PaymentEvent {
//   final String stationId;
//   final String amount;
//   final String currencyCode;
//   // Potentially add a field to indicate if it's Apple Pay or Card,
//   // or handle that decision within the BLoC or UI.
//   // For now, let's assume the BLoC will try Apple Pay first if available,
//   // or you'll have separate UI triggers.
//
//   const StartBraintreePayment({
//     required this.stationId,
//     required this.amount,
//     required this.currencyCode,
//   });
//
//   @override
//   List<Object> get props => [stationId, amount, currencyCode];
// }
//
// // If you need a specific event to only trigger Apple Pay
// class RequestApplePayPayment extends PaymentEvent {
//   final String stationId;
//   final String amount;
//   final String currencyCode;
//
//   const RequestApplePayPayment({
//     required this.stationId,
//     required this.amount,
//     required this.currencyCode,
//   });
//   @override
//   List<Object> get props => [stationId, amount, currencyCode];
// }
//
// // If you need a specific event to only trigger Card Form
// class RequestCardPayment extends PaymentEvent {
//   final String stationId;
//   // Card form usually doesn't need amount/currency upfront for tokenization,
//   // but it's good to have it for context if your BLoC needs it later.
//   final String amount;
//   final String currencyCode;
//
//   const RequestCardPayment({
//     required this.stationId,
//     required this.amount,
//     required this.currencyCode,
//   });
//
//   @override
//   List<Object> get props => [stationId, amount, currencyCode];
// }


