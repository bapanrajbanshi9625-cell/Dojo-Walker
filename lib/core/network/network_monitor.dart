import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../screens/no_network_screen.dart';

class NetworkMonitor extends StatefulWidget {
  final Widget child;

  const NetworkMonitor({
    super.key,
    required this.child,
  });

  @override
  State<NetworkMonitor> createState() => _NetworkMonitorState();
}

class _NetworkMonitorState extends State<NetworkMonitor> {
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _offline = false;

  @override
  void initState() {
    super.initState();

    _checkInternet();

    _subscription = Connectivity()
        .onConnectivityChanged
        .listen(_handleConnectivity);
  }

  Future<void> _checkInternet() async {
    final result = await _hasInternet();

    if (!mounted) return;

    setState(() {
      _offline = !result;
    });
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await Connectivity().checkConnectivity();

      final connected = result.any(
        (item) =>
            item == ConnectivityResult.mobile ||
            item == ConnectivityResult.wifi ||
            item == ConnectivityResult.ethernet ||
            item == ConnectivityResult.vpn,
      );

      if (!connected) {
        return false;
      }

      final lookup = await InternetAddress.lookup(
        'firebase.google.com',
      ).timeout(
        const Duration(seconds: 5),
      );

      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleConnectivity(
    List<ConnectivityResult> results,
  ) async {
    final internetAvailable = await _hasInternet();

    if (!mounted) return;

    setState(() {
      _offline = !internetAvailable;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_offline) {
      return const NoNetworkScreen();
    }

    return widget.child;
  }
}
