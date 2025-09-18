// part of 'payment_bloc.dart';
//
// abstract class PaymentEvent extends Equatable {
//   const PaymentEvent();
//
//   @override
//   List<Object?> get props => [];
// }
//
// /// Event to initialize the payment flow, fetch client token, and check Apple Pay availability.
// class InitPaymentFlow extends PaymentEvent {
//   final String stationId; // Might be needed if initial setup depends on station
//
//   const InitPaymentFlow({required this.stationId});
//
//   @override
//   List<Object?> get props => [stationId];
// }
//
// /// Event to request an Apple Pay payment via Web JS.
// class RequestApplePayPaymentViaWeb extends PaymentEvent {
//   final String stationId;
//   final String amount;
//   final String currencyCode;
//
//   const RequestApplePayPaymentViaWeb({
//     required this.stationId,
//     required this.amount,
//     required this.currencyCode,
//   });
//
//   @override
//   List<Object?> get props => [stationId, amount, currencyCode];
// }
//
// /// Event to request a Card payment via Web JS.
// class RequestCardPaymentViaWeb extends PaymentEvent {
//   final String stationId;
//   // Card payments might not need amount/currency directly here if JS form handles it,
//   // but good to have if JS needs them for display or initial setup.
//   final String amount;
//   final String currencyCode;
//
//
//   const RequestCardPaymentViaWeb({
//     required this.stationId,
//     required this.amount,
//     required this.currencyCode,
//   });
//
//   @override
//   List<Object?> get props => [stationId, amount, currencyCode];
// }
//
// /// Event triggered internally by the BLoC when a nonce is received from JS Interop.
// class ProcessPaymentNonce extends PaymentEvent {
//   final String nonce;
//   final String stationId;
//   final bool isApplePay;
//   final String? deviceData; // Optional, likely null for basic web JS flow
//
//   const ProcessPaymentNonce({
//     required this.nonce,
//     required this.stationId,
//     required this.isApplePay,
//     this.deviceData,
//   });
//
//   @override
//   List<Object?> get props => [nonce, stationId, isApplePay, deviceData];
// }
