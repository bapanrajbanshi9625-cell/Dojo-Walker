// File location: lib/screens/splash_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/profile_setup/services/profile_setup_service.dart';
import 'main_navigation_screen.dart';
import 'mobile_login_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {
  String? _errorMessage;

  bool _isChecking = true;

  @override
  void initState() {
    super.initState();

    // Firebase/Auth check start
    _checkLoginAndNavigate();
  }

  // ============================================================
  // CHECK LOGIN + FIRESTORE PROFILE
  // ============================================================

  Future<void> _checkLoginAndNavigate() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    try {
      // ========================================================
      // CURRENT FIREBASE USER
      // ========================================================

      final User? user =
          FirebaseAuth.instance.currentUser;

      // ========================================================
      // USER NOT LOGGED IN
      // ========================================================

      if (user == null) {
        debugPrint(
          'Splash: No Firebase user found.',
        );

        if (!mounted) {
          return;
        }

        _goTo(
          const MobileLoginScreen(),
        );

        return;
      }

      // ========================================================
      // FIREBASE UID
      // ========================================================

      debugPrint(
        '========================================',
      );
      debugPrint(
        'SPLASH PROFILE CHECK',
      );
      debugPrint(
        'Firebase UID: ${user.uid}',
      );
      debugPrint(
        '========================================',
      );

      // ========================================================
      // FIRESTORE PROFILE CHECK
      //
      // IMPORTANT:
      // Splash screen remains visible while this request
      // is running.
      // ========================================================

      final bool profileCompleted =
          await ProfileSetupService
              .isWalkerProfileCompleted(
        authUid: user.uid,
      );

      debugPrint(
        'Profile Completed: $profileCompleted',
      );

      if (!mounted) {
        return;
      }

      // ========================================================
      // PROFILE INCOMPLETE
      // ========================================================

      if (!profileCompleted) {
        debugPrint(
          'Profile incomplete '
          '→ Mandatory Profile Setup',
        );

        _goTo(
          const MandatoryProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // PROFILE COMPLETE
      // ========================================================

      debugPrint(
        'Profile complete '
        '→ Main Navigation',
      );

      _goTo(
        const MainNavigationScreen(),
      );
    } catch (e) {
      // ========================================================
      // FIREBASE / FIRESTORE ERROR
      // ========================================================

      debugPrint(
        '========================================',
      );
      debugPrint(
        'SPLASH PROFILE CHECK ERROR',
      );
      debugPrint(
        '$e',
      );
      debugPrint(
        '========================================',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;

        _errorMessage =
            'Unable to verify your profile.\n\n'
            'Please check your internet connection '
            'and try again.';
      });
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goTo(Widget screen) {
    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ======================================================
          // SPLASH IMAGE
          // ======================================================

          Image.asset(
            'assets/dojo_walker_splash.png',
            fit: BoxFit.cover,
          ),

          // ======================================================
          // BOTTOM STATUS
          // ======================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 65,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==================================================
                // NORMAL FIREBASE CHECKING
                // ==================================================

                if (_errorMessage == null) ...[
                  const Text(
                    'Getting things ready...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // =================================================
                  // ONLY CIRCULAR LOADING
                  // NO PERCENTAGE
                  // NO LINE PROGRESS BAR
                  // =================================================

                  const SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      value: null,
                      color: Colors.white,
                    ),
                  ),
                ],

                // ==================================================
                // FIREBASE ERROR
                // ==================================================

                if (_errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: _isChecking
                        ? null
                        : _checkLoginAndNavigate,
                    child: const Text(
                      'Try Again',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
