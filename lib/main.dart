// File location: lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? startupError;

  // --------------------------------------------------
  // Firebase initialization
  // --------------------------------------------------
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization error: $e');
    debugPrintStack(stackTrace: stackTrace);

    final error = e.toString().toLowerCase();

    final isNetworkError =
        error.contains('network') ||
        error.contains('timeout') ||
        error.contains('socket') ||
        error.contains('connection') ||
        error.contains('unavailable') ||
        error.contains('internet');

    if (isNetworkError) {
      startupError = 'NO_NETWORK';
    } else {
      startupError = 'Firebase initialization failed:\n$e';
    }
  }

  // --------------------------------------------------
  // Start application
  // --------------------------------------------------
  runApp(
    DojoWalkerApp(
      startupError: startupError,
    ),
  );
}
