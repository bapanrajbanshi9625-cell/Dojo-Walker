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
      debugPrint('Phone: +91$cleanPhone');
      debugPrint('========================================');

      if (cleanPhone.length != 10) {
        onError(
          'Please enter a valid 10-digit mobile number.',
        );
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$cleanPhone',

        // =================================================
        // AUTOMATIC VERIFICATION
        // =================================================

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          debugPrint(
            'Firebase automatic verification completed.',
          );

          try {
            final UserCredential result =
                await _auth.signInWithCredential(
              credential,
            );

            final User? user = result.user;

            if (user != null) {
              debugPrint(
                'AUTO LOGIN SUCCESS',
              );

              debugPrint(
                'Firebase UID: ${user.uid}',
              );

              debugPrint(
                'Firebase Phone: ${user.phoneNumber}',
              );

              final SharedPreferences prefs =
                  await SharedPreferences.getInstance();

              await prefs.setBool(
                'isLoggedIn',
                true,
              );
            } else {
              debugPrint(
                'AUTO LOGIN FAILED: user is null',
              );
            }
          } on FirebaseAuthException catch (e) {
            debugPrint(
              'AUTO LOGIN FIREBASE ERROR',
            );
            debugPrint(
              'Code: ${e.code}',
            );
            debugPrint(
              'Message: ${e.message}',
            );
          } catch (e) {
            debugPrint(
              'AUTO LOGIN ERROR: $e',
            );
          }
        },

        // =================================================
        // VERIFICATION FAILED
        // =================================================

        verificationFailed: (
          FirebaseAuthException e,
        ) {
          debugPrint(
            '========================================',
          );

          debugPrint(
            'FIREBASE VERIFICATION FAILED',
          );

          debugPrint(
            'ERROR CODE: ${e.code}',
          );

          debugPrint(
            'ERROR MESSAGE: ${e.message}',
          );

          debugPrint(
            '========================================',
          );

          onError(
            '${e.code}: ${e.message ?? 'Firebase verification failed.'}',
          );
        },

        // =================================================
        // OTP SENT
        // =================================================

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          debugPrint(
            '========================================',
          );

          debugPrint(
            'FIREBASE OTP SENT SUCCESSFULLY',
          );

          debugPrint(
            'Verification ID received.',
          );

          debugPrint(
            'Verification ID length: ${verificationId.length}',
          );

          debugPrint(
            '========================================',
          );

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
            'Firebase OTP auto retrieval timeout.',
          );

          debugPrint(
            'Verification ID still received.',
          );

          debugPrint(
            'Verification ID length: ${verificationId.length}',
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'PHONE VERIFICATION FIREBASE EXCEPTION',
      );

      debugPrint(
        'ERROR CODE: ${e.code}',
      );

      debugPrint(
        'ERROR MESSAGE: ${e.message}',
      );

      debugPrint(
        '========================================',
      );

      onError(
        '${e.code}: ${e.message ?? 'Phone verification failed.'}',
      );
    } catch (e) {
      debugPrint(
        'PHONE VERIFICATION EXCEPTION: $e',
      );

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
    try {
      final String cleanOtp = smsCode.trim();

      debugPrint(
        '========================================',
      );

      debugPrint(
        'FIREBASE OTP VERIFICATION START',
      );

      debugPrint(
        'Verification ID length: ${verificationId.length}',
      );

      debugPrint(
        'OTP length: ${cleanOtp.length}',
      );

      debugPrint(
        '========================================',
      );

      if (verificationId.isEmpty) {
        debugPrint(
          'ERROR: verificationId is EMPTY',
        );

        return false;
      }

      if (cleanOtp.length != 6) {
        debugPrint(
          'ERROR: OTP must contain exactly 6 digits',
        );

        return false;
      }

      // =================================================
      // CREATE FIREBASE CREDENTIAL
      // =================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: cleanOtp,
      );

      debugPrint(
        'Firebase PhoneAuthCredential created.',
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
          'ERROR: Firebase returned NULL user.',
        );

        return false;
      }

      debugPrint(
        '========================================',
      );

      debugPrint(
        'OTP VERIFICATION SUCCESS',
      );

      debugPrint(
        'Firebase UID: ${user.uid}',
      );

      debugPrint(
        'Firebase Phone: ${user.phoneNumber}',
      );

      debugPrint(
        '========================================',
      );

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
          'ERROR: Firebase currentUser is NULL.',
        );

        return false;
      }

      debugPrint(
        '========================================',
      );

      debugPrint(
        'FIREBASE SESSION CONFIRMED',
      );

      debugPrint(
        'CURRENT UID: ${currentUser.uid}',
      );

      debugPrint(
        'CURRENT PHONE: ${currentUser.phoneNumber}',
      );

      debugPrint(
        '========================================',
      );

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'FIREBASE OTP ERROR',
      );

      debugPrint(
        'ERROR CODE: ${e.code}',
      );

      debugPrint(
        'ERROR MESSAGE: ${e.message}',
      );

      debugPrint(
        '========================================',
      );

      return false;
    } catch (e) {
      debugPrint(
        '========================================',
      );

      debugPrint(
        'OTP VERIFICATION GENERAL ERROR',
      );

      debugPrint(
        'ERROR: $e',
      );

      debugPrint(
        '========================================',
      );

      return false;
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
