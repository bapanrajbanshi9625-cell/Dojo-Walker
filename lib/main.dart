import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart'; // This import is required
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isLoggedIn = false;

  try {
    // Initialize Firebase with options
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  try {
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  } catch (e) {
    debugPrint("SharedPreferences error: $e");
    isLoggedIn = false;
  }
  
  runApp(DojoWalkerApp(isLoggedIn: isLoggedIn));
}
