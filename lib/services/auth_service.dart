import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  AuthService._();

  static final AuthService instance =
      AuthService._();

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // SEND OTP
  // ============================================================

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
  }) async {
    try {
      final String cleanPhone =
          phoneNumber.trim();

      if (!RegExp(r'^[0-9]{10}$')
          .hasMatch(cleanPhone)) {
        onError(
          'Please enter a valid 10-digit mobile number.',
        );
        return;
      }

      final String formattedPhone =
          '+91$cleanPhone';

      debugPrint(
        'FIREBASE OTP REQUEST: $formattedPhone',
      );

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,

        verificationCompleted:
            (PhoneAuthCredential credential) {
          debugPrint(
            'Automatic verification available.',
          );
        },

        verificationFailed:
            (FirebaseAuthException e) {
          debugPrint(
            'Phone verification failed: '
            '${e.code} - ${e.message}',
          );

          onError(
            e.message ??
                'Firebase phone verification failed.',
          );
        },

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          debugPrint(
            'OTP sent successfully.',
          );

          onCodeSent(
            verificationId,
          );
        },

        codeAutoRetrievalTimeout:
            (String verificationId) {
          debugPrint(
            'OTP auto retrieval timeout.',
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      onError(
        e.message ??
            'Phone verification failed.',
      );
    } catch (e) {
      onError(
        e.toString(),
      );
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<bool> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    final String cleanVerificationId =
        verificationId.trim();

    final String cleanOtp =
        smsCode.trim();

    if (cleanVerificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message:
            'Firebase verification ID is empty.',
      );
    }

    if (!RegExp(r'^[0-9]{6}$')
        .hasMatch(cleanOtp)) {
      throw FirebaseAuthException(
        code: 'invalid-otp-format',
        message:
            'OTP must contain exactly 6 digits.',
      );
    }

    try {
      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId:
            cleanVerificationId,
        smsCode: cleanOtp,
      );

      final UserCredential result =
          await _auth.signInWithCredential(
        credential,
      );

      final User? user = result.user;

      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message:
              'Firebase authentication returned no user.',
        );
      }

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
        'OTP AUTH SUCCESS: ${currentUser.uid}',
      );

      return true;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw FirebaseAuthException(
        code: 'otp-verification-error',
        message: e.toString(),
      );
    }
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  bool get isFirebaseLoggedIn =>
      _auth.currentUser != null;

  String? get currentUid =>
      _auth.currentUser?.uid;

  String? get currentPhoneNumber =>
      _auth.currentUser?.phoneNumber;

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    await _auth.signOut();
  }
}
