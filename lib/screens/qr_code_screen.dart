import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PlaceholderQRScreen extends StatelessWidget {
  final String defaultStationId;
  const PlaceholderQRScreen({super.key, required this.defaultStationId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR (Simulated)')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('QR Code scanning is not implemented for this test.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            const Text('Using test station ID:'),
            Text(defaultStationId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                // Navigate to payment screen with the test station ID
                context.go('/pay?stationId=$defaultStationId');
              },
              child: const Text('Proceed to Payment'),
            ),
            const SizedBox(height: 30),
            const Text('Or, access directly via URL:', textAlign: TextAlign.center),
            SelectableText('/pay?stationId=YOUR_STATION_ID', style: TextStyle(color: Colors.blue)),
          ],
        ),
      ),
    );
  }
}