// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';

import 'data/repositories/payment_repository.dart';
import 'blocs/payment/payment_bloc.dart';
import 'ui/screens/payment_screen.dart';

void main() {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.yourdomain.com/api/v1',
    headers: {'Authorization': 'Bearer YOUR_ACCESS_TOKEN'},
  ));

  final paymentRepo = PaymentRepository(dio);

  runApp(
    RepositoryProvider.value(
      value: paymentRepo,
      child: BlocProvider(
        create: (_) => PaymentBloc(paymentRepo),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Power Bank Rental',
      home: const PaymentScreen(
        planId: 'tss2',
        cabinetId: 'station-123',
        connectionKey: 'station-123',
      ),
    );
  }
}
