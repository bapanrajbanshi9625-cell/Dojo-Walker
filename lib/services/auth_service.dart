// File location: lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

      if (!RegExp(r'^[0-9]{10}$').hasMatch(cleanPhone)) {
        onError(
          'Please enter a valid 10-digit mobile number.',
        );
        return;
      }

      debugPrint('========================================');
      debugPrint('FIREBASE PHONE VERIFICATION START');
      debugPrint('PHONE: +91$cleanPhone');
      debugPrint('========================================');

      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$cleanPhone',

        // =================================================
        // AUTOMATIC VERIFICATION
        // =================================================

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            final UserCredential result =
                await _auth.signInWithCredential(
              credential,
            );

            final User? user = result.user;

            if (user == null) {
              debugPrint(
                'AUTO VERIFICATION: USER IS NULL',
              );
              return;
            }

            debugPrint('========================================');
            debugPrint('AUTO FIREBASE AUTH SUCCESS');
            debugPrint('FIREBASE UID: ${user.uid}');
            debugPrint(
              'PHONE: ${user.phoneNumber ?? '+91$cleanPhone'}',
            );
            debugPrint('========================================');

            // IMPORTANT:
            // Do NOT create Walker ID here.
            //
            // Walker ID creation is handled by:
            // WalkerIdService
            //
            // This prevents duplicate account creation.
          } on FirebaseAuthException catch (e) {
            debugPrint(
              'AUTO FIREBASE AUTH ERROR: '
              '${e.code} - ${e.message}',
            );
          } catch (e) {
            debugPrint(
              'AUTO VERIFICATION ERROR: $e',
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
          debugPrint('PHONE VERIFICATION FAILED');
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
            'VERIFICATION ID LENGTH: '
            '${verificationId.length}',
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
          debugPrint(
            'FIREBASE OTP AUTO RETRIEVAL TIMEOUT',
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'PHONE AUTH ERROR: '
        '${e.code} - ${e.message}',
      );

      onError(
        '${e.code}: '
        '${e.message ?? 'Phone verification failed.'}',
      );
    } catch (e) {
      debugPrint(
        'PHONE AUTH GENERAL ERROR: $e',
      );

      onError(
        e.toString(),
      );
    }
  }

  // =====================================================
  // VERIFY OTP
  //
  // IMPORTANT:
  // This method ONLY verifies Firebase OTP.
  //
  // It does NOT:
  // - create Walker ID
  // - write Firestore
  // - create walker profile
  // - update counters
  //
  // Those operations are handled after successful
  // Firebase authentication.
  // =====================================================

  Future<bool> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final String cleanVerificationId =
        verificationId.trim();

    final String cleanOtp =
        smsCode.trim();

    // =====================================================
    // VALIDATE VERIFICATION ID
    // =====================================================

    if (cleanVerificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message:
            'Firebase verification ID is empty.',
      );
    }

    // =====================================================
    // VALIDATE OTP
    // =====================================================

    if (!RegExp(r'^[0-9]{6}$').hasMatch(cleanOtp)) {
      throw FirebaseAuthException(
        code: 'invalid-otp-format',
        message:
            'OTP must contain exactly 6 digits.',
      );
    }

    try {
      // =================================================
      // CREATE PHONE CREDENTIAL
      // =================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: cleanVerificationId,
        smsCode: cleanOtp,
      );

      // =================================================
      // FIREBASE AUTH LOGIN
      // =================================================

      final UserCredential userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message:
              'Firebase authentication returned no user.',
        );
      }

      // =================================================
      // FIREBASE AUTH SUCCESS
      // =================================================

      debugPrint('========================================');
      debugPrint('FIREBASE AUTH SUCCESS');
      debugPrint('FIREBASE UID: ${user.uid}');
      debugPrint(
        'FIREBASE PHONE: '
        '${user.phoneNumber ?? 'unknown'}',
      );
      debugPrint('========================================');

      // =================================================
      // FINAL SESSION CHECK
      // =================================================

      final User? currentUser =
          _auth.currentUser;

      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'session-not-created',
          message:
              'Firebase login session was not created.',
        );
      }

      debugPrint('========================================');
      debugPrint('FIREBASE OTP LOGIN COMPLETE');
      debugPrint(
        'CURRENT UID: ${currentUser.uid}',
      );
      debugPrint('========================================');

      return true;
    } on FirebaseAuthException {
      // Firebase authentication errors are passed directly
      // to the OTP screen.
      rethrow;
    } catch (e) {
      debugPrint(
        'OTP AUTH ERROR: $e',
      );

      throw FirebaseAuthException(
        code: 'otp-verification-error',
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
  // FIREBASE LOGIN STATE
  // =====================================================

  bool get isFirebaseLoggedIn {
    return _auth.currentUser != null;
  }

  // =====================================================
  // FIREBASE UID
  // =====================================================

  String? get currentUid {
    return _auth.currentUser?.uid;
  }

  // =====================================================
  // CURRENT PHONE
  // =====================================================

  String? get currentPhoneNumber {
    return _auth.currentUser?.phoneNumber;
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    try {
      await _auth.signOut();

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
