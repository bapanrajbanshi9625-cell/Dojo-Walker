import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'features/auth/presentation/mobile_login_screen.dart';
import 'features/walk_tracking/presentation/main_navigation_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DojoWalkerApp());
}

class DojoWalkerApp extends StatelessWidget {
  const DojoWalkerApp({super.key});

  Future<Widget> _getInitialScreen() async {
    await Firebase.initializeApp();
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
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: CircularProgressIndicator(
                  color: Colors.orange,
                ),
              ),
            );
          }
          
          if (snapshot.hasError) {
            return Scaffold(
              backgroundColor: Colors.white,
              body: Center(
                child: Text('Initialization Error: ${snapshot.error}'),
              ),
            );
          }

          return snapshot.data ?? const MobileLoginScreen();
        },
      ),
    );
  }
}
