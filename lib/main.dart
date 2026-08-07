import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';
// Correct imports based on your GitHub folder structure
import 'features/auth/presentation/mobile_login_screen.dart';
import 'features/walk_tracking/presentation/main_navigation_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  // Check if a user is already logged in
  User? currentUser = FirebaseAuth.instance.currentUser;
  
  // Decide the initial screen based on authentication state
  // If user exists, open MainNavigationScreen, otherwise open MobileLoginScreen
  Widget initialScreen = currentUser != null 
      ? const MainNavigationScreen() 
      : const MobileLoginScreen();

  runApp(DojoWalkerApp(initialScreen: initialScreen));
}

class DojoWalkerApp extends StatelessWidget {
  final Widget initialScreen;

  const DojoWalkerApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo Walker - Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      // Set the dynamic initial screen so it persists login across app restarts
      home: initialScreen,
    );
  }
}
