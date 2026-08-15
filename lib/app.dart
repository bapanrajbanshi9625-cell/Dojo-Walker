// File location: lib/app.dart

import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';

class DojoWalkerApp extends StatelessWidget {
  final String? startupError;

  const DojoWalkerApp({
    super.key,
    this.startupError,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dojo Walker - Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: startupError != null
          ? StartupErrorScreen(
              error: startupError!,
            )
          : const SplashScreen(),
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  final String error;

  const StartupErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dojo Walker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'App startup failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
