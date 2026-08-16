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

  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  // =====================================================
  // CHECK LOGIN + FIRESTORE PROFILE
  // =====================================================

  Future<void> _checkLoginAndNavigate() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      // =================================================
      // USER NOT LOGGED IN
      // =================================================

      if (user == null) {
        _goTo(
          const MobileLoginScreen(),
        );
        return;
      }

      // =================================================
      // FIREBASE UID
      // =================================================

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

      // =================================================
      // CHECK FIRESTORE
      // =================================================

      final bool profileCompleted =
          await ProfileSetupService
              .isWalkerProfileCompleted(
        walkerUid: user.uid,
      );

      debugPrint(
        'Profile Completed: $profileCompleted',
      );

      if (!mounted) {
        return;
      }

      // =================================================
      // PROFILE INCOMPLETE
      // =================================================

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

      // =================================================
      // PROFILE COMPLETE
      // =================================================

      debugPrint(
        'Profile complete '
        '→ Main Navigation',
      );

      _goTo(
        const MainNavigationScreen(),
      );
    } catch (e) {
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

      // =================================================
      // IMPORTANT
      //
      // Firebase/Firestore confirmation nahi mila.
      // Is situation mein Mandatory Profile par
      // automatically NAHI bhejna hai.
      // =================================================

      setState(() {
        _errorMessage =
            'Unable to verify your profile.\n\n'
            'Please check your internet connection '
            'and try again.';
      });
    }
  }

  // =====================================================
  // NAVIGATION
  // =====================================================

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

  // =====================================================
  // BUILD
  // =====================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/dojo_walker_splash.png',
            fit: BoxFit.cover,
          ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 65,
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                if (_errorMessage == null)
                  const Text(
                    'Getting things ready...',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                if (_errorMessage != null)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 25,
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign:
                          TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 18),

                if (_errorMessage == null)
                  Theme(
                    data: Theme.of(context)
                        .copyWith(
                      colorScheme:
                          Theme.of(context)
                              .colorScheme
                              .copyWith(
                                primary:
                                    Colors.white,
                              ),
                    ),
                    child: const SizedBox(
                      width: 30,
                      height: 30,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 3,
                      ),
                    ),
                  ),

                if (_errorMessage != null)
                  ElevatedButton(
                    onPressed:
                        _checkLoginAndNavigate,
                    child:
                        const Text('Try Again'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
