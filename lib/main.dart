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

    startupError = 'Firebase initialization failed:\n$e';
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
