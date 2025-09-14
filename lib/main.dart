import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:powerbank_app/bloc/payment_bloc.dart'; // Assuming your BLoC is here
import 'package:powerbank_app/services/payment_service.dart';
import 'package:powerbank_app/screens/payment_screen.dart';
import 'package:powerbank_app/screens/success_screen.dart';
import 'package:powerbank_app/screens/qr_code_screen.dart'; // Placeholder for QR

// Import your JS interop manager
// Ensure this file is structured correctly for conditional import if you ever plan non-web targets
// For now, assuming web-only for this test.
import 'package:powerbank_app/js_interop_manager.dart';
import 'package:flutter/foundation.dart' show kIsWeb; // For kIsWeb check


void main() {
  // Ensure services are initialized
  final paymentService = PaymentService();

  // Create the JS Interop Manager. It might need the BLoC or a way to emit events/results.
  // Or the BLoC itself will use the JSInteropManager.
  // For simplicity here, let's assume the BLoC will instantiate and use the JSInteropManager.
  final jsInteropManager = JSInteropManager(); // Your class that handles JS calls and callbacks

  final paymentBloc = PaymentBloc(
    service: paymentService,
    jsInteropManager: jsInteropManager, // Pass it to the BLoC
  );

  // === THIS CALLBACK REGISTRATION IN main() IS LIKELY NOT THE BEST PLACE ===
  // The BLoC, when it initiates a payment, should be the one setting up the specific
  // completer or callback mechanism within the JSInteropManager for *that specific payment attempt*.
  // A global callback like this can be tricky with the BLoC's lifecycle and multiple payment attempts.
  //
  // registerApplePayCallback((nonce) { // This `registerApplePayCallback` is custom
  //   final stationId = Uri.base.queryParameters['stationId'] ?? ''; // This might be too late or incorrect context
  //   paymentBloc.add(
  //     SubmitPaymentViaBraintreeDropIn(stationId: stationId, amount: '', currencyCode: ''), // Event name needs update
  //   );
  // });
  // =======================================================================

  runApp(MyApp(paymentBloc: paymentBloc));
}

class MyApp extends StatelessWidget {
  final PaymentBloc paymentBloc;

  const MyApp({required this.paymentBloc, super.key});

  @override
  Widget build(BuildContext context) {
    // For testing QR flow, use a default stationId
    const String defaultStationId = 'RECH082203000350';

    final router = GoRouter(
      // For a web app, the initialLocation might often be determined by the URL directly.
      // If the app is always meant to start at a payment flow for this test,
      // initialLocation could be `/pay?stationId=...`
      initialLocation: kIsWeb ? Uri.base.toString().replaceFirst(Uri.base.origin, '') : '/pay?stationId=$defaultStationId',
      // Alternatively, if deep linking / QR scan is properly simulated by directly opening the URL:
      // initialLocation: Uri.base.toString().contains('stationId=')
      //     ? Uri.base.toString().replaceFirst(Uri.base.origin, '')
      //     : '/placeholder-qr', // Fallback if no stationId in URL

      routes: [
        // Placeholder for QR screen if needed, or if initial URL doesn't have stationId
        GoRoute(
          path: '/placeholder-qr',
          builder: (_, __) => const PlaceholderQRScreen(defaultStationId: defaultStationId),
        ),
        GoRoute(
            path: '/pay',
            builder: (context, state) {
              // Extract stationId from query parameters.
              // If directly navigating via URL (simulating QR scan redirect), this will have the value.
              String stationId = state.uri.queryParameters['stationId'] ?? defaultStationId;

              // It's generally better for the screen to dispatch an event to the BLoC
              // to initialize payment with the stationId, rather than PaymentBloc
              // trying to read Uri.base globally.
              return PaymentScreen(stationId: stationId);
            }),
        GoRoute(
          path: '/success',
          builder: (_, __) => const SuccessScreen(), // Your existing SuccessScreen
        ),
        // Optional: A root redirector if you always want to go to /pay for this test
        GoRoute(
          path: '/',
          redirect: (BuildContext context, GoRouterState state) {
            String stationIdFromUrl = Uri.base.queryParameters['stationId'] ?? defaultStationId;
            if (Uri.base.path == '/' && (stationIdFromUrl == defaultStationId && !Uri.base.queryParameters.containsKey('stationId'))) {
              // If at root and no stationId in URL, maybe go to placeholder or default pay
              return '/placeholder-qr';
            } else if (Uri.base.path == '/' && stationIdFromUrl != defaultStationId) {
              return '/pay?stationId=$stationIdFromUrl';
            }
            // If already on /pay or other valid paths, no redirect
            return null;
          },
          // builder: (context, state) => Container(), // Must have builder or redirect
        ),
      ],
      // Log router errors for debugging
      onException: (_, GoRouterState state, GoRouter router) {
        debugPrint('GoRouter Exception: ${state.error}');
        // router.go('/error'); // Optional: redirect to an error screen
      },
    );

    return BlocProvider.value(
      value: paymentBloc,
      child: MaterialApp.router(
        title: 'PowerBank App',
        routerConfig: router,
        theme: ThemeData(
          fontFamily: 'SF Pro Display', // Ensure this font is available for web
          // You might want to define primary colors, button themes etc. to match Figma
          // e.g. primaryColor: Colors.black,
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
