import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

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

      final String formattedPhone = '+91$cleanPhone';

      debugPrint('========================================');
      debugPrint('FIREBASE PHONE VERIFICATION START');
      debugPrint('PHONE: $formattedPhone');
      debugPrint('========================================');

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,

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
              'PHONE: ${user.phoneNumber ?? formattedPhone}',
            );
            debugPrint('========================================');

            // IMPORTANT:
            // Walker ID creation is NOT done here.
            //
            // It is done only after the OTP screen
            // completes the normal verification flow.
            //
            // This prevents duplicate Walker IDs.
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

          onCodeSent(verificationId);
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

      onError(e.toString());
    }
  }

  // =====================================================
  // VERIFY OTP
  //
  // THIS METHOD ONLY DOES:
  //
  // Phone OTP
  //      ↓
  // Firebase Authentication
  //      ↓
  // Firebase UID
  //
  // Walker ID / Firestore is handled separately.
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
      // CREATE CREDENTIAL
      // =================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: cleanVerificationId,
        smsCode: cleanOtp,
      );

      // =================================================
      // FIREBASE LOGIN
      // =================================================

      final UserCredential userCredential =
          await _auth.signInWithCredential(
        credential,
      );

      final User? user =
          userCredential.user;

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
