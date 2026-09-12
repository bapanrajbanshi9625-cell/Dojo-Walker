// File location: lib/app.dart

import 'dart:async';

import 'package:flutter/material.dart';

import 'core/network/network_monitor.dart';
import 'core/services/app_state_service.dart';
import 'core/theme/dojo_walker.dart';
import 'features/insta_walk/models/insta_walk_request.dart';
import 'features/insta_walk/services/insta_walk_request_service.dart';
import 'features/incoming_walk/screens/incoming_walk_request_screen.dart';
import 'screens/no_network_screen.dart';
import 'screens/splash_screen.dart';

class DojoWalkerApp extends StatefulWidget {
  final String? startupError;

  const DojoWalkerApp({
    super.key,
    this.startupError,
  });

  @override
  State<DojoWalkerApp> createState() => _DojoWalkerAppState();
}

class _DojoWalkerAppState extends State<DojoWalkerApp>
    with WidgetsBindingObserver {
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  StreamSubscription<List<InstaWalkRequest>>?
      _incomingRequestSubscription;

  bool _incomingScreenOpen = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _startIncomingWalkMonitor();
  }

  void _startIncomingWalkMonitor() {
    _incomingRequestSubscription?.cancel();

    _incomingRequestSubscription =
        InstaWalkRequestService.instance.pendingRequestsStream().listen(
      _handleIncomingWalkRequests,
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          'Global incoming walk monitor error: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      },
    );
  }

  void _handleIncomingWalkRequests(
    List<InstaWalkRequest> requests,
  ) {
    if (!mounted) {
      return;
    }

    if (requests.isEmpty) {
      return;
    }

    if (_incomingScreenOpen) {
      return;
    }

    final InstaWalkRequest request = requests.first;

    unawaited(
      _openIncomingWalkScreen(request),
    );
  }

  Future<void> _openIncomingWalkScreen(
    InstaWalkRequest request,
  ) async {
    if (!mounted || _incomingScreenOpen) {
      return;
    }

    _incomingScreenOpen = true;

    try {
      await WidgetsBinding.instance.endOfFrame;

      if (!mounted) {
        _incomingScreenOpen = false;
        return;
      }

      final NavigatorState? navigator =
          _navigatorKey.currentState;

      if (navigator == null) {
        debugPrint(
          'Unable to open incoming walk screen: '
          'Navigator is not ready.',
        );

        _incomingScreenOpen = false;
        return;
      }

      await navigator.push(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) {
            return IncomingWalkRequestScreen(
              request: request,
            );
          },
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'Unable to open incoming walk screen: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    } finally {
      _incomingScreenOpen = false;
    }
  }

  @override
  void dispose() {
    _incomingRequestSubscription?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      AppStateService.instance.refresh();

      _startIncomingWalkMonitor();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isNetworkError =
        _isNetworkError(widget.startupError);

    final Widget startScreen;

    if (isNetworkError) {
      startScreen = const NoNetworkScreen();
    } else if (widget.startupError != null &&
        widget.startupError!.trim().isNotEmpty) {
      startScreen = StartupErrorScreen(
        error: widget.startupError!,
      );
    } else {
      startScreen = const SplashScreen();
    }

    return MaterialApp(
      title: 'Dojo Walker',
      debugShowCheckedModeBanner: false,
      theme: DojoWalkerTheme.light,

      // ========================================================
      // GLOBAL NAVIGATOR
      //
      // Incoming Walk can now open from the global request
      // monitor even though this State is above MaterialApp.
      // ========================================================

      navigatorKey: _navigatorKey,

      home: NetworkMonitor(
        child: startScreen,
      ),
    );
  }

  bool _isNetworkError(String? error) {
    if (error == null || error.trim().isEmpty) {
      return false;
    }

    final String text = error.toLowerCase();

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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoWalkerColors.background,
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
                  color: DojoWalkerColors.error,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Dojo Walker',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DojoWalkerColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'App startup failed',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: DojoWalkerColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DojoWalkerColors.textSecondary,
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
