// File location: lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =====================================================
  // SEND OTP
  // =====================================================

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      final String cleanPhone = phoneNumber.trim();

      debugPrint('========================================');
      debugPrint('FIREBASE PHONE VERIFICATION START');
      debugPrint('PHONE: +91$cleanPhone');
      debugPrint('========================================');

      // ---------------------------------------------------
      // PHONE VALIDATION
      // ---------------------------------------------------

      if (!RegExp(r'^[0-9]{10}$').hasMatch(cleanPhone)) {
        onError(
          'Please enter a valid 10-digit mobile number.',
        );
        return;
      }

      // ---------------------------------------------------
      // FIREBASE PHONE VERIFICATION
      // ---------------------------------------------------

      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$cleanPhone',

        // =================================================
        // AUTOMATIC VERIFICATION
        // =================================================

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          debugPrint('========================================');
          debugPrint('FIREBASE AUTOMATIC VERIFICATION');
          debugPrint('========================================');

          try {
            final UserCredential result =
                await _auth.signInWithCredential(
              credential,
            );

            final User? user = result.user;

            if (user != null) {
              debugPrint('AUTO LOGIN SUCCESS');
              debugPrint('UID: ${user.uid}');
              debugPrint('PHONE: ${user.phoneNumber}');

              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();

              await prefs.setBool(
                'isLoggedIn',
                true,
              );
            } else {
              debugPrint(
                'AUTO LOGIN FAILED: USER IS NULL',
              );
            }
          } on FirebaseAuthException catch (e) {
            debugPrint(
              'AUTO LOGIN FIREBASE ERROR',
            );
            debugPrint(
              'CODE: ${e.code}',
            );
            debugPrint(
              'MESSAGE: ${e.message}',
            );
          } catch (e) {
            debugPrint(
              'AUTO LOGIN GENERAL ERROR: $e',
            );
          }
        },

        // =================================================
        // VERIFICATION FAILED
        // =================================================

        verificationFailed: (
          FirebaseAuthException e,
        ) {
          debugPrint('========================================');
          debugPrint('FIREBASE PHONE VERIFICATION FAILED');
          debugPrint('CODE: ${e.code}');
          debugPrint('MESSAGE: ${e.message}');
          debugPrint('========================================');

          onError(
            '${e.code}: '
            '${e.message ?? 'Firebase phone verification failed.'}',
          );
        },

        // =================================================
        // OTP SENT
        // =================================================

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          debugPrint('========================================');
          debugPrint('FIREBASE OTP SENT');
          debugPrint(
            'VERIFICATION ID LENGTH: ${verificationId.length}',
          );
          debugPrint(
            'RESEND TOKEN: $resendToken',
          );
          debugPrint('========================================');

          onCodeSent(
            verificationId,
          );
        },

        // =================================================
        // AUTO RETRIEVAL TIMEOUT
        // =================================================

        codeAutoRetrievalTimeout: (
          String verificationId,
        ) {
          debugPrint('========================================');
          debugPrint(
            'FIREBASE OTP AUTO RETRIEVAL TIMEOUT',
          );
          debugPrint(
            'VERIFICATION ID LENGTH: ${verificationId.length}',
          );
          debugPrint('========================================');
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('========================================');
      debugPrint(
        'PHONE VERIFICATION FIREBASE EXCEPTION',
      );
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('========================================');

      onError(
        '${e.code}: '
        '${e.message ?? 'Phone verification failed.'}',
      );
    } catch (e) {
      debugPrint('========================================');
      debugPrint(
        'PHONE VERIFICATION GENERAL EXCEPTION',
      );
      debugPrint('ERROR: $e');
      debugPrint('========================================');

      onError(
        e.toString(),
      );
    }
  }

  // =====================================================
  // VERIFY OTP
  // =====================================================

  Future<bool> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final String cleanVerificationId =
        verificationId.trim();

    final String cleanOtp =
        smsCode.trim();

    debugPrint('========================================');
    debugPrint('FIREBASE OTP VERIFICATION START');
    debugPrint(
      'VERIFICATION ID LENGTH: '
      '${cleanVerificationId.length}',
    );
    debugPrint(
      'OTP LENGTH: ${cleanOtp.length}',
    );
    debugPrint('========================================');

    // ===================================================
    // BASIC VALIDATION
    // ===================================================

    if (cleanVerificationId.isEmpty) {
      debugPrint(
        'ERROR: VERIFICATION ID IS EMPTY',
      );

      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message:
            'Firebase verification ID is empty.',
      );
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(cleanOtp)) {
      debugPrint(
        'ERROR: OTP MUST CONTAIN EXACTLY 6 DIGITS',
      );

      throw FirebaseAuthException(
        code: 'invalid-otp-format',
        message:
            'OTP must contain exactly 6 digits.',
      );
    }

    try {
      // =================================================
      // CREATE FIREBASE PHONE CREDENTIAL
      // =================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: cleanVerificationId,
        smsCode: cleanOtp,
      );

      debugPrint(
        'FIREBASE PHONE AUTH CREDENTIAL CREATED',
      );

      // =================================================
      // SIGN IN WITH FIREBASE
      // =================================================

      final UserCredential userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

      // =================================================
      // CHECK USER
      // =================================================

      if (user == null) {
        debugPrint(
          'ERROR: FIREBASE RETURNED NULL USER',
        );

        throw FirebaseAuthException(
          code: 'null-user',
          message:
              'Firebase authentication returned no user.',
        );
      }

      // =================================================
      // OTP SUCCESS
      // =================================================

      debugPrint('========================================');
      debugPrint('OTP VERIFICATION SUCCESS');
      debugPrint('FIREBASE UID: ${user.uid}');
      debugPrint(
        'FIREBASE PHONE: ${user.phoneNumber}',
      );
      debugPrint('========================================');

      // =================================================
      // SAVE LOCAL LOGIN STATUS
      // =================================================

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'isLoggedIn',
        true,
      );

      // =================================================
      // CONFIRM FIREBASE SESSION
      // =================================================

      final User? currentUser =
          _auth.currentUser;

      if (currentUser == null) {
        debugPrint(
          'ERROR: FIREBASE CURRENT USER IS NULL',
        );

        throw FirebaseAuthException(
          code: 'session-not-created',
          message:
              'Firebase login session was not created.',
        );
      }

      debugPrint('========================================');
      debugPrint('FIREBASE SESSION CONFIRMED');
      debugPrint(
        'CURRENT UID: ${currentUser.uid}',
      );
      debugPrint(
        'CURRENT PHONE: ${currentUser.phoneNumber}',
      );
      debugPrint('========================================');

      return true;
    }

    // ===================================================
    // IMPORTANT:
    // DO NOT HIDE FIREBASE ERROR
    // ===================================================

    on FirebaseAuthException catch (e) {
      debugPrint('========================================');
      debugPrint('FIREBASE OTP VERIFICATION ERROR');
      debugPrint('ERROR CODE: ${e.code}');
      debugPrint(
        'ERROR MESSAGE: ${e.message}',
      );
      debugPrint('========================================');

      // IMPORTANT:
      // Screen को exact Firebase error मिलेगा.
      rethrow;
    } catch (e) {
      debugPrint('========================================');
      debugPrint('OTP VERIFICATION GENERAL ERROR');
      debugPrint('ERROR: $e');
      debugPrint('========================================');

      throw FirebaseAuthException(
        code: 'otp-verification-failed',
        message: e.toString(),
      );
    }
  }

  // =====================================================
  // CURRENT USER
  // =====================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // =====================================================
  // FIREBASE LOGIN SESSION
  // =====================================================

  bool get isFirebaseLoggedIn {
    return _auth.currentUser != null;
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    try {
      await _auth.signOut();

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'isLoggedIn',
        false,
      );

      debugPrint(
        'Firebase logout successful.',
      );
    } catch (e) {
      debugPrint(
        'Logout error: $e',
      );
    }
  }
}
