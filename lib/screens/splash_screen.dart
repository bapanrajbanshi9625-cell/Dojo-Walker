// File location:
// lib/screens/splash_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../features/walker_verification/screens/pending_verification_screen.dart';
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
  // FIREBASE
  // ============================================================

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // STATE
  // ============================================================

  String? _errorMessage;

  bool _checking = true;

  bool _navigating = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    // Start account check after the first frame.
    // This keeps Splash as the only visible startup screen.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _checkStartup();
      },
    );
  }

  // ============================================================
  // STARTUP CHECK
  // ============================================================

  Future<void> _checkStartup() async {
    if (!mounted || _navigating) {
      return;
    }

    setState(() {
      _checking = true;
      _errorMessage = null;
    });

    try {
      // ========================================================
      // 1. FIREBASE USER
      // ========================================================

      final User? user =
          _auth.currentUser;

      if (user == null) {
        debugPrint(
          'Splash: No Firebase user.',
        );

        _navigateTo(
          const MobileLoginScreen(),
        );

        return;
      }

      // ========================================================
      // 2. UID
      // ========================================================

      final String uid =
          user.uid.trim();

      if (uid.isEmpty) {
        debugPrint(
          'Splash: Empty UID.',
        );

        await _logoutAndLogin();

        return;
      }

      debugPrint(
        '========================================',
      );
      debugPrint(
        'SPLASH STARTUP CHECK',
      );
      debugPrint(
        'UID: $uid',
      );
      debugPrint(
        '========================================',
      );

      // ========================================================
      // 3. WALKER DOCUMENT
      // ========================================================

      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection('walkers')
              .doc(uid)
              .get();

      // ========================================================
      // WALKER DOES NOT EXIST
      // ========================================================

      if (!snapshot.exists) {
        debugPrint(
          'Splash: Walker document missing.',
        );

        _navigateTo(
          const MandatoryProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // DATA
      // ========================================================

      final Map<String, dynamic> data =
          snapshot.data() ??
              <String, dynamic>{};

      // ========================================================
      // 4. ROLE
      // ========================================================

      final String role =
          _stringValue(data['role'])
              .toLowerCase();

      debugPrint(
        'Splash role: $role',
      );

      if (role != 'walker') {
        debugPrint(
          'Splash: Invalid role.',
        );

        await _logoutAndLogin();

        return;
      }

      // ========================================================
      // 5. AUTH UID VALIDATION
      // ========================================================

      final String authUid =
          _stringValue(data['authUid']);

      if (authUid.isNotEmpty &&
          authUid != uid) {
        debugPrint(
          'Splash: authUid mismatch.',
        );

        await _logoutAndLogin();

        return;
      }

      // ========================================================
      // 6. DOCUMENT UID VALIDATION
      // ========================================================

      final String documentUid =
          _stringValue(data['uid']);

      if (documentUid.isNotEmpty &&
          documentUid != uid) {
        debugPrint(
          'Splash: document uid mismatch.',
        );

        await _logoutAndLogin();

        return;
      }

      // ========================================================
      // 7. WALKER ID
      // ========================================================

      final String walkerId =
          _stringValue(data['walkerId']);

      debugPrint(
        'Splash walkerId: $walkerId',
      );

      if (walkerId.isEmpty) {
        debugPrint(
          'Splash: Walker ID missing.',
        );

        _navigateTo(
          const MandatoryProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // 8. PROFILE COMPLETED
      // ========================================================

      final bool profileCompleted =
          _boolValue(
        data['profileCompleted'],
      );

      // ========================================================
      // 9. VERIFICATION STATUS
      // ========================================================

      final String verificationStatus =
          _normalizeStatus(
        data['verificationStatus'],
      );

      // ========================================================
      // 10. WALKER ID ACTIVE
      // ========================================================

      final bool walkerIdActive =
          _boolValue(
        data['walkerIdActive'],
      );

      debugPrint(
        '----------------------------------------',
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
      // 11. PROFILE INCOMPLETE
      // ========================================================

      if (!profileCompleted) {
        debugPrint(
          'Splash → PROFILE SETUP',
        );

        _navigateTo(
          const MandatoryProfileSetupScreen(),
        );

        return;
      }

      // ========================================================
      // 12. REJECTED
      // ========================================================

      if (verificationStatus == 'rejected') {
        debugPrint(
          'Splash → PENDING VERIFICATION / REJECTED',
        );

        _navigateTo(
          const PendingVerificationScreen(),
        );

        return;
      }

      // ========================================================
      // 13. PENDING / UNDER REVIEW
      // ========================================================

      if (_isPendingStatus(
        verificationStatus,
      )) {
        debugPrint(
          'Splash → PENDING VERIFICATION',
        );

        _navigateTo(
          const PendingVerificationScreen(),
        );

        return;
      }

      // ========================================================
      // 14. APPROVED + ACTIVE
      // ========================================================

      if (verificationStatus == 'approved' &&
          walkerIdActive) {
        debugPrint(
          'Splash → MAIN NAVIGATION',
        );

        _navigateTo(
          const MainNavigationScreen(),
        );

        return;
      }

      // ========================================================
      // 15. APPROVED BUT NOT ACTIVE
      // ========================================================

      if (verificationStatus == 'approved' &&
          !walkerIdActive) {
        debugPrint(
          'Splash → APPROVED BUT NOT ACTIVE',
        );

        _navigateTo(
          const PendingVerificationScreen(),
        );

        return;
      }

      // ========================================================
      // 16. UNKNOWN STATUS
      // ========================================================

      debugPrint(
        'Splash → UNKNOWN STATUS',
      );

      _navigateTo(
        const PendingVerificationScreen(),
      );
    } on FirebaseException catch (e, stackTrace) {
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

      debugPrintStack(
        stackTrace: stackTrace,
      );

      debugPrint(
        '========================================',
      );

      if (!mounted || _navigating) {
        return;
      }

      setState(() {
        _checking = false;
        _errorMessage =
            'Unable to verify your account.\n\n'
            'Please check your internet connection '
            'and try again.';
      });
    } catch (e, stackTrace) {
      debugPrint(
        'Splash error: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      if (!mounted || _navigating) {
        return;
      }

      setState(() {
        _checking = false;
        _errorMessage =
            'Unable to verify your account.\n\n'
            'Please try again.';
      });
    }
  }

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _navigateTo(
    Widget screen,
  ) {
    if (!mounted || _navigating) {
      return;
    }

    // Lock navigation BEFORE calling Navigator.
    // This prevents duplicate navigation from startup callbacks.
    _navigating = true;

    setState(() {
      _checking = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => screen,
      ),
      (Route<dynamic> route) => false,
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logoutAndLogin() async {
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

    _navigateTo(
      const MobileLoginScreen(),
    );
  }

  // ============================================================
  // STRING
  // ============================================================

  String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

  // ============================================================
  // BOOL
  // ============================================================

  bool _boolValue(
    dynamic value,
  ) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final String text =
          value
              .trim()
              .toLowerCase();

      return text == 'true' ||
          text == 'yes' ||
          text == '1' ||
          text == 'active' ||
          text == 'approved';
    }

    return false;
  }

  // ============================================================
  // NORMALIZE STATUS
  // ============================================================

  String _normalizeStatus(
    dynamic value,
  ) {
    final String text =
        _stringValue(value)
            .toLowerCase();

    if (text.isEmpty) {
      return 'pending';
    }

    if (text.contains('approve') ||
        text.contains('verified') ||
        text.contains('accepted')) {
      return 'approved';
    }

    if (text.contains('reject')) {
      return 'rejected';
    }

    if (text.contains('pending') ||
        text.contains('review') ||
        text.contains('waiting') ||
        text.contains('verification')) {
      return 'pending';
    }

    return text;
  }

  // ============================================================
  // PENDING STATUS
  // ============================================================

  bool _isPendingStatus(
    String status,
  ) {
    return status == 'pending' ||
        status == 'under_review' ||
        status == 'verification' ||
        status == 'review';
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
          // LIGHT OVERLAY
          // ======================================================

          Container(
            color: backgroundColor.withOpacity(
              0.08,
            ),
          ),

          // ======================================================
          // STARTUP STATUS
          // ======================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 65,
            child: _buildStatus(
              theme: theme,
              primaryColor: primaryColor,
              onPrimaryColor: onPrimaryColor,
              errorColor: errorColor,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS UI
  // ============================================================

  Widget _buildStatus({
    required ThemeData theme,
    required Color primaryColor,
    required Color onPrimaryColor,
    required Color errorColor,
  }) {
    // ----------------------------------------------------------
    // NORMAL LOADING
    // ----------------------------------------------------------

    if (_errorMessage == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Getting things ready...',
            textAlign: TextAlign.center,
            style:
                theme.textTheme.bodyLarge?.copyWith(
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
            child:
                CircularProgressIndicator(
              strokeWidth: 3,
              color: onPrimaryColor,
            ),
          ),
        ],
      );
    }

    // ----------------------------------------------------------
    // ERROR
    // ----------------------------------------------------------

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
          onPressed: _checking
              ? null
              : _checkStartup,
          style:
              ElevatedButton.styleFrom(
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
    );
  }
}
