import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/presentation/mobile_login_screen.dart';
import 'features/walk_tracking/presentation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // <--- Firebase yahan start hona chahiye
  runApp(const DojoWalkerApp());
}

class DojoWalkerApp extends StatelessWidget {
  const DojoWalkerApp({super.key});

  Widget _getInitialScreen() {
    User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      return const MainNavigationScreen();
    } else {
      return const MobileLoginScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo Walker - Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: _getInitialScreen(),
    );
  }
}
