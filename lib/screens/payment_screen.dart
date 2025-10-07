import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:powerbank_app/services/api_service.dart';
import 'package:powerbank_app/screens/success_screen.dart';
import 'package:powerbank_app/widgets/custom_button.dart';
import 'package:flutter_braintree/flutter_braintree.dart';

class PaymentScreen extends StatefulWidget {
  final String stationId;

  const PaymentScreen({super.key, required this.stationId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _accessToken;
  String? _braintreeToken;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    print('PaymentScreen initialized with stationId: ${widget.stationId}');
    _initializePayment();
  }

  Future<void> _initializePayment() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      print('Calling /api/v1/auth/apple/generate-account');
      final authResponse = await _apiService.generateAppleAccount();
      setState(() {
        _accessToken = authResponse.accessJwt;
        print('Access token received: $_accessToken');
      });
      print('Calling /api/v1/payments/generate-and-save-braintree-client-token');
      final braintreeToken = await _apiService.getBraintreeToken(_accessToken!);
      setState(() {
        _braintreeToken = braintreeToken;
        print('Braintree token received: $_braintreeToken');
      });
    } catch (e) {
      print('Error initializing payment: $e');
      setState(() {
        _errorMessage = 'Failed to initialize payment: $e. Please try again or contact support.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showBraintreeDropIn({required bool requestApplePay}) async {
    if (_braintreeToken == null) {
      print('Braintree token not available');
      setState(() {
        _errorMessage = 'Payment initialization not complete. Please wait or try again.';
      });
      return;
    }

    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      print('Showing Braintree Drop-in UI (Apple Pay: $requestApplePay)');

      final request = BraintreeDropInRequest(
        clientToken: _braintreeToken!,
        collectDeviceData: true,
        applePayRequest: requestApplePay
            ? BraintreeApplePayRequest(
          currencyCode: 'USD',
          supportedNetworks: [
            ApplePaySupportedNetworks.visa,
            ApplePaySupportedNetworks.masterCard,
            ApplePaySupportedNetworks.amex,
            ApplePaySupportedNetworks.discover,
          ],
          merchantIdentifier: 'merchant.com.company.app', // Replace with actual Merchant ID
          countryCode: 'US',
          paymentSummaryItems: [
            ApplePaySummaryItem(
              label: 'PowerBank App',
              amount: 4.99,
              type: _isLoading ? ApplePaySummaryItemType.pending : ApplePaySummaryItemType.final_,
            ),
          ], displayName: '',
        )
            : null,
        cardEnabled: !requestApplePay, // Disable card entry for Apple Pay flow
      );

      final result = await BraintreeDropIn.start(request);
      if (result != null) {
        print('Braintree nonce: ${result.paymentMethodNonce.nonce}');
        // Process payment with nonce
        await _apiService.addPaymentMethod(
          _accessToken!,
          result.paymentMethodNonce.nonce,
          'Power Bank Rental Subscription',
          requestApplePay ? 'apple_pay' : 'card',
        );
        await _apiService.createSubscription(
          _accessToken!,
          result.paymentMethodNonce.nonce,
          'tss2',
        );
        await _apiService.rentPowerBank(
          _accessToken!,
          widget.stationId,
          'connection_key', // Replace with actual connection key
        );
        print('Navigating to SuccessScreen');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SuccessScreen()),
        );
      } else {
        print('Braintree Drop-in UI cancelled');
        setState(() {
          _errorMessage = 'Payment cancelled. Please try again.';
        });
      }
    } catch (e) {
      print('Braintree payment error: $e');
      setState(() {
        _errorMessage = 'Payment failed: $e. Please try again or contact support.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SpinKitCircle(color: Colors.blue),
            SizedBox(height: 16),
            Text(
              'Loading Payment...',
              style: TextStyle(fontFamily: 'Inter', fontSize: 16),
            ),
          ],
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializePayment,
              child: const Text('Retry'),
            ),
          ],
        ),
      )
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
                      onPressed: _braintreeToken != null
                          ? () => _showBraintreeDropIn(requestApplePay: true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _braintreeToken != null ? Colors.black : Colors.grey,
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
                            errorBuilder: (context, error, stackTrace) {
                              print('Error loading Apple Pay icon: $error');
                              return const Icon(Icons.error, color: Colors.red);
                            },
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
                      rightIconPath: 'assets/icons/right_arrow.png',
                      backgroundColor: Colors.white,
                      textColor: const Color(0xFF0B0B0B),
                      borderColor: Colors.grey[300],
                      onPressed: () => _showBraintreeDropIn(requestApplePay: false),
                    ),
                  ],
                ),
                const Spacer(),
                Center(
                  child: InkWell(
                    onTap: () async {
                      const url = 'https://support.example.com';
                      print('Opening support link: $url');
                      if (await canLaunchUrl(Uri.parse(url))) {
                        await launchUrl(Uri.parse(url));
                      } else {
                        print('Failed to open support link');
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
