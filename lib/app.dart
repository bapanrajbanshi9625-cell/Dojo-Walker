// File location: lib/app.dart
import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/mobile_login_screen.dart';
import 'screens/main_navigation_screen.dart';

class DojoWalkerApp extends StatelessWidget {
  final bool isLoggedIn;
  const DojoWalkerApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo Walker - Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: isLoggedIn ? const MainNavigationScreen() : const MobileLoginScreen(),
    );
  }
}
