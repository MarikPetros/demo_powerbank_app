import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QRScreen extends StatelessWidget {
  const QRScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Text('Simulate QR Scan'),
          onPressed: () {
            context.go('/pay?stationId=RECH082203000350');
          },
        ),
      ),
    );
  }
}
