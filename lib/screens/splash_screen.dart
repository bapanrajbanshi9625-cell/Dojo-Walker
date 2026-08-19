// File location: lib/screens/splash_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

class _SplashScreenState
    extends State<SplashScreen> {
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
  // CHECK LOGIN + WALKER ACCOUNT + PROFILE
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

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        await _forceLogout();

        return;
      }

      // ========================================================
      // LOG
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
      // 2. READ WALKER DOCUMENT
      //
      // IMPORTANT:
      // Document ID MUST be Firebase UID.
      //
      // walkers/{Firebase UID}
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
    'Splash: Walker document not found → Mandatory Profile Setup',
  );

  if (!mounted) {
    return;
  }

  _goTo(
    const MandatoryProfileSetupScreen(),
  );

  return;
}

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

      if (role != 'walker') {
        debugPrint(
          'Splash: Invalid walker role: $role',
        );

        await _forceLogout();

        return;
      }

      // ========================================================
      // 4. CHECK AUTH UID INSIDE DOCUMENT
      // ========================================================

      final String documentAuthUid =
          data['authUid']
                  ?.toString()
                  .trim() ??
              '';

      // --------------------------------------------------------
      // If authUid exists, it MUST match Firebase UID.
      // --------------------------------------------------------

      if (documentAuthUid.isNotEmpty &&
          documentAuthUid != uid) {
        debugPrint(
          'Splash: authUid mismatch.',
        );

        await _forceLogout();

        return;
      }

      // ========================================================
      // 5. CHECK WALKER ID
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

        await _forceLogout();

        return;
      }

      debugPrint(
        'Walker ID: $walkerId',
      );

      // ========================================================
      

      // 
// ========================================================
// PROFILE + VERIFICATION STATUS
// ========================================================

final bool profileCompleted =
    data['profileCompleted'] == true;

final String verificationStatus =
    data['verificationStatus']
            ?.toString()
            .trim()
            .toLowerCase() ??
        'pending';

final bool walkerIdActive =
    data['walkerIdActive'] == true;

debugPrint(
  'Splash: profileCompleted=$profileCompleted',
);

debugPrint(
  'Splash: verificationStatus=$verificationStatus',
);

debugPrint(
  'Splash: walkerIdActive=$walkerIdActive',
);

// ========================================================
// 1. APPROVED + ACTIVE → MAIN NAVIGATION
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
// 2. PROFILE NOT COMPLETED → MANDATORY PROFILE
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
// 3. PROFILE COMPLETED + PENDING
// ========================================================

if (verificationStatus == 'pending') {
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
// 4. REJECTED
// ========================================================

if (verificationStatus == 'rejected') {
  debugPrint(
    'Splash → REJECTED / PENDING VERIFICATION',
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
// 5. SAFE FALLBACK
// ========================================================

debugPrint(
  'Splash → PENDING VERIFICATION FALLBACK',
);

if (!mounted) {
  return;
}

_goTo(
  const PendingVerificationScreen(),
);

return;

    } on FirebaseException catch (e) {
      debugPrint(
        'SPLASH FIREBASE ERROR: ${e.code}',
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
    } catch (e) {
      debugPrint(
        'SPLASH ERROR: $e',
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
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                // ==================================================
                // NORMAL CHECKING
                // ==================================================

                if (_errorMessage == null) ...[
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

                  const SizedBox(
                    height: 18,
                  ),

                  const SizedBox(
                    width: 30,
                    height: 30,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 3,
                      value: null,
                      color: Colors.white,
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
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  ElevatedButton(
                    onPressed:
                        _isChecking
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
