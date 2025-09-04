import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:js_util';
import 'dart:js';
import 'bloc/payment_bloc.dart';
import 'bloc/payment_event.dart';
import 'services/payment_service.dart';
import 'screens/qr_code_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/success_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final PaymentBloc paymentBloc = PaymentBloc(PaymentService());

  MyApp({super.key}) {
    // Register JS callback
    setProperty(context['handleApplePayResult'], 'call', allowInterop((nonce) {
      paymentBloc.add(SubmitApplePay(nonce));
    }));
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => QRScreen()),
        GoRoute(path: '/pay', builder: (_, state) {
          final stationId = state.uri.queryParameters['stationId'] ?? '';
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
