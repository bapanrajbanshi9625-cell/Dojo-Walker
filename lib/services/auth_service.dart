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

      if (cleanPhone.length != 10) {
        onError('Please enter a valid 10-digit mobile number.');
        return;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: '+91$cleanPhone',

        // Android में automatic verification होने पर
        // Firebase खुद user को sign in कर देगा.
        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            await _auth.signInWithCredential(credential);

            final User? user = _auth.currentUser;

            if (user != null) {
              debugPrint(
                'Firebase auto verification successful: ${user.uid}',
              );

              final prefs =
                  await SharedPreferences.getInstance();

              await prefs.setBool('isLoggedIn', true);
            }
          } catch (e) {
            debugPrint(
              'Automatic Firebase sign-in error: $e',
            );
          }
        },

        // Firebase verification error
        verificationFailed: (FirebaseAuthException e) {
          debugPrint(
            'Firebase Verification Failed: '
            '${e.code} - ${e.message}',
          );

          onError(
            e.message ?? 'Firebase phone verification failed.',
          );
        },

        // OTP successfully sent
        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          debugPrint(
            'Firebase OTP sent. Verification ID received.',
          );

          onCodeSent(verificationId);
        },

        // OTP timeout
        codeAutoRetrievalTimeout: (
          String verificationId,
        ) {
          debugPrint(
            'Firebase OTP auto-retrieval timeout.',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Phone Verification Exception: $e',
      );

      onError(e.toString());
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

      if (verificationId.isEmpty) {
        debugPrint(
          'OTP verification failed: verificationId is empty.',
        );
        return false;
      }

      if (cleanOtp.length != 6) {
        debugPrint(
          'OTP verification failed: invalid OTP length.',
        );
        return false;
      }

      // Create Firebase phone credential
      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: cleanOtp,
      );

      // IMPORTANT:
      // This creates the real Firebase Auth session.
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      final User? user = userCredential.user;

      if (user == null) {
        debugPrint(
          'Firebase OTP verification failed: user is null.',
        );
        return false;
      }

      debugPrint(
        'Firebase OTP verification successful.',
      );

      debugPrint(
        'Firebase User UID: ${user.uid}',
      );

      debugPrint(
        'Firebase Phone: ${user.phoneNumber}',
      );

      // Local login flag
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'isLoggedIn',
        true,
      );

      // Confirm Firebase session exists
      final User? currentUser =
          FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        debugPrint(
          'Firebase session could not be confirmed.',
        );
        return false;
      }

      debugPrint(
        'Firebase session confirmed: ${currentUser.uid}',
      );

      return true;
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase OTP Error: ${e.code} - ${e.message}',
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
  // CURRENT USER
  // =====================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // =====================================================
  // CHECK LOGIN SESSION
  // =====================================================

  bool get isFirebaseLoggedIn {
    return _auth.currentUser != null;
  }

  // =====================================================
  // LOGOUT
  // =====================================================

  Future<void> logout() async {
    await _auth.signOut();

    final prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'isLoggedIn',
      false,
    );
  }
}
