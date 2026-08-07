import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/presentation/mobile_login_screen.dart';
import 'features/walk_tracking/presentation/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  User? currentUser = FirebaseAuth.instance.currentUser;
  
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
      home: initialScreen,
    );
  }
}
