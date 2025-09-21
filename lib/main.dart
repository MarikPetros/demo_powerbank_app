import 'package:flutter/material.dart';
import 'package:uni_links/uni_links.dart';
import 'package:powerbank_app/screens/payment_screen.dart';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PowerBank App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
      ),
      home: const DeepLinkHandler(),
    );
  }
}

class DeepLinkHandler extends StatefulWidget {
  const DeepLinkHandler({super.key});

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();
  }

  void _handleIncomingLinks() {
    // Handle initial link
    getInitialLink().then((String? link) {
      if (link != null) {
        _navigateToPaymentScreen(link);
      }
    });

    // Handle links while app is running
    _sub = linkStream.listen((String? link) {
      if (link != null) {
        _navigateToPaymentScreen(link);
      }
    }, onError: (err) {
      print('Error handling deep link: $err');
    });
  }

  void _navigateToPaymentScreen(String link) {
    final uri = Uri.parse(link);
    final stationId = uri.queryParameters['stationId'] ?? 'RECH082203000350';
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(stationId: stationId),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}