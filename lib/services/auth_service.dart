import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // SEND OTP
  // ============================================================

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

        // ======================================================
        // AUTOMATIC VERIFICATION
        //
        // IMPORTANT:
        // DO NOT sign in automatically here.
        //
        // Otherwise Firebase can create an authenticated
        // session before the OTP screen has completed the
        // normal verification flow.
        //
        // SplashScreen could then see currentUser and send
        // the user to Profile Setup even when the user did
        // not manually verify the OTP.
        // ======================================================

        verificationCompleted:
            (PhoneAuthCredential credential) {
          debugPrint('========================================');
          debugPrint('FIREBASE AUTO VERIFICATION AVAILABLE');
          debugPrint(
            'Automatic credential received.',
          );
          debugPrint(
            'Waiting for manual OTP verification flow.',
          );
          debugPrint('========================================');

          // Intentionally NOT calling:
          //
          // _auth.signInWithCredential(credential)
          //
          // Manual OTP verification is the only place where
          // Firebase authentication is completed.
        },

        // ======================================================
        // VERIFICATION FAILED
        // ======================================================

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

        // ======================================================
        // OTP SENT
        // ======================================================

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

        // ======================================================
        // AUTO RETRIEVAL TIMEOUT
        // ======================================================

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

  // ============================================================
  // VERIFY OTP
  //
  // ONLY THIS METHOD CREATES THE FIREBASE LOGIN SESSION.
  //
  // Wrong OTP:
  //   -> exception
  //   -> no Walker ID
  //   -> no Firestore profile
  //   -> no SharedPreferences login
  //   -> no navigation
  //
  // Correct OTP:
  //   -> Firebase Auth success
  //   -> returns true
  // ============================================================

  Future<bool> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final String cleanVerificationId =
        verificationId.trim();

    final String cleanOtp = smsCode.trim();

    // ==========================================================
    // VERIFICATION ID VALIDATION
    // ==========================================================

    if (cleanVerificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message:
            'Firebase verification ID is empty.',
      );
    }

    // ==========================================================
    // OTP VALIDATION
    // ==========================================================

    if (!RegExp(r'^[0-9]{6}$').hasMatch(cleanOtp)) {
      throw FirebaseAuthException(
        code: 'invalid-otp-format',
        message:
            'OTP must contain exactly 6 digits.',
      );
    }

    try {
      // ========================================================
      // CREATE PHONE CREDENTIAL
      // ========================================================

      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: cleanVerificationId,
        smsCode: cleanOtp,
      );

      // ========================================================
      // FIREBASE AUTH
      // ========================================================

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

      // ========================================================
      // SUCCESS
      // ========================================================

      debugPrint('========================================');
      debugPrint('FIREBASE OTP AUTH SUCCESS');
      debugPrint('UID: ${user.uid}');
      debugPrint(
        'PHONE: ${user.phoneNumber ?? 'unknown'}',
      );
      debugPrint('========================================');

      // ========================================================
      // FINAL SESSION CHECK
      // ========================================================

      final User? currentUser =
          _auth.currentUser;

      if (currentUser == null) {
        throw FirebaseAuthException(
          code: 'session-not-created',
          message:
              'Firebase login session was not created.',
        );
      }

      debugPrint(
        'FIREBASE OTP LOGIN COMPLETE',
      );

      return true;
    } on FirebaseAuthException {
      // IMPORTANT:
      // Wrong OTP comes directly back to OTP screen.
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

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // LOGIN STATE
  // ============================================================

  bool get isFirebaseLoggedIn {
    return _auth.currentUser != null;
  }

  // ============================================================
  // UID
  // ============================================================

  String? get currentUid {
    return _auth.currentUser?.uid;
  }

  // ============================================================
  // PHONE
  // ============================================================

  String? get currentPhoneNumber {
    return _auth.currentUser?.phoneNumber;
  }

  // ============================================================
  // LOGOUT
  // ============================================================

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
