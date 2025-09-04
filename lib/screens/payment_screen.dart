// // lib/ui/screens/payment_screen.dart
 import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:js/js.dart';
import 'dart:js' as js;

import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatelessWidget {
  final String stationId;
  const PaymentScreen({required this.stationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentBloc(PaymentService())..add(InitPaymentFlow(stationId)),
      child: Scaffold(
        appBar: AppBar(title: Text('Rent Power Bank')),
        body: BlocBuilder<PaymentBloc, PaymentState>(
          builder: (context, state) {
            if (state is PaymentLoading) return Center(child: CircularProgressIndicator());
            if (state is PaymentReady) {
              return Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.apple),
                  label: Text('Apple Pay'),
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => ApplePayBottomSheet(clientToken: state.clientToken),
                    );
                  },
                ),
              );
            }
            if (state is PaymentError) return Center(child: Text('Error: ${state.message}'));
            if (state is PaymentSuccess) {
              Future.microtask(() => context.go('/success'));
              return SizedBox.shrink();
            }
            return SizedBox.shrink();
          },
        ),
      ),
    );
  }
}


class ApplePayBottomSheet extends StatelessWidget {
  final String clientToken;
  const ApplePayBottomSheet({required this.clientToken});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Color(0xFFF2F2F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Image.asset('assets/apple_pay_black.png', height: 24),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          _buildCardInfo(),
          _buildAmountCard(),
          _buildAccountCard(),
          Spacer(),
          Divider(),
          _buildPaymentSummary(),
          _buildSideButtonHint(),
          SizedBox(height: 12),
          _buildHomeIndicator(),
        ],
      ),
    );
  }

  Widget _buildCardInfo() => _card(
    leading: Icon(Icons.credit_card),
    trailing: Icon(Icons.chevron_right),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apple Card', style: TextStyle(fontSize: 15.13, letterSpacing: 0.76)),
        Text('10880 Malibu Point Malibu Cal...', style: TextStyle(color: Color(0x3C3C4399), fontSize: 13.11)),
        Text('•••• 1234', style: TextStyle(color: Color(0x3C3C4399), fontSize: 13.11)),
      ],
    ),
  );

  Widget _buildAmountCard() => _card(
    content: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('\$4.99', style: TextStyle(fontSize: 13)),
        Icon(Icons.chevron_right),
      ],
    ),
  );

  Widget _buildAccountCard() => _card(
    content: Text('Account: username@icloud.com', style: TextStyle(color: Color(0x3C3C4399), fontSize: 13)),
  );

  Widget _card({Widget? leading, required Widget content, Widget? trailing}) => Container(
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        if (leading != null) leading,
        SizedBox(width: 12),
        Expanded(child: content),
        if (trailing != null) trailing,
      ],
    ),
  );

  Widget _buildPaymentSummary() => Container(
    color: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pay recharge', style: TextStyle(color: Colors.grey)),
            Text('\$4.99', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        Spacer(),
        Icon(Icons.chevron_right),
      ],
    ),
  );

  Widget _buildSideButtonHint() => ElevatedButton(
    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF007AFF)),
    onPressed: () {
      // Simulate Apple Pay confirmation
      js.context.callMethod('startApplePay', [clientToken, 'handleApplePayResult']);
    },
    child: Text('Double-click side button to confirm'),
  );

  Widget _buildHomeIndicator() => Container(
    height: 5,
    width: 134,
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: Colors.black26,
      borderRadius: BorderRadius.circular(3),
    ),
  );
}

