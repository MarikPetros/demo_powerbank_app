import 'package:flutter/foundation.dart' show kIsWeb; // For kIsWeb check
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:powerbank_app/bloc/payment_bloc.dart'; // Assuming your BLoC is here
// Import your JS interop manager
// Ensure this file is structured correctly for conditional import if you ever plan non-web targets
// For now, assuming web-only for this test.
import 'package:powerbank_app/js_interop_manager.dart';
import 'package:powerbank_app/screens/payment_screen.dart';
import 'package:powerbank_app/screens/qr_code_screen.dart'; // Placeholder for QR
import 'package:powerbank_app/screens/success_screen.dart';
import 'package:powerbank_app/services/payment_service.dart';

void main() {
  // Ensure services are initialized
  final paymentService = PaymentService();

  // Create the JS Interop Manager. It might need the BLoC or a way to emit events/results.
  // Or the BLoC itself will use the JSInteropManager.
  // For simplicity here, let's assume the BLoC will instantiate and use the JSInteropManager.
  final jsInteropManager =
      JSInteropManager(); // Your class that handles JS calls and callbacks

  final paymentBloc = PaymentBloc(
    paymentService: paymentService,
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

  runApp(
    // MyApp(paymentBloc: paymentBloc)
    TestApp(),
  );
}

// import 'package:flutter/foundation.dart' show kIsWeb; // Already imported

class MyApp extends StatelessWidget {
  final PaymentBloc paymentBloc;

  const MyApp({required this.paymentBloc, super.key});

  @override
  Widget build(BuildContext context) {
    const String defaultStationId = 'RECH082203000350';

    final router = GoRouter(
      // Let GoRouter determine the initial location from the browser's URL.
      // If the URL is just "http://localhost:5555/", initialLocation will be "/".
      // If "http://localhost:5555/pay?stationId=123", initialLocation will be "/pay?stationId=123".
      // No need for complex Uri.base manipulation here if your web server serves index.html for all paths.
      initialLocation: kIsWeb
          ? Uri.base.toString().replaceFirst(
              Uri.base.origin,
              '',
            ) // Standard way to get path + query
          : '/?stationId=$defaultStationId',

      // For non-web, keep your default behavior
      routes: [
        GoRoute(
          path: '/',
          redirect: (BuildContext context, GoRouterState state) {
            // This redirect is for when the user lands on the absolute root "/".
            // It will decide whether to show a QR placeholder or go to payment screen.

            // Get stationId from the *actual current URL query parameters* if any.
            // state.uri.queryParameters are the query params for the path being matched ('/')
            // For the root redirect, we're interested in the browser's actual URL params.
            final String? stationIdFromBrowserUrl =
                Uri.base.queryParameters['stationId'];

            if (stationIdFromBrowserUrl != null &&
                stationIdFromBrowserUrl.isNotEmpty) {
              // If stationId is in the browser URL, redirect to pay screen with it.
              return '/?stationId=$stationIdFromBrowserUrl';
            } else {
              // No stationId in URL, or at root, go to QR placeholder.
              // This simplifies: if you're at "/" and don't have a stationId in the
              // URL bar, you see the QR screen.
              return '/placeholder-qr';
            }
            // Note: The previous logic for `stationIdFromUrl == defaultStationId` and
            // `!Uri.base.queryParameters.containsKey('stationId')` was a bit complex.
            // This revised logic is more direct: has stationId in URL -> /pay, else -> /placeholder-qr.
          },
        ),
        GoRoute(
          path: '/placeholder-qr',
          builder: (context, state) =>
              const PlaceholderQRScreen(defaultStationId: defaultStationId),
        ),
        GoRoute(
          path: '/pay',
          builder: (context, state) {
            // Extract stationId from GoRouter's state for this route.
            // This will have the value if redirected from "/" or if navigated directly.
            String stationId =
                state.uri.queryParameters['stationId'] ?? defaultStationId;

            // If stationId somehow ended up empty or as the default AND we really
            // expect one from a QR scan, we could add a fallback, but the root redirect handles most cases.
            if (stationId.isEmpty ||
                (stationId == defaultStationId &&
                    !state.uri.queryParameters.containsKey('stationId'))) {
              // This condition might be redundant if the '/' redirect is robust.
              // Consider if you really need the defaultStationId here or if it should always come from query.
              // For now, using it as a fallback.
              print(
                "Warning: Navigated to /pay without a specific stationId, using default: $defaultStationId",
              );
            }
            return PaymentScreen(stationId: stationId);
          },
        ),
        GoRoute(path: '/success', builder: (_, __) => const SuccessScreen()),
      ],
      onException: (_, GoRouterState state, GoRouter router) {
        // Use debugPrint for Flutter console, console.log for browser JS console
        debugPrint(
          'GoRouter Exception: Path "${state.uri}" resulted in error: ${state.error}',
        );
        if (state.error != null) {
          // Log the full error if possible
          debugPrint('GoRouter Exception Details: ${state.error.toString()}');
        }
        // Redirect to a dedicated error screen or a safe fallback like placeholder-qr
        // router.go('/placeholder-qr'); // Avoid potential redirect loops to an error page
      },
      // observers: [ GoRouterObserver() ], // Add for more detailed logging if needed
    );

    return BlocProvider.value(
      value: paymentBloc,
      child: MaterialApp.router(
        title: 'PowerBank App',
        routerConfig: router,
        theme: ThemeData(fontFamily: 'SF Pro Display'),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

// Optional: A simple observer for debugging
// class GoRouterObserver extends NavigatorObserver {
//   @override
//   void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
//     debugPrint('GoRouter: Pushed ${route.settings.name}');
//   }
//   @override
//   void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
//     debugPrint('GoRouter: Popped ${route.settings.name}');
//   }
//   // ... other overrides
// }

class TestApp extends StatelessWidget {
   TestApp({super.key});

  // final String?  defaultStationId1=
  // Uri.base.queryParameters['stationId'];

  @override
  Widget build(BuildContext context) {
    return Center(child: Text('The station ID is: RECH082203000350'));
  }
}
