// File location: lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'core/services/app_state_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupError;

  // ============================================================
  // FIREBASE INITIALIZATION
  // ============================================================

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');

    debugPrintStack(
      stackTrace: stackTrace,
    );

    final String error =
        e.toString().toLowerCase();

    final bool isNetworkError =
        error.contains('network') ||
        error.contains('timeout') ||
        error.contains('socket') ||
        error.contains('connection') ||
        error.contains('unavailable') ||
        error.contains('internet');

    if (isNetworkError) {
      startupError = 'NO_NETWORK';
    } else {
      startupError =
          'Firebase initialization failed:\n$e';
    }
  }

  // ============================================================
  // APP STATE INITIALIZATION
  // ============================================================
  //
  // Firebase successfully initialize होने के बाद ही
  // AppStateService initialize होगा.
  //
  // इसका काम:
  // - Firebase user recover करना
  // - active walk recover करना
  // - live walk state monitor करना
  // - app restart के बाद state restore करना
  //
  // AppStateService fail होने पर application बंद नहीं होगी.
  // ============================================================

  if (startupError == null) {
    try {
      await AppStateService.instance.initialize();
    } catch (e, stackTrace) {
      debugPrint(
        'App state initialization error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // START APPLICATION
  // ============================================================

  runApp(
    DojoWalkerApp(
      startupError: startupError,
    ),
  );
}
