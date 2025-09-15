import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // For kIsWeb check

// Assuming these are your BLoC and event paths
import '../bloc/payment_bloc.dart';

class PaymentScreen extends StatefulWidget {
  final String stationId;

  const PaymentScreen({super.key, required this.stationId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    // Dispatch event to initialize payment flow when screen loads
    // Pass the stationId received by the screen
    context.read<PaymentBloc>().add(InitPaymentFlow(stationId: widget.stationId));
  }

  @override
  Widget build(BuildContext context) {
    // These values are based on your Figma description
    const String displayedAmount = "\$4.99";
    const String originalAmount = "\$9.99";
    const String currencyCode = "USD"; // Should match BLoC and Braintree setup

    return Scaffold(
      // backgroundColor: Colors.white, // Default is usually white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Assuming no back button based on flow
        title: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(top: 10.0, left: 0), // Adjust padding as per Figma
            // Replace with your actual logo widget or Image.asset
            child: Text(
                "YOUR_LOGO",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 20
                )
            ),
          ),
        ),
      ),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (context, state) {
          if (state is PaymentSuccess) {
            context.go('/success'); // Navigate to success screen
          }
          if (state is PaymentError) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.message)));
          }
          if (state is PaymentCancelled) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(const SnackBar(content: Text("Payment cancelled.")));
          }
        },
        builder: (context, state) {
          if (state is PaymentInitial || (state is PaymentLoading && state.message == 'Initializing...')) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PaymentError && state is! PaymentReady) { // Show error if not in a ready state
            return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Error: ${state.message}", style: TextStyle(color: Colors.red)),
                    SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: (){
                          context.read<PaymentBloc>().add(InitPaymentFlow(stationId: widget.stationId));
                        },
                        child: Text("Retry Initialization")
                    )
                  ],
                )
            );
          }

          // Determine if Apple Pay button should be shown
          bool showApplePayButton = false;
          if (state is PaymentReady) {
            showApplePayButton = state.isApplePayAvailable;
          } else if (state is PaymentProcessing) {
            // Keep showing Apple Pay button as available if we were in PaymentReady before processing
            // This is a simplification; you might need to access previous state or refine.
            // For now, let's assume if processing, it was available.
            // A better way would be to store isApplePayAvailable in the BLoC directly.
            // Let's assume the BLoC's _reEmitPaymentReady handles this.
          }


          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20), // Space under logo/appbar
                    const Text(
                      'Monthly Subscription',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          displayedAmount,
                          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          originalAmount,
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'First month only',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 25),
                    const Divider(color: Colors.grey, height: 1),
                    const SizedBox(height: 25),

                    // --- Apple Pay Button ---
                    if (kIsWeb && showApplePayButton) // Only show if available on web
                      _ApplePayButton(
                        onPressed: (state is PaymentProcessing) ? null : () {
                          context.read<PaymentBloc>().add(
                            RequestApplePayPaymentViaWeb(
                              stationId: widget.stationId,
                              amount: PaymentBloc.paymentAmount, // Use constant from BLoC
                              currencyCode: PaymentBloc.currencyCode, // Use constant from BLoC
                            ),
                          );
                        },
                      ),
                    if (kIsWeb && showApplePayButton) const SizedBox(height: 20),


                    // --- Debit or Credit Card Button ---
                    _DebitCreditCardButton(
                      onPressed: (state is PaymentProcessing) ? null : () {
                        // TODO: Implement card payment initiation
                        // This will likely involve showing a card form (e.g., Braintree Hosted Fields)
                        // which would be managed via JS Interop.
                        // For now, we can add the event for the BLoC to handle.
                        debugPrint("Debit/Credit Card button pressed. JS for card form is TODO.");
                        context.read<PaymentBloc>().add(
                          RequestCardPaymentViaWeb(
                            stationId: widget.stationId,
                            amount: PaymentBloc.paymentAmount,
                            currencyCode: PaymentBloc.currencyCode,
                          ),
                        );
                        // ScaffoldMessenger.of(context).showSnackBar(
                        //   const SnackBar(content: Text('Card payment form (JS) to be implemented.')),
                        // );
                      },
                    ),
                    const Spacer(), // Pushes bottom content down
                  ],
                ),
              ),
              // Bottom Bar (as per Figma: button and tabs with dark gray background)
              // This is a simplified representation. Tabs would need more setup.
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  color: Colors.grey[800], // Dark gray background
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Example color
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: (state is PaymentProcessing) ? null : () {
                          // This button's action depends on what's selected (Apple Pay or Card)
                          // Or if it's a generic "Pay" button after selecting a method.
                          // For this design, it seems payment methods are directly actionable.
                          // If this is a separate "Confirm Purchase" button, the logic would differ.
                          // Based on Figma, the Apple Pay and Card buttons are direct actions.
                          // So, this button might be for something else or not needed if other buttons trigger payment.
                          // Let's assume it's like a general action button not directly tied to payment for now.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Bottom button action TBD')),
                          );
                        },
                        child: const Text('BOTTOM ACTION BUTTON', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                      const SizedBox(height: 10),
                      // Placeholder for Tabs
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Icon(Icons.home, color: Colors.white70),
                          Icon(Icons.map, color: Colors.white70),
                          Icon(Icons.account_circle, color: Colors.white70),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Loading Overlay
              if (state is PaymentProcessing)
                Container(
                  color: Colors.black.withOpacity(0.3),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 10),
                        Text(state.message, style: TextStyle(color: Colors.white, fontSize: 16))
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// --- Custom Apple Pay Button Widget ---
class _ApplePayButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _ApplePayButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.apple, color: Colors.white, size: 28), // Example Apple icon
      label: const Text(
        'Pay with Apple Pay',
        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50), // Make button wide
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
        ),
      ),
      onPressed: onPressed,
    );
  }
}

// --- Custom Debit/Credit Card Button Widget ---
class _DebitCreditCardButton extends StatelessWidget {
  final VoidCallback? onPressed;
  const _DebitCreditCardButton({this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: Colors.grey[300]!)
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          // decoration: BoxDecoration(
          //   color: Colors.white, // White background
          //   borderRadius: BorderRadius.circular(8),
          //   border: Border.all(color: Colors.grey[300]!), // Delimiters
          // ),
          child: Row(
            children: [
              // Placeholder for card icons
              Icon(Icons.credit_card, color: Colors.grey[700]),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  'Debit or credit card',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.black87),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[700]),
            ],
          ),
        ),
      ),
    );
  }
}
