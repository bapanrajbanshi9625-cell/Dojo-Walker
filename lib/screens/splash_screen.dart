// File location: lib/screens/splash_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';
import 'mobile_login_screen.dart';

class SplashScreen extends StatefulWidget {
  final bool isLoggedIn;

  const SplashScreen({
    super.key,
    required this.isLoggedIn,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  double progress = 0.0;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startLoading();
  }

  void startLoading() {
    timer = Timer.periodic(
      const Duration(milliseconds: 80),
      (timer) {
        if (!mounted) return;

        setState(() {
          progress += 0.01;

          if (progress >= 1.0) {
            progress = 1.0;
            timer.cancel();

            Future.delayed(const Duration(milliseconds: 300), () {
              if (!mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => widget.isLoggedIn
                      ? const MainNavigationScreen()
                      : const MobileLoginScreen(),
                ),
              );
            });
          }
        });
      },
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [

          // =====================================
          // FULL SPLASH PNG
          // =====================================
          Image.asset(
            'assets/dojo_walker_splash.png',
            fit: BoxFit.cover,
          ),

          // =====================================
          // REAL LOADING
          // =====================================
          Positioned(
            left: 60,
            right: 60,
            bottom: 55,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                Text(
                  progress < 1.0
                      ? 'Getting things ready...'
                      : 'Ready!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 16),

                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
                    backgroundColor: Colors.white24,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
