// File location: lib/app.dart

import 'package:flutter/material.dart';

import 'core/network/network_monitor.dart';
import 'core/theme/app_theme.dart';
import 'screens/no_network_screen.dart';
import 'screens/splash_screen.dart';

class DojoWalkerApp extends StatelessWidget {
  final String? startupError;

  const DojoWalkerApp({
    super.key,
    this.startupError,
  });

  @override
  Widget build(BuildContext context) {
    final bool isNetworkError = _isNetworkError(startupError);

    Widget startScreen;

    if (isNetworkError) {
      startScreen = const NoNetworkScreen();
    } else if (startupError != null) {
      startScreen = StartupErrorScreen(
        error: startupError!,
      );
    } else {
      startScreen = const SplashScreen();
    }

    return MaterialApp(
      title: 'Dojo Walker - Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      home: NetworkMonitor(
        child: startScreen,
      ),
    );
  }

  bool _isNetworkError(String? error) {
    if (error == null) {
      return false;
    }

    final text = error.toLowerCase();

    return text.contains('no_network') ||
        text.contains('network') ||
        text.contains('timeout') ||
        text.contains('socket') ||
        text.contains('connection') ||
        text.contains('unavailable') ||
        text.contains('internet') ||
        text.contains('failed host lookup') ||
        text.contains('network is unreachable');
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
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
