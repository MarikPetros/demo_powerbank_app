import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Power Bank Dispensed!', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final url = Uri.parse('https://apps.apple.com/ru/app/recharge-city/id1594160460');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url);
                }
              },
              child: Text('Download App'),
            ),
          ],
        ),
      ),
    );
  }
}
