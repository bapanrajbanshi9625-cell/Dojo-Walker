// File location:
// lib/screens/splash_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/profile_setup/screens/pending_verification_screen.dart';

import 'main_navigation_screen.dart';
import 'mobile_login_screen.dart';
import 'profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
  });

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // ============================================================
  // STATE
  // ============================================================

  String? _errorMessage;

  bool _isChecking = true;

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _checkLoginAndNavigate();
  }

  // ============================================================
  // CHECK LOGIN + WALKER ACCOUNT + PROFILE + VERIFICATION
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
      // 1. CURRENT FIREBASE USER
      // ========================================================

      final User? user =
          _auth.currentUser;

      // ========================================================
      // NO FIREBASE SESSION
      // ========================================================

      if (user == null) {
        debugPrint(
          'Splash: No Firebase user.',
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

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        debugPrint(
          'Splash: Empty Firebase UID.',
        );

        await _forceLogout();

        return;
      }

      // ========================================================
      // DEBUG LOG
      // ========================================================

      debugPrint(
        '========================================',
      );

      debugPrint(
        'SPLASH AUTH CHECK',
      );

      debugPrint(
        'Firebase UID: $uid',
      );

      debugPrint(
        'Phone: ${user.phoneNumber ?? 'unknown'}',
      );

      debugPrint(
        '========================================',
      );

      // ========================================================
      // 2. WALKER DOCUMENT
      //
      // IMPORTANT:
      //
      // walkers/{Firebase Auth UID}
      //
      // Walker document ID must be Firebase UID.
      // ========================================================

      final DocumentReference<
          Map<String, dynamic>> walkerRef =
          _firestore
              .collection('walkers')
              .doc(uid);

      final DocumentSnapshot<
          Map<String, dynamic>> walkerSnapshot =
          await walkerRef.get();

      // ========================================================
      // WALKER DOCUMENT DOES NOT EXIST
      // ========================================================

      if (!walkerSnapshot.exists) {
        debugPrint(
          'Splash: Walker document not found.',
        );

        debugPrint(
          'Splash → MANDATORY PROFILE SETUP',
        );

        if (!mounted) {
          return;
        }

        _goTo(
          const MandatoryProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // WALKER DATA
      // ========================================================

      final Map<String, dynamic> data =
          walkerSnapshot.data() ??
              <String, dynamic>{};

      // ========================================================
      // 3. CHECK ROLE
      // ========================================================

      final String role =
          data['role']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      debugPrint(
        'Splash: role=$role',
      );

      if (role != 'walker') {
        debugPrint(
          'Splash: Invalid walker role.',
        );

        await _forceLogout();

        return;
      }

      // ========================================================
      // 4. CHECK AUTH UID
      // ========================================================

      final String documentAuthUid =
          data['authUid']
                  ?.toString()
                  .trim() ??
              '';

      if (documentAuthUid.isNotEmpty &&
          documentAuthUid != uid) {
        debugPrint(
          'Splash: authUid mismatch.',
        );

        await _forceLogout();

        return;
      }

      // ========================================================
      // 5. CHECK WALKER UID
      // ========================================================

      final String documentUid =
          data['uid']
                  ?.toString()
                  .trim() ??
              '';

      if (documentUid.isNotEmpty &&
          documentUid != uid) {
        debugPrint(
          'Splash: uid mismatch.',
        );

        await _forceLogout();

        return;
      }

      // ========================================================
      // 6. CHECK WALKER ID
      // ========================================================

      final String walkerId =
          data['walkerId']
                  ?.toString()
                  .trim() ??
              '';

      if (walkerId.isEmpty) {
        debugPrint(
          'Splash: Walker ID missing.',
        );

        debugPrint(
          'Splash → MANDATORY PROFILE SETUP',
        );

        if (!mounted) {
          return;
        }

        _goTo(
          const MandatoryProfileSetupScreen(),
        );

        return;
      }

      debugPrint(
        'Walker ID: $walkerId',
      );

      // ========================================================
      // 7. PROFILE STATUS
      // ========================================================

      final bool profileCompleted =
          data['profileCompleted'] == true;

      // ========================================================
      // 8. VERIFICATION STATUS
      // ========================================================

      final String verificationStatus =
          data['verificationStatus']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              'pending';

      // ========================================================
      // 9. WALKER ID ACTIVE
      // ========================================================

      final bool walkerIdActive =
          data['walkerIdActive'] == true;

      // ========================================================
      // DEBUG
      // ========================================================

      debugPrint(
        '----------------------------------------',
      );

      debugPrint(
        'PROFILE STATUS',
      );

      debugPrint(
        'profileCompleted: $profileCompleted',
      );

      debugPrint(
        'verificationStatus: $verificationStatus',
      );

      debugPrint(
        'walkerIdActive: $walkerIdActive',
      );

      debugPrint(
        '----------------------------------------',
      );

      // ========================================================
      // 10. PROFILE NOT COMPLETED
      //
      // This check comes BEFORE approval.
      //
      // Therefore an incomplete profile can NEVER
      // directly enter Home.
      // ========================================================

      if (!profileCompleted) {
        debugPrint(
          'Splash → MANDATORY PROFILE SETUP',
        );

        if (!mounted) {
          return;
        }

        _goTo(
          const MandatoryProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // 11. REJECTED
      // ========================================================

      if (verificationStatus == 'rejected') {
        debugPrint(
          'Splash → REJECTED / VERIFICATION SCREEN',
        );

        if (!mounted) {
          return;
        }

        _goTo(
          const PendingVerificationScreen(),
        );

        return;
      }

      // ========================================================
      // 12. PENDING
      // ========================================================

      if (verificationStatus == 'pending' ||
          verificationStatus == 'verification' ||
          verificationStatus == 'under_review') {
        debugPrint(
          'Splash → PENDING VERIFICATION',
        );

        if (!mounted) {
          return;
        }

        _goTo(
          const PendingVerificationScreen(),
        );

        return;
      }

      // ========================================================
      // 13. APPROVED + ACTIVE
      //
      // Only this condition allows Home.
      // ========================================================

      if (verificationStatus == 'approved' &&
          walkerIdActive) {
        debugPrint(
          'Splash → MAIN NAVIGATION',
        );

        if (!mounted) {
          return;
        }

        _goTo(
          const MainNavigationScreen(),
        );

        return;
      }

      // ========================================================
      // 14. APPROVED BUT NOT ACTIVE
      //
      // Do NOT allow Home.
      // ========================================================

      if (verificationStatus == 'approved' &&
          !walkerIdActive) {
        debugPrint(
          'Splash → APPROVED BUT WALKER ID NOT ACTIVE',
        );

        if (!mounted) {
          return;
        }

        _goTo(
          const PendingVerificationScreen(),
        );

        return;
      }

      // ========================================================
      // 15. SAFE FALLBACK
      //
      // Unknown status never opens Home.
      // ========================================================

      debugPrint(
        'Splash → UNKNOWN STATUS FALLBACK',
      );

      if (!mounted) {
        return;
      }

      _goTo(
        const PendingVerificationScreen(),
      );

      return;
    } on FirebaseException catch (e) {
      // ========================================================
      // FIREBASE ERROR
      // ========================================================

      debugPrint(
        '========================================',
      );

      debugPrint(
        'SPLASH FIREBASE ERROR',
      );

      debugPrint(
        'Code: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
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
            'Unable to verify your account.\n\n'
            'Please check your internet connection '
            'and try again.';
      });
    } catch (e, stackTrace) {
      // ========================================================
      // GENERAL ERROR
      // ========================================================

      debugPrint(
        'SPLASH ERROR: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isChecking = false;

        _errorMessage =
            'Unable to verify your account.\n\n'
            'Please try again.';
      });
    }
  }

  // ============================================================
  // FORCE LOGOUT
  // ============================================================

  Future<void> _forceLogout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint(
        'Splash logout error: $e',
      );
    }

    if (!mounted) {
      return;
    }

    _goTo(
      const MobileLoginScreen(),
    );
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _goTo(
    Widget screen,
  ) {
    if (!mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final ThemeData theme =
        Theme.of(context);

    final Color backgroundColor =
        theme.scaffoldBackgroundColor;

    final Color primaryColor =
        theme.colorScheme.primary;

    final Color onPrimaryColor =
        theme.colorScheme.onPrimary;

    final Color errorColor =
        theme.colorScheme.error;

    return Scaffold(
      backgroundColor: backgroundColor,

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
          // OPTIONAL THEME OVERLAY
          //
          // Uses theme colors only.
          // No hard-coded color.
          // ======================================================

          Container(
  color: backgroundColor.withOpacity(
    0.08,
  ),
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
                // NORMAL CHECKING
                // ==================================================

                if (_errorMessage == null) ...[
                  Text(
                    'Getting things ready...',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      value: null,
                      color: onPrimaryColor,
                    ),
                  ),
                ],

                // ==================================================
                // ERROR
                // ==================================================

                if (_errorMessage != null) ...[
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 25,
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style:
                          theme.textTheme.bodyMedium?.copyWith(
                        color: onPrimaryColor,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  ElevatedButton(
                    onPressed: _isChecking
                        ? null
                        : _checkLoginAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: onPrimaryColor,
                    ),
                    child: Text(
                      'Try Again',
                      style:
                          theme.textTheme.labelLarge?.copyWith(
                        color: onPrimaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ),

                  Icon(
                    Icons.error_outline_rounded,
                    size: 28,
                    color: errorColor,
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
