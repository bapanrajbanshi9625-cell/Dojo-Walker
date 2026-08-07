import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/mobile_login_screen.dart';
import 'features/walk_tracking/presentation/main_navigation_screen.dart';

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
