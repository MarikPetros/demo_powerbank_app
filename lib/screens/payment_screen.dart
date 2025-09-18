// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:flutter/foundation.dart' show kIsWeb; // For kIsWeb check
//
// // Assuming these are your BLoC and event paths
// import '../bloc/payment_bloc.dart';
//
// class PaymentScreen extends StatefulWidget {
//   final String stationId;
//
//   const PaymentScreen({super.key, required this.stationId});
//
//   @override
//   State<PaymentScreen> createState() => _PaymentScreenState();
// }
//
// class _PaymentScreenState extends State<PaymentScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Dispatch event to initialize payment flow when screen loads
//     // Pass the stationId received by the screen
//     context.read<PaymentBloc>().add(InitPaymentFlow(stationId: widget.stationId));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // These values are based on your Figma description
//     const String displayedAmount = "\$4.99";
//     const String originalAmount = "\$9.99";
//     const String currencyCode = "USD"; // Should match BLoC and Braintree setup
//
//     return Scaffold(
//       // backgroundColor: Colors.white, // Default is usually white
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         automaticallyImplyLeading: false, // Assuming no back button based on flow
//         title: Align(
//           alignment: Alignment.topLeft,
//           child: Padding(
//             padding: const EdgeInsets.only(top: 10.0, left: 0), // Adjust padding as per Figma
//             // Replace with your actual logo widget or Image.asset
//             child: Text(
//                 "YOUR_LOGO",
//                 style: TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 20
//                 )
//             ),
//           ),
//         ),
//       ),
//       body: BlocConsumer<PaymentBloc, PaymentState>(
//         listener: (context, state) {
//           if (state is PaymentSuccess) {
//             context.go('/success'); // Navigate to success screen
//           }
//           if (state is PaymentError) {
//             ScaffoldMessenger.of(context)
//               ..hideCurrentSnackBar()
//               ..showSnackBar(SnackBar(content: Text(state.message)));
//           }
//           if (state is PaymentCancelled) {
//             ScaffoldMessenger.of(context)
//               ..hideCurrentSnackBar()
//               ..showSnackBar(const SnackBar(content: Text("Payment cancelled.")));
//           }
//         },
//         builder: (context, state) {
//           if (state is PaymentInitial || (state is PaymentLoading && state.message == 'Initializing...')) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (state is PaymentError && state is! PaymentReady) { // Show error if not in a ready state
//             return Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Text("Error: ${state.message}", style: TextStyle(color: Colors.red)),
//                     SizedBox(height: 20),
//                     ElevatedButton(
//                         onPressed: (){
//                           context.read<PaymentBloc>().add(InitPaymentFlow(stationId: widget.stationId));
//                         },
//                         child: Text("Retry Initialization")
//                     )
//                   ],
//                 )
//             );
//           }
//
//           // Determine if Apple Pay button should be shown
//           bool showApplePayButton = false;
//           if (state is PaymentReady) {
//             showApplePayButton = state.isApplePayAvailable;
//           } else if (state is PaymentProcessing) {
//             // Keep showing Apple Pay button as available if we were in PaymentReady before processing
//             // This is a simplification; you might need to access previous state or refine.
//             // For now, let's assume if processing, it was available.
//             // A better way would be to store isApplePayAvailable in the BLoC directly.
//             // Let's assume the BLoC's _reEmitPaymentReady handles this.
//           }
//
//
//           return Stack(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const SizedBox(height: 20), // Space under logo/appbar
//                     const Text(
//                       'Monthly Subscription',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 15),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       crossAxisAlignment: CrossAxisAlignment.baseline,
//                       textBaseline: TextBaseline.alphabetic,
//                       children: [
//                         Text(
//                           displayedAmount,
//                           style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
//                         ),
//                         const SizedBox(width: 8),
//                         Text(
//                           originalAmount,
//                           style: const TextStyle(
//                             fontSize: 18,
//                             color: Colors.grey,
//                             decoration: TextDecoration.lineThrough,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 5),
//                     const Text(
//                       'First month only',
//                       style: TextStyle(fontSize: 12, color: Colors.grey),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 25),
//                     const Divider(color: Colors.grey, height: 1),
//                     const SizedBox(height: 25),
//
//                     // --- Apple Pay Button ---
//                     if (kIsWeb && showApplePayButton) // Only show if available on web
//                       _ApplePayButton(
//                         onPressed: (state is PaymentProcessing) ? null : () {
//                           context.read<PaymentBloc>().add(
//                             RequestApplePayPaymentViaWeb(
//                               stationId: widget.stationId,
//                               amount: PaymentBloc.paymentAmount, // Use constant from BLoC
//                               currencyCode: PaymentBloc.currencyCode, // Use constant from BLoC
//                             ),
//                           );
//                         },
//                       ),
//                     if (kIsWeb && showApplePayButton) const SizedBox(height: 20),
//
//
//                     // --- Debit or Credit Card Button ---
//                     _DebitCreditCardButton(
//                       onPressed: (state is PaymentProcessing) ? null : () {
//                         // TODO: Implement card payment initiation
//                         // This will likely involve showing a card form (e.g., Braintree Hosted Fields)
//                         // which would be managed via JS Interop.
//                         // For now, we can add the event for the BLoC to handle.
//                         debugPrint("Debit/Credit Card button pressed. JS for card form is TODO.");
//                         context.read<PaymentBloc>().add(
//                           RequestCardPaymentViaWeb(
//                             stationId: widget.stationId,
//                             amount: PaymentBloc.paymentAmount,
//                             currencyCode: PaymentBloc.currencyCode,
//                           ),
//                         );
//                         // ScaffoldMessenger.of(context).showSnackBar(
//                         //   const SnackBar(content: Text('Card payment form (JS) to be implemented.')),
//                         // );
//                       },
//                     ),
//                     const Spacer(), // Pushes bottom content down
//                   ],
//                 ),
//               ),
//               // Bottom Bar (as per Figma: button and tabs with dark gray background)
//               // This is a simplified representation. Tabs would need more setup.
//               Align(
//                 alignment: Alignment.bottomCenter,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
//                   color: Colors.grey[800], // Dark gray background
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.green, // Example color
//                           minimumSize: const Size(double.infinity, 50),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                         ),
//                         onPressed: (state is PaymentProcessing) ? null : () {
//                           // This button's action depends on what's selected (Apple Pay or Card)
//                           // Or if it's a generic "Pay" button after selecting a method.
//                           // For this design, it seems payment methods are directly actionable.
//                           // If this is a separate "Confirm Purchase" button, the logic would differ.
//                           // Based on Figma, the Apple Pay and Card buttons are direct actions.
//                           // So, this button might be for something else or not needed if other buttons trigger payment.
//                           // Let's assume it's like a general action button not directly tied to payment for now.
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(content: Text('Bottom button action TBD')),
//                           );
//                         },
//                         child: const Text('BOTTOM ACTION BUTTON', style: TextStyle(fontSize: 16, color: Colors.white)),
//                       ),
//                       const SizedBox(height: 10),
//                       // Placeholder for Tabs
//                       const Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceAround,
//                         children: [
//                           Icon(Icons.home, color: Colors.white70),
//                           Icon(Icons.map, color: Colors.white70),
//                           Icon(Icons.account_circle, color: Colors.white70),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               // Loading Overlay
//               if (state is PaymentProcessing)
//                 Container(
//                   color: Colors.black.withOpacity(0.3),
//                   child: Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         CircularProgressIndicator(color: Colors.white),
//                         SizedBox(height: 10),
//                         Text(state.message, style: TextStyle(color: Colors.white, fontSize: 16))
//                       ],
//                     ),
//                   ),
//                 ),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
//
// // --- Custom Apple Pay Button Widget ---
// class _ApplePayButton extends StatelessWidget {
//   final VoidCallback? onPressed;
//   const _ApplePayButton({this.onPressed});
//
//   @override
//   Widget build(BuildContext context) {
//     return ElevatedButton.icon(
//       icon: const Icon(Icons.apple, color: Colors.white, size: 28), // Example Apple icon
//       label: const Text(
//         'Pay with Apple Pay',
//         style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.black,
//         minimumSize: const Size(double.infinity, 50), // Make button wide
//         padding: const EdgeInsets.symmetric(vertical: 12),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8), // Rounded corners
//         ),
//       ),
//       onPressed: onPressed,
//     );
//   }
// }
//
// // --- Custom Debit/Credit Card Button Widget ---
// class _DebitCreditCardButton extends StatelessWidget {
//   final VoidCallback? onPressed;
//   const _DebitCreditCardButton({this.onPressed});
//
//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.white,
//       shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(8),
//           side: BorderSide(color: Colors.grey[300]!)
//       ),
//       child: InkWell(
//         onTap: onPressed,
//         borderRadius: BorderRadius.circular(8),
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
//           // decoration: BoxDecoration(
//           //   color: Colors.white, // White background
//           //   borderRadius: BorderRadius.circular(8),
//           //   border: Border.all(color: Colors.grey[300]!), // Delimiters
//           // ),
//           child: Row(
//             children: [
//               // Placeholder for card icons
//               Icon(Icons.credit_card, color: Colors.grey[700]),
//               const SizedBox(width: 15),
//               const Expanded(
//                 child: Text(
//                   'Debit or credit card',
//                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
//                 ),
//               ),
//               Icon(Icons.chevron_right, color: Colors.grey[700]),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:powerbank_app/services/api_service.dart';
import 'package:powerbank_app/screens/success_screen.dart';
import 'package:powerbank_app/widgets/custom_button.dart';
import 'package:js/js.dart';
import 'dart:js' as js;

// JavaScript interop for Apple Pay
@JS('ApplePaySession')
external dynamic get ApplePaySession;

@JS()
external bool canMakePayments();

class PaymentScreen extends StatefulWidget {
  final String stationId;

  const PaymentScreen({super.key, required this.stationId});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _accessToken;
  String? _braintreeToken;
  bool _showWebView = false;
  bool _applePayAvailable = false;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _checkApplePayAvailability();
    _initializePayment();
    _setupWebViewController();
  }

  void _setupWebViewController() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('payment_success')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const SuccessScreen()),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _checkApplePayAvailability() async {
    try {
      final bool isAvailable = js.context.hasProperty('ApplePaySession') && canMakePayments();
      setState(() {
        _applePayAvailable = isAvailable;
      });
    } catch (e) {
      print('Error checking Apple Pay availability: $e');
      setState(() {
        _applePayAvailable = false;
      });
    }
  }

  Future<void> _initializePayment() async {
    try {
      setState(() => _isLoading = true);
      final authResponse = await _apiService.generateAppleAccount();
      setState(() {
        _accessToken = authResponse.accessJwt;
      });
      final braintreeToken = await _apiService.getBraintreeToken(_accessToken!);
      setState(() {
        _braintreeToken = braintreeToken;
        _webViewController.loadRequest(Uri.parse(
            'https://goldfish-app-3lf7u.ondigitalocean.app/payment?token=$_braintreeToken'));
      });
    } catch (e) {
      print('Error initializing payment: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApplePay() async {
    if (!_applePayAvailable) return;

    setState(() => _isLoading = true);
    try {
      final paymentRequest = js.JsObject.jsify({
        'countryCode': 'US',
        'currencyCode': 'USD',
        'supportedNetworks': ['visa', 'masterCard', 'amex', 'discover'],
        'merchantCapabilities': ['supports3DS'],
        'total': {
          'label': 'Power Bank Rental',
          'amount': '4.99',
        },
      });

      final session = js.JsObject(ApplePaySession, [1, paymentRequest]);

      session['onvalidatemerchant'] = allowInterop((event) async {
        try {
          final merchantSession = await _apiService.validateMerchant();
          session.callMethod('completeMerchantValidation', [js.JsObject.jsify(merchantSession)]);
        } catch (e) {
          session.callMethod('abort', []);
        }
      });

      session['onpaymentauthorized'] = allowInterop((event) async {
        try {
          final paymentToken = jsonEncode(event['payment']['token']);
          await _apiService.createSubscription(_accessToken!, paymentToken, 'tss2');
          await _apiService.rentPowerBank(_accessToken!, widget.stationId, 'connection_key');
          session.callMethod('completePayment', [js.JsObject.jsify({'status': 0})]);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const SuccessScreen()),
          );
        } catch (e) {
          session.callMethod('completePayment', [js.JsObject.jsify({'status': 1})]);
          print('Apple Pay error: $e');
        }
      });

      session.callMethod('begin', []);
    } catch (e) {
      print('Apple Pay error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showCardPaymentWebView() {
    setState(() => _showWebView = true);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF2C2C2E),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF0A84FF)), onPressed: () {}),
            IconButton(icon: const Icon(Icons.share, color: Color(0xFF0A84FF)), onPressed: () {}),
            IconButton(icon: const Icon(Icons.book, color: Color(0xFF0A84FF)), onPressed: () {}),
            IconButton(icon: const Icon(Icons.copy, color: Color(0xFF0A84FF)), onPressed: () {}),
            IconButton(icon: const Icon(Icons.arrow_forward, color: Color(0xFF0A84FF)), onPressed: () {}),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: SpinKitCircle(color: Colors.blue))
          : _showWebView
          ? WebViewWidget(controller: _webViewController)
          : SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isMobile ? screenWidth : 353),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monthly Subscription',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF0B0B0B),
                    height: 1.25,
                    letterSpacing: 0.26,
                  ),
                ),
                const SizedBox(height: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '\$4.99',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 38,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                            height: 1.525,
                            letterSpacing: 0.38,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '\$9.99',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 26,
                            fontWeight: FontWeight.w400,
                            color: Colors.grey[400],
                            height: 1.525,
                            letterSpacing: 0.26,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'First month only',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.grey[400],
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Column(
                  children: [
                    // Apple Pay Button
                    ElevatedButton(
                      onPressed: _applePayAvailable
                          ? () {
                        _handleApplePay(); // Synchronous wrapper
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _applePayAvailable ? Colors.black : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/icons/apple_pay_logo.png',
                            height: 18.48,
                            width: 48,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Pay with Apple Pay',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              height: 1.0,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Card Payment Button
                    CustomButton(
                      text: 'Debit or Credit Card',
                      iconPath: 'assets/icons/cards_icon.png',
                      rightIconPath: 'assets/images/right_arrow.png',
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF0B0B0B),
                      borderColor: Colors.grey[300],
                      onPressed: _showCardPaymentWebView,
                    ),
                  ],
                ),
                const Spacer(),
                Center(
                  child: InkWell(
                    onTap: () async {
                      const url = 'https://support.example.com';
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      }
                    },
                    child: const Text(
                      'NOTHING HAPPENED? CONTACT SUPPORT',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF606060),
                        height: 1.0,
                        letterSpacing: 1,
                        textBaseline: TextBaseline.alphabetic,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}