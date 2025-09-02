// lib/blocs/payment/payment_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'payment_event.dart';
import 'payment_state.dart';
import '../../data/repositories/payment_repository.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _repo;

  PaymentBloc(this._repo) : super(PaymentInitial()) {
    on<FetchClientToken>(_onFetchClientToken);
    on<AddPaymentMethod>(_onAddPaymentMethod);
    on<CreateSubscription>(_onCreateSubscription);
    on<RentPowerBank>(_onRentPowerBank);
  }

  Future<void> _onFetchClientToken(
      FetchClientToken event,
      Emitter<PaymentState> emit,
      ) async {
    emit(PaymentLoading());
    try {
      final token = await _repo.fetchClientToken();
      emit(ClientTokenLoaded(token));
    } catch (e) {
      emit(PaymentFailure('Failed to load client token: $e'));
    }
  }

  Future<void> _onAddPaymentMethod(
      AddPaymentMethod event,
      Emitter<PaymentState> emit,
      ) async {
    emit(PaymentLoading());
    try {
      final paymentToken = await _repo.addPaymentMethod(event.nonce);
      emit(PaymentMethodAdded(paymentToken));
    } catch (e) {
      emit(PaymentFailure('Add payment method failed: $e'));
    }
  }

  Future<void> _onCreateSubscription(
      CreateSubscription event,
      Emitter<PaymentState> emit,
      ) async {
    emit(PaymentLoading());
    try {
      await _repo.createSubscription(
        paymentToken: event.paymentToken,
        planId: event.planId,
      );
      emit(SubscriptionCreated());
    } catch (e) {
      emit(PaymentFailure('Subscription failed: $e'));
    }
  }

  Future<void> _onRentPowerBank(
      RentPowerBank event,
      Emitter<PaymentState> emit,
      ) async {
    emit(PaymentLoading());
    try {
      await _repo.rentPowerBank(
        cabinetId: event.cabinetId,
        connectionKey: event.connectionKey,
      );
      emit(PowerBankRented());
    } catch (e) {
      emit(PaymentFailure('Renting failed: $e'));
    }
  }
}
