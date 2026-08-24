// File location: lib/app.dart

import 'package:flutter/material.dart';

import 'core/network/network_monitor.dart';
import 'core/services/app_state_service.dart';
import 'core/theme/dojo_walker_theme.dart';
import 'screens/no_network_screen.dart';
import 'screens/splash_screen.dart';

class DojoWalkerApp extends StatefulWidget {
  final String? startupError;

  const DojoWalkerApp({
    super.key,
    this.startupError,
  });

  @override
  State<DojoWalkerApp> createState() =>
      _DojoWalkerAppState();
}

class _DojoWalkerAppState
    extends State<DojoWalkerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();

    // ==========================================================
    // APP LIFECYCLE
    // ==========================================================

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  // ============================================================
  // APP LIFECYCLE CHANGED
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      AppStateService.instance.refresh();
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isNetworkError =
        _isNetworkError(widget.startupError);

    Widget startScreen;

    if (isNetworkError) {
      startScreen = const NoNetworkScreen();
    } else if (widget.startupError != null) {
      startScreen = StartupErrorScreen(
        error: widget.startupError!,
      );
    } else {
      startScreen = const SplashScreen();
    }

    return MaterialApp(
      title: 'Dojo Walker - Buddy',
      debugShowCheckedModeBanner: false,

      // ========================================================
      // DOJO WALKER GLOBAL THEME
      // ========================================================

      theme: DojoWalkerTheme.light(),

      // ========================================================
      // START SCREEN
      // ========================================================

      home: NetworkMonitor(
        child: startScreen,
      ),
    );
  }

  // ============================================================
  // NETWORK ERROR CHECK
  // ============================================================

  bool _isNetworkError(
    String? error,
  ) {
    if (error == null) {
      return false;
    }

    final String text =
        error.toLowerCase();

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

// ================================================================
// STARTUP ERROR SCREEN
// ================================================================

class StartupErrorScreen extends StatelessWidget {
  final String error;

  const StartupErrorScreen({
    super.key,
    required this.error,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          DojoWalkerColors.background,

      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 64,
                  color: DojoWalkerColors.error,
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'Dojo Walker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight:
                        FontWeight.bold,
                    color:
                        DojoWalkerColors.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                const Text(
                  'App startup failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        DojoWalkerColors.textPrimary,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                Text(
                  error,
                  textAlign:
                      TextAlign.center,
                  style: const TextStyle(
                    color:
                        DojoWalkerColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
