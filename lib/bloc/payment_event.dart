abstract class PaymentEvent {}

class InitPaymentFlow extends PaymentEvent {
  final String stationId;
  InitPaymentFlow(this.stationId);
}

class SubmitApplePay extends PaymentEvent {
  final String nonce;
  SubmitApplePay(this.nonce);
}
