// // // // lib/ui/screens/payment_screen.dart
// //
// // import 'dart:convert';
// //
// // import 'package:flutter/material.dart';
// // import 'package:flutter_bloc/flutter_bloc.dart';
// // import 'package:go_router/go_router.dart';
// // import 'package:pay/pay.dart';
// // import 'package:powerbank_app/apple_pay_config.dart';
// //
// // import '../bloc/payment_bloc.dart';
// // import '../bloc/payment_event.dart';
// // import '../bloc/payment_state.dart';
// // import '../services/payment_service.dart';
// //
// // class PaymentScreen extends StatelessWidget {
// //   final String stationId;
// //
// //   const PaymentScreen({super.key, required this.stationId});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     if (stationId == 'Error has happened') {
// //       return Scaffold(body: Center(child: Text('Invalid station ID')));
// //     }
// //
// //     return BlocProvider(
// //       create: (_) =>
// //           PaymentBloc(PaymentService())..add(InitPaymentFlow(stationId)),
// //       child: Scaffold(
// //         appBar: AppBar(title: Text('Rent Power Bank')),
// //         body: BlocBuilder<PaymentBloc, PaymentState>(
// //           builder: (context, state) {
// //             if (state is PaymentLoading) {
// //               return Center(child: CircularProgressIndicator());
// //             }
// //             if (state is PaymentReady) {
// //               return Center(
// //                 child: ApplePayButton(
// //                   paymentConfiguration: PaymentConfiguration.fromJsonString(
// //                     applePayJson,
// //                   ),
// //                   paymentItems: [
// //                     PaymentItem(label: 'Recharge', amount: '4.99'),
// //                   ],
// //                   type: ApplePayButtonType.plain,
// //                   style: ApplePayButtonStyle.black,
// //                   width: 200,
// //                   height: 44,
// //                   onPaymentResult: (result) {
// //                     // 1. Dump it so you can see the raw shape
// //                     debugPrint('🔔 ApplePay raw result → ${jsonEncode(result)}');
// //
// //                     // 2. Extract the token. On iOS, it's under `paymentData`.
// //                     final paymentData = result['paymentData'];
// //                     if (paymentData == null) {
// //                       ScaffoldMessenger.of(context).showSnackBar(
// //                         SnackBar(content: Text('Apple Pay returned no paymentData')),
// //                       );
// //                       return;
// //                     }
// //
// //                     // 3. JSON-encode the Apple PKPaymentToken for Braintree
// //                     final nonce = jsonEncode(paymentData);
// //
// //                     context.read<PaymentBloc>().add(
// //                       SubmitApplePay(
// //                         paymentNonce: nonce,
// //                         stationId: stationId,
// //                       ),
// //                     );
// //
// //                   },
// //                   loadingIndicator: const CircularProgressIndicator(),
// //                 ),
// //               );
// //             }
// //             if (state is PaymentError) {
// //               return Center(child: Text('Error: ${state.message}'));
// //             }
// //             if (state is PaymentSuccess) {
// //               Future.microtask(() => context.go('/success'));
// //               return SizedBox.shrink();
// //             }
// //             return SizedBox.shrink();
// //           },
// //         ),
// //       ),
// //     );
// //   }
// // }
// // lib/ui/screens/payment_screen.dart
//
// import 'dart:convert';
//
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:pay/pay.dart';
// import 'package:powerbank_app/apple_pay_config.dart';
//
// import '../bloc/payment_bloc.dart';
// import '../bloc/payment_event.dart';
// import '../bloc/payment_state.dart';
// import '../services/payment_service.dart';
//
// class PaymentScreen extends StatelessWidget {
//   final String stationId;
//
//   const PaymentScreen({super.key, required this.stationId});
//
//   @override
//   Widget build(BuildContext context) {
//     if (stationId == 'Error has happened') {
//       return Scaffold(
//         appBar: AppBar(title: Text('Rent Power Bank')),
//         body: Center(child: Text('Invalid station ID')),
//       );
//     }
//
//     return BlocProvider(
//       create: (_) =>
//       PaymentBloc(PaymentService())..add(InitPaymentFlow(stationId)),
//       child: Scaffold(
//         appBar: AppBar(title: Text('Rent Power Bank')),
//         body: SafeArea(
//           child: BlocBuilder<PaymentBloc, PaymentState>(
//             builder: (context, state) {
//               debugPrint('🔄 PaymentState: ${state.runtimeType}');
//
//               if (state is PaymentLoading) {
//                 return Center(child: CircularProgressIndicator());
//               }
//
//               if (state is PaymentError) {
//                 return Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text('Error: ${state.message}'),
//                       SizedBox(height: 16),
//                       ElevatedButton(
//                         onPressed: () {
//                           context.read<PaymentBloc>().add(
//                             InitPaymentFlow(stationId),
//                           );
//                         },
//                         child: Text('Retry'),
//                       ),
//                     ],
//                   ),
//                 );
//               }
//
//               if (state is PaymentSuccess) {
//                 Future.microtask(() => context.go('/success'));
//                 return Center(child: Text('Redirecting...'));
//               }
//
//               if (state is PaymentReady) {
//                 // return Center(
//                 //   child: ApplePayButton(
//                 //     paymentConfiguration: PaymentConfiguration.fromJsonString(
//                 //       applePayJson,
//                 //     ),
//                 //     paymentItems: [
//                 //       PaymentItem(label: 'Recharge', amount: '4.99'),
//                 //     ],
//                 //     type: ApplePayButtonType.plain,
//                 //     style: ApplePayButtonStyle.black,
//                 //     width: 200,
//                 //     height: 44,
//                 //     onPaymentResult: (result) {
//                 //       debugPrint('🔔 ApplePay raw result → ${jsonEncode(result)}');
//                 //
//                 //       final paymentData = result['paymentData'];
//                 //       if (paymentData == null || paymentData.isEmpty) {
//                 //         ScaffoldMessenger.of(context).showSnackBar(
//                 //           SnackBar(content: Text('Apple Pay returned no paymentData')),
//                 //         );
//                 //         return;
//                 //       }
//                 //
//                 //       final nonce = jsonEncode(paymentData);
//                 //
//                 //       context.read<PaymentBloc>().add(
//                 //         SubmitApplePay(
//                 //           paymentNonce: nonce,
//                 //           stationId: stationId,
//                 //         ),
//                 //       );
//                 //     },
//                 //     loadingIndicator: const CircularProgressIndicator(),
//                 //   ),
//                 // );
//                 return Padding(
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Text('Tap to pay with Apple Pay'),
//                       SizedBox(height: 24),
//                       SizedBox(
//                         width: 200,
//                         height: 44,
//                         child: ApplePayButton(
//                           paymentConfiguration: PaymentConfiguration.fromJsonString(applePayJson),
//                           paymentItems: [PaymentItem(label: 'Recharge', amount: '4.99')],
//                           type: ApplePayButtonType.plain,
//                           style: ApplePayButtonStyle.black,
//                           onPaymentResult: (result) {
//                             debugPrint('🔔 ApplePay raw result → ${jsonEncode(result)}');
//                             final paymentData = result['paymentData'];
//                             if (paymentData == null || paymentData.isEmpty) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(content: Text('Apple Pay returned no paymentData')),
//                               );
//                               return;
//                             }
//                             final nonce = jsonEncode(paymentData);
//                             context.read<PaymentBloc>().add(
//                               SubmitApplePay(paymentNonce: nonce, stationId: stationId),
//                             );
//                           },
//                           loadingIndicator: CircularProgressIndicator(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//
//               }
//
//               // Fallback for unexpected states
//               return Center(child: Text('Initializing...'));
//             },
//           ),
//         ),
//       ),
//     );
//   }
// }
//

// lib/ui/screens/payment_screen.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pay/pay.dart';
import 'package:powerbank_app/apple_pay_config.dart';
import '../bloc/payment_bloc.dart';
import '../bloc/payment_event.dart';
import '../bloc/payment_state.dart';
import '../services/payment_service.dart';

class PaymentScreen extends StatelessWidget {
  final String stationId;
  const PaymentScreen({super.key, required this.stationId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
      PaymentBloc(PaymentService())..add(InitPaymentFlow(stationId)),
      child: Scaffold(
        appBar: AppBar(title: Text('Rent Power Bank')),
        body: SafeArea(
          child: BlocBuilder<PaymentBloc, PaymentState>(
            builder: (context, state) {
              debugPrint('🔄 PaymentState: ${state.runtimeType}');
              if (state is PaymentLoading) {
                return Center(child: CircularProgressIndicator());
              }
              if (state is PaymentError) {
                return Center(child: Text('Error: ${state.message}'));
              }
              if (state is PaymentSuccess) {
                Future.microtask(() => context.go('/success'));
                return Center(child: Text('Redirecting...'));
              }
              // state is PaymentReady (or any fallback)
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Tap to pay with Apple Pay'),
                    SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      height: 44,
                      child: ApplePayButton(
                        paymentConfiguration:
                        PaymentConfiguration.fromJsonString(applePayJson),
                        paymentItems: [
                          PaymentItem(label: 'Recharge', amount: '4.99'),
                        ],
                        type: ApplePayButtonType.plain,
                        style: ApplePayButtonStyle.black,
                        onPaymentResult: (result) {
                          debugPrint(
                              '🔔 ApplePay raw result → ${jsonEncode(result)}');
                          final paymentData = result['token'] as String?;
                          if (paymentData == null || paymentData.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                  Text('Apple Pay returned no data')),
                            );
                            return;
                          }
                          final nonce = jsonEncode(paymentData);
                          context.read<PaymentBloc>().add(
                            SubmitApplePay(
                              paymentNonce: nonce,
                              stationId: stationId,
                            ),
                          );
                        },
                        loadingIndicator: CircularProgressIndicator(),
                      ),
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
