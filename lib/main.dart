// File location: lib/main.dart

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool isLoggedIn = false;
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
  // SharedPreferences
  // --------------------------------------------------
  try {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  } catch (e, stackTrace) {
    debugPrint('SharedPreferences error: $e');
    debugPrintStack(stackTrace: stackTrace);

    isLoggedIn = false;
  }

  // --------------------------------------------------
  // Start application
  // --------------------------------------------------
  runApp(
    DojoWalkerApp(
      isLoggedIn: isLoggedIn,
      startupError: startupError,
    ),
  );
}
