//  lib/bloc/payment/payment_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:powerbank_app/bloc/payment_event.dart';
import 'package:powerbank_app/bloc/payment_state.dart';

import '../services/payment_service.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentService service;
  String? jwt;
  String? stationId;

  PaymentBloc(this.service) : super(PaymentInitial()) {
    on<InitPaymentFlow>(_onInit);
    on<SubmitApplePay>(_onSubmit);
  }

  Future<void> _onInit(InitPaymentFlow event,
      Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      stationId = event.stationId;
      final auth = await service.generateAppleAccount();

      print('Auth response: $auth');////////////////////

      jwt = auth['accessJwt'];
      if (jwt == null || jwt!.isEmpty) {
        emit(PaymentError('JWT missing from auth response'));
        return;
      }

      final token = await service.getClientToken(jwt!);
      emit(PaymentReady(token));
    } catch (e) {
      emit(PaymentError('Init failed: ${e.toString()}'));
    }
  }

  Future<void> _onSubmit(SubmitApplePay event,
      Emitter<PaymentState> emit) async {
    emit(PaymentLoading());
    try {
      if (jwt == null || jwt!.isEmpty) {
        emit(PaymentError('JWT missing during payment submission'));
        return;
      }

      final methodToken = await service.addPaymentMethod(
        jwt!,
        event.nonce,
        'Apple Pay',
        'APPLE_PAY',
      );
      await service.createSubscription(methodToken);
      await service.rentPowerBank(jwt!, stationId!, 'connectionKey');
      emit(PaymentSuccess());
    } catch (e) {
      emit(PaymentError('Payment failed: ${e.toString()}'));
    }
  }
}
