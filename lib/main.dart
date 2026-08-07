import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';
// Note: Import your home page and login page files here if they are in separate files
// import 'pages/home_page.dart';
// import 'pages/login_page.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();

  // Check if a user is already logged in
  User? currentUser = FirebaseAuth.instance.currentUser;
  
  // Decide the initial route based on authentication state
  // Replace 'LoginPage()' and 'HomePage()' with your actual widget class names
  Widget initialScreen = currentUser != null ? const HomePage() : const LoginPage();

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
      // Set the dynamic initial screen so it doesn't log out on restart
      home: initialScreen,
    );
  }
}
