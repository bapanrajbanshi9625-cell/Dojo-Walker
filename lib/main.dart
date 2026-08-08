import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool isLoggedIn = false;

  try {
    // Initialize Firebase safely
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }

  try {
    // Read SharedPreferences safely to prevent getting stuck in a loop
    final prefs = await SharedPreferences.getInstance();
    isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  } catch (e) {
    debugPrint("SharedPreferences error: $e");
    isLoggedIn = false; // Default to the login page if an error occurs
  }
  
  runApp(DojoWalkerApp(isLoggedIn: isLoggedIn));
}
