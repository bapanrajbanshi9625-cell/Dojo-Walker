import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/mobile_login_screen.dart';

class DojoWalkerApp extends StatelessWidget {
  const DojoWalkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo Walker',
      theme: AppTheme.lightTheme,
      home: const MobileLoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
