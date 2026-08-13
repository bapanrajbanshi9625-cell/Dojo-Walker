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

      // -------------------------------------------------
      // VALIDATE PHONE NUMBER
      // -------------------------------------------------

      if (cleanPhone.length != 10) {
        onError(
          'Please enter a valid 10-digit mobile number.',
        );
        return;
      }

      debugPrint(
        'Starting Firebase phone verification...',
      );

      debugPrint(
        'Phone: +91$cleanPhone',
      );

      // -------------------------------------------------
      // FIREBASE PHONE AUTH
      // -------------------------------------------------

      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$cleanPhone',

        // =================================================
        // AUTOMATIC VERIFICATION
        // =================================================

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            debugPrint(
              'Firebase automatic verification started.',
            );

            final UserCredential userCredential =
                await _auth.signInWithCredential(
              credential,
            );

            final User? user =
                userCredential.user;

            if (user != null) {
              debugPrint(
                'Firebase automatic verification successful.',
              );

              debugPrint(
                'Firebase UID: ${user.uid}',
              );

              debugPrint(
                'Firebase Phone: ${user.phoneNumber}',
              );

              await _saveLoginState();
            }
          } catch (e) {
            debugPrint(
              'Automatic Firebase sign-in error: $e',
            );
          }
        },

        // =================================================
        // VERIFICATION FAILED
        // =================================================

        verificationFailed:
            (FirebaseAuthException e) {
          debugPrint(
            'Firebase Verification Failed',
          );

          debugPrint(
            'Code: ${e.code}',
          );

          debugPrint(
            'Message: ${e.message}',
          );

          onError(
            e.message ??
                'Firebase phone verification failed.',
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
            'Firebase OTP sent successfully.',
          );

          debugPrint(
            'Verification ID received.',
          );

          onCodeSent(
            verificationId,
          );
        },

        // =================================================
        // AUTO RETRIEVAL TIMEOUT
        // =================================================

        codeAutoRetrievalTimeout:
            (String verificationId) {
          debugPrint(
            'Firebase OTP auto-retrieval timeout.',
          );

          debugPrint(
            'Verification ID is still available.',
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Phone Verification Exception',
      );

      debugPrint(
        'Code: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
      );

      onError(
        e.message ??
            'Phone verification failed.',
      );
    } catch (e) {
      debugPrint(
        'Phone Verification Exception: $e',
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
      final String cleanVerificationId =
          verificationId.trim();

      final String cleanOtp =
          smsCode.trim();

      // -------------------------------------------------
      // VALIDATE VERIFICATION ID
      // -------------------------------------------------

      if (cleanVerificationId.isEmpty) {
        debugPrint(
          'OTP verification failed: verificationId is empty.',
        );

        return false;
      }

      // -------------------------------------------------
      // VALIDATE OTP
      // -------------------------------------------------

      if (cleanOtp.length != 6) {
        debugPrint(
          'OTP verification failed: invalid OTP length.',
        );

        return false;
      }

      debugPrint(
        'Starting Firebase OTP verification...',
      );

      // =================================================
      // CREATE FIREBASE PHONE CREDENTIAL
      // =================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId:
            cleanVerificationId,
        smsCode: cleanOtp,
      );

      // =================================================
      // SIGN IN WITH FIREBASE
      // =================================================

      final UserCredential userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      // =================================================
      // GET FIREBASE USER
      // =================================================

      final User? user =
          userCredential.user;

      if (user == null) {
        debugPrint(
          'Firebase OTP verification failed: user is null.',
        );

        return false;
      }

      // =================================================
      // FIREBASE LOGIN SUCCESS
      // =================================================

      debugPrint(
        'Firebase OTP verification successful.',
      );

      debugPrint(
        'Firebase User UID: ${user.uid}',
      );

      debugPrint(
        'Firebase Phone: ${user.phoneNumber}',
      );

      // =================================================
      // SAVE LOCAL LOGIN STATE
      // =================================================

      await _saveLoginState();

      // =================================================
      // CONFIRM FIREBASE SESSION
      // =================================================

      final User? currentUser =
          _auth.currentUser;

      if (currentUser == null) {
        debugPrint(
          'Firebase session could not be confirmed.',
        );

        return false;
      }

      debugPrint(
        'Firebase session confirmed.',
      );

      debugPrint(
        'Current Firebase UID: ${currentUser.uid}',
      );

      debugPrint(
        'Current Firebase Phone: '
        '${currentUser.phoneNumber}',
      );

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase OTP Error',
      );

      debugPrint(
        'Code: ${e.code}',
      );

      debugPrint(
        'Message: ${e.message}',
      );

      return false;
    } catch (e) {
      debugPrint(
        'OTP Verification Exception: $e',
      );

      return false;
    }
  }

  // =====================================================
  // SAVE LOGIN STATE
  // =====================================================

  Future<void> _saveLoginState() async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'isLoggedIn',
        true,
      );

      debugPrint(
        'Local login state saved.',
      );
    } catch (e) {
      debugPrint(
        'Failed to save local login state: $e',
      );
    }
  }

  // =====================================================
  // CURRENT FIREBASE USER
  // =====================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // =====================================================
  // CURRENT FIREBASE UID
  // =====================================================

  String? get currentUserUid {
    return _auth.currentUser?.uid;
  }

  // =====================================================
  // CURRENT PHONE NUMBER
  // =====================================================

  String? get currentPhoneNumber {
    return _auth.currentUser?.phoneNumber;
  }

  // =====================================================
  // CHECK FIREBASE LOGIN SESSION
  // =====================================================

  bool get isFirebaseLoggedIn {
    return _auth.currentUser != null;
  }

  // =====================================================
  // CHECK LOCAL LOGIN STATE
  // =====================================================

  Future<bool> isLoggedIn() async {
    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    return prefs.getBool(
          'isLoggedIn',
        ) ??
        false;
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    try {
      // -------------------------------------------------
      // FIREBASE LOGOUT
      // -------------------------------------------------

      await _auth.signOut();

      // -------------------------------------------------
      // LOCAL LOGOUT
      // -------------------------------------------------

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'isLoggedIn',
        false,
      );

      debugPrint(
        'Firebase and local logout successful.',
      );
    } catch (e) {
      debugPrint(
        'Logout error: $e',
      );
    }
  }
}
