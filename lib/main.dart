import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'bloc/payment_bloc.dart';
// import 'bloc/payment_event.dart';
import 'services/payment_service.dart';
import 'screens/qr_code_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/success_screen.dart';
import 'package:powerbank_app/js_bridge/js_bridge.dart';


void main() {
  final service = PaymentService();
  final paymentBloc = PaymentBloc(service);

  // Register JS callback only on web
  registerApplePayCallback((nonce) {
    final stationId = Uri.base.queryParameters['stationId'] ?? '';
    paymentBloc.add(
      SubmitPaymentViaBraintreeDropIn(stationId: stationId, amount: '', currencyCode: ''),
    );
  });


  runApp(MyApp(paymentBloc: paymentBloc));
}

class MyApp extends StatelessWidget {
  final PaymentBloc paymentBloc;
  const MyApp({required this.paymentBloc, super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => QRScreen()),
        GoRoute(path: '/pay', builder: (_, state) {
          final stationId = state.uri.queryParameters['stationId'] ?? 'RECH082203000350';
          return PaymentScreen(stationId: stationId);
        }),
        GoRoute(path: '/success', builder: (_, __) => SuccessScreen()),
      ],
    );

    return BlocProvider.value(
      value: paymentBloc,
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(fontFamily: 'SF Pro Display'),
      ),
    );
  }
}
