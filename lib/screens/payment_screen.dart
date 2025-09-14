import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// flutter_braintree specific imports are handled within the BLoC

import '../bloc/payment_bloc.dart';
import 'package:powerbank_app/js_interop_manager.dart';
import '../services/payment_service.dart'; // For PaymentService in BlocProvider

class PaymentScreen extends StatelessWidget {
  final String stationId;
  const PaymentScreen({super.key, required this.stationId});

  // Define payment details here or pass them if they are dynamic
  final String paymentAmount = "4.99";
  final String currencyCode = "USD";

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentBloc(service: PaymentService(), jsInteropManager: JSInteropManager())
        ..add(InitPaymentFlow(stationId:  stationId)), // Pass stationId if needed for Init
      child: Scaffold(
        appBar: AppBar(title: const Text('Rent Power Bank')),
        body: SafeArea(
          child: BlocConsumer<PaymentBloc, PaymentState>( // Use BlocConsumer for listening to side effects like errors
            listener: (context, state) {
              if (state is PaymentError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: ${state.message}')),
                );
              }
            },
            builder: (context, state) {
              debugPrint('🔄 PaymentState: ${state.runtimeType}');

              if (state is PaymentSuccess) {
                // Use WidgetsBinding.instance.addPostFrameCallback to ensure navigation happens
                // after the current build cycle, especially if state change triggers rebuild.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (ModalRoute.of(context)?.isCurrent ?? false) { // Ensure screen is still active
                    context.go('/success');
                  }
                });
                return const Center(child: Text('Payment Successful! Redirecting...'));
              }

              if (state is PaymentLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              // For PaymentError, the listener above will show a SnackBar.
              // We can still show a message in the UI body if desired.
              if (state is PaymentError && state.message.isNotEmpty) { // Check if message is not empty
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Payment Failed: ${state.message}', textAlign: TextAlign.center),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            // Optionally, allow re-initialization or retry
                            context.read<PaymentBloc>().add(InitPaymentFlow(stationId:  stationId));
                          },
                          child: const Text('Try Again'),
                        )
                      ],
                    ),
                  ),
                );
              }

              // This will be the main UI when state is PaymentInitial or PaymentReady
              // Or if PaymentError has an empty message (fallback)
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Complete Your Payment',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Amount: $paymentAmount $currencyCode',
                      style: const TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    // if (state is PaymentReady || state is PaymentInitial || (state is PaymentError && state.message.isEmpty))
                      // ElevatedButton(
                      //   style: ElevatedButton.styleFrom(
                      //     // backgroundColor: Colors.black, // Example styling
                      //     padding: const EdgeInsets.symmetric(vertical: 12),
                      //     textStyle: const TextStyle(fontSize: 18),
                      //   ),
                      //   onPressed: (state is PaymentLoading) // Disable button while loading
                      //       ? null
                      //       : () {
                      //     // Dispatch the event that uses BraintreeDropIn
                      //     context.read<PaymentBloc>().add(
                      //       SubmitPaymentViaBraintreeDropIn(
                      //         stationId: stationId,
                      //         amount: paymentAmount,
                      //         currencyCode: currencyCode,
                      //       ),
                      //     );
                      //   },
                      //   // You can use an Apple Pay like icon or text
                      //   child: const Row(
                      //     mainAxisAlignment: MainAxisAlignment.center,
                      //     children: [
                      //       // Icon(Icons.apple, color: Colors.white), // If you want an icon
                      //       // SizedBox(width: 8),
                      //       Text('Pay with Braintree'), // Or 'Pay Now' or 'Pay with Apple Pay'
                      //       // The Braintree DropIn will show the Apple Pay option if available
                      //     ],
                      //   ),
                      // ),
                    // payment_screen.dart - relevant part
// ...
                    if (kIsWeb && state is PaymentReady && state.isApplePayAvailable)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.apple), // Or a proper Apple Pay button asset
                        label: const Text('Pay with Apple Pay (Web)'),
                        onPressed: () {
                          context.read<PaymentBloc>().add(
                            RequestApplePayPayment(
                              stationId: stationId,
                              amount: paymentAmount, // Make sure these are passed
                              currencyCode: currencyCode,
                            ),
                          );
                        },
                      ),
// ...

                    if (state is PaymentLoading) // Show loading text near button if preferred
                      const Padding(
                        padding: EdgeInsets.only(top: 16.0),
                        child: Text('Processing payment...', textAlign: TextAlign.center),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

//*****************************************************
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
//
// import '../bloc/payment_bloc.dart';
// // payment_event.dart and payment_state.dart are implicitly imported via payment_bloc.dart if using part/part of
// // or import them directly if not.
// import '../services/payment_service.dart';
// // import 'package:powerbank_app/bloc/payment_event.dart';
// // import 'package:powerbank_app/bloc/payment_state.dart';
//
// class PaymentScreen extends StatelessWidget {
//   final String stationId;
//   const PaymentScreen({super.key, required this.stationId});
//
//   // Example payment details - make these dynamic as needed
//   final String paymentAmount = "4.99";
//   final String currencyCode = "USD";
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => PaymentBloc(PaymentService())
//         ..add(InitPaymentFlow(stationId: stationId)),
//       child: Scaffold(
//         appBar: AppBar(title: const Text('Complete Payment')),
//         body: SafeArea(
//           child: BlocConsumer<PaymentBloc, PaymentState>(
//             listener: (context, state) {
//               if (state is PaymentError) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                       content: Text('Error: ${state.message}'),
//                       backgroundColor: Colors.red),
//                 );
//               } else if (state is PaymentCancelled) {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   const SnackBar(content: Text('Payment was cancelled.')),
//                 );
//               }
//             },
//             builder: (context, state) {
//               debugPrint('PaymentScreen 🔄 PaymentState: ${state.runtimeType}');
//
//               if (state is PaymentSuccess) {
//                 WidgetsBinding.instance.addPostFrameCallback((_) {
//                   if (ModalRoute.of(context)?.isCurrent ?? false) {
//                     context.go('/success'); // Navigate to your success screen
//                   }
//                 });
//                 return const Center(child: Text('Payment Successful! Redirecting...'));
//               }
//
//               if (state is PaymentLoading) {
//                 return Center(
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         const CircularProgressIndicator(),
//                         const SizedBox(height: 16),
//                         Text(state.message ?? 'Processing...'),
//                       ],
//                     ));
//               }
//
//               // UI for PaymentInitial, PaymentReady, or after PaymentCancelled/PaymentError
//               bool applePayAvailable = false;
//               if (state is PaymentReady) {
//                 applePayAvailable = state.isApplePayAvailable;
//               }
//
//               return Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     const Text(
//                       'Choose Payment Method',
//                       style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       'Amount: $paymentAmount $currencyCode',
//                       style: const TextStyle(fontSize: 18),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 32),
//
//                     // Apple Pay Button (show only if available and state is ready)
//                     if (state is PaymentReady && applePayAvailable)
//                       ElevatedButton.icon(
//                         icon: const Icon(Icons.apple), // Simple Apple icon
//                         label: const Text('Pay with Apple Pay'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.black,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           textStyle: const TextStyle(fontSize: 18),
//                         ),
//                         onPressed: () {
//                           context.read<PaymentBloc>().add(
//                             RequestApplePayPayment(
//                               stationId: stationId,
//                               amount: paymentAmount,
//                               currencyCode: currencyCode,
//                             ),
//                           );
//                         },
//                       ),
//                     if (state is PaymentReady && applePayAvailable)
//                       const SizedBox(height: 16),
//
//                     // Card Payment Button (show if state is ready)
//                     if (state is PaymentReady)
//                       ElevatedButton.icon(
//                         icon: const Icon(Icons.credit_card),
//                         label: const Text('Pay with Card'),
//                         style: ElevatedButton.styleFrom(
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           textStyle: const TextStyle(fontSize: 18),
//                         ),
//                         onPressed: () {
//                           context.read<PaymentBloc>().add(
//                             RequestCardPayment(
//                               stationId: stationId,
//                               amount: paymentAmount,
//                               currencyCode: currencyCode,
//                             ),
//                           );
//                         },
//                       ),
//
//                     const SizedBox(height: 20),
//                     if (state is PaymentError) // Show a retry option on error
//                       ElevatedButton(
//                         onPressed: () {
//                           context.read<PaymentBloc>().add(InitPaymentFlow(stationId: stationId));
//                         },
//                         child: const Text('Try Again'),
//                       )
//
//                   ],
//                 ),
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//
