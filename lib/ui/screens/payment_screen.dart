// lib/ui/screens/payment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_braintree/flutter_braintree.dart';

import '../../blocs/payment/payment_bloc.dart';
import '../../blocs/payment/payment_event.dart';
import '../../blocs/payment/payment_state.dart';

class PaymentScreen extends StatelessWidget {
  final String planId;
  final String cabinetId;
  final String connectionKey;

  const PaymentScreen({
    super.key,
    required this.planId,
    required this.cabinetId,
    required this.connectionKey,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rent Power Bank')),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is SubscriptionCreated) {
            // proceed to rent
            context.read<PaymentBloc>().add(
              RentPowerBank(cabinetId, connectionKey),
            );
          }

          if (state is PowerBankRented) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const SuccessScreen(),
              ),
            );
          }

          if (state is PaymentFailure) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is PaymentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Center(
            child: ElevatedButton(
              onPressed: () async {
                // 1. fetch client token
                context.read<PaymentBloc>().add(FetchClientToken());
              },
              child: const Text('Pay with Card / ApplePay'),
            ),
          );
        },
      ),
    );
  }
}

// Hook into clientTokenLoaded to show drop-in:
class _DropInListener extends BlocListener<PaymentBloc, PaymentState> {
  const _DropInListener({required super.child});

  @override
  void listen(BuildContext context, PaymentState state) {
    if (state is ClientTokenLoaded) {
      _showDropIn(context, state.clientToken);
    }
  }

  Future<void> _showDropIn(BuildContext context, String clientToken) async {
    final request = BraintreeDropInRequest(
      tokenizationKey: clientToken,
      collectDeviceData: true,
      paypalRequest: null,
      cardEnabled: true,
      applePayRequest: BraintreeApplePayRequest(
        merchantIdentifier: 'merchant.com.example',
        amount: '0.01',
        currencyCode: 'USD',
      ),
    );

    final result = await BraintreeDropIn.start(request);
    if (result != null) {
      context.read<PaymentBloc>().add(AddPaymentMethod(result.paymentMethodNonce.nonce));
    }
  }
}

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Success! Your power bank is unlocked.')),
    );
  }
}
