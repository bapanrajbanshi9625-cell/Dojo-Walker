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
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginAndNavigate();
  }

  // =====================================================
  // CHECK LOGIN + PROFILE
  // =====================================================

  Future<void> _checkLoginAndNavigate() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser;

      // =================================================
      // USER NOT LOGGED IN
      // =================================================

      if (user == null) {
        _goTo(const MobileLoginScreen());
        return;
      }

      // =================================================
      // USER LOGGED IN
      // CHECK WALKER PROFILE
      // =================================================

      debugPrint('========================================');
      debugPrint('SPLASH PROFILE CHECK');
      debugPrint('Firebase UID: ${user.uid}');
      debugPrint('========================================');

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
          'Profile incomplete → Mandatory Profile Setup',
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
        'Profile complete → Main Navigation',
      );

      _goTo(
        const MainNavigationScreen(),
      );
    } catch (e) {
      debugPrint(
        'Splash profile check error: $e',
      );

      if (!mounted) {
        return;
      }

      // =================================================
      // SAFETY:
      // IF PROFILE CHECK FAILS, DO NOT BYPASS
      // MANDATORY PROFILE SETUP.
      // =================================================

      _goTo(
        const MandatoryProfileSetupScreen(),
      );
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
              mainAxisSize: MainAxisSize.min,
              children: [
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

                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme:
                        Theme.of(context)
                            .colorScheme
                            .copyWith(
                              primary: Colors.white,
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
