import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase safely
  await Firebase.initializeApp();

  // Check login status locally from mobile storage (Prevents black screen & server lag)
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  
  // Run the application with the login status
  runApp(DojoWalkerApp(isLoggedIn: isLoggedIn));
}
