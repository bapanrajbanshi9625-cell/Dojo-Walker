import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase safely
  await Firebase.initializeApp();
  
  // Run the application
  runApp(const DojoWalkerApp());
}
