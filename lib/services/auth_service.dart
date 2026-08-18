// File location: lib/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _role = 'walker';

  // =====================================================
  // MONTH LETTER
  // =====================================================

  String _monthLetter(int month) {
    const Map<int, String> months = {
      1: 'J',
      2: 'F',
      3: 'R',
      4: 'A',
      5: 'Y',
      6: 'U',
      7: 'L',
      8: 'G',
      9: 'P',
      10: 'O',
      11: 'N',
      12: 'D',
    };

    return months[month] ?? 'X';
  }

  // =====================================================
  // DAY LETTER
  // =====================================================

  String _dayLetter(int weekday) {
    const Map<int, String> days = {
      DateTime.monday: 'M',
      DateTime.tuesday: 'T',
      DateTime.wednesday: 'W',
      DateTime.thursday: 'R',
      DateTime.friday: 'F',
      DateTime.saturday: 'S',
      DateTime.sunday: 'N',
    };

    return days[weekday] ?? 'X';
  }

  // =====================================================
  // CREATE / GET WALKER ACCOUNT
  // =====================================================

  Future<String> _ensureWalkerAccount(User user) async {
    final String uid = user.uid;

    final DocumentReference<Map<String, dynamic>> accountRef =
        _firestore.collection('phoneAccounts').doc(uid);

    final DocumentReference<Map<String, dynamic>> counterRef =
        _firestore.collection('counters').doc('walker');

    final DateTime now = DateTime.now();

    final String year = now.year.toString();
    final String month = _monthLetter(now.month);
    final String day = _dayLetter(now.weekday);

    try {
      final String walkerId =
          await _firestore.runTransaction<String>(
        (transaction) async {
          // =================================================
          // READ EXISTING PHONE ACCOUNT
          // =================================================

          final DocumentSnapshot<Map<String, dynamic>>
              accountSnapshot =
              await transaction.get(accountRef);

          final Map<String, dynamic> accountData =
              accountSnapshot.data() ?? {};

          // =================================================
          // EXISTING WALKER ID
          // =================================================

          final dynamic existingWalkerId =
              accountData['walkerId'];

          if (existingWalkerId is String &&
              existingWalkerId.trim().isNotEmpty) {
            return existingWalkerId.trim();
          }

          // =================================================
          // READ COUNTER
          // =================================================

          final DocumentSnapshot<Map<String, dynamic>>
              counterSnapshot =
              await transaction.get(counterRef);

          final Map<String, dynamic> counterData =
              counterSnapshot.data() ?? {};

          final int lastSerial =
              (counterData['lastSerial'] as num?)?.toInt() ?? 0;

          final int nextSerial = lastSerial + 1;

          if (nextSerial > 9999) {
            throw Exception(
              'Walker serial number limit reached.',
            );
          }

          // =================================================
          // FOUR DIGIT SERIAL
          // =================================================

          final String serial =
              nextSerial.toString().padLeft(4, '0');

          final String newWalkerId =
              '$year$month$day$serial';

          // =================================================
          // COUNTER UPDATE
          // =================================================

          transaction.set(
            counterRef,
            {
              'lastSerial': nextSerial,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          // =================================================
          // PHONE ACCOUNT
          // =================================================

          transaction.set(
            accountRef,
            {
              'authUid': uid,
              'role': _role,
              'active': true,
              'walkerId': newWalkerId,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          return newWalkerId;
        },
      );

      debugPrint('========================================');
      debugPrint('WALKER ACCOUNT READY');
      debugPrint('WALKER ID: $walkerId');
      debugPrint('AUTH UID: $uid');
      debugPrint('ROLE: $_role');
      debugPrint('========================================');

      return walkerId;
    } on FirebaseException catch (e) {
      debugPrint('========================================');
      debugPrint('WALKER FIRESTORE ERROR');
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('========================================');

      rethrow;
    } catch (e) {
      debugPrint(
        'WALKER ACCOUNT CREATION ERROR: $e',
      );
      rethrow;
    }
  }

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

        verificationCompleted:
            (PhoneAuthCredential credential) async {
          try {
            final UserCredential result =
                await _auth.signInWithCredential(
              credential,
            );

            final User? user = result.user;

            if (user == null) {
              return;
            }

            final String walkerId =
                await _ensureWalkerAccount(user);

            final SharedPreferences prefs =
                await SharedPreferences.getInstance();

            await prefs.setBool(
              'isLoggedIn',
              true,
            );

            await prefs.setString(
              'walkerId',
              walkerId,
            );

            debugPrint(
              'AUTO LOGIN SUCCESS: $walkerId',
            );
          } catch (e) {
            debugPrint(
              'AUTO LOGIN ACCOUNT SETUP ERROR: $e',
            );

            await _auth.signOut();
          }
        },

        verificationFailed: (
          FirebaseAuthException e,
        ) {
          debugPrint(
            'PHONE VERIFICATION FAILED: '
            '${e.code} - ${e.message}',
          );

          onError(
            '${e.code}: '
            '${e.message ?? 'Firebase phone verification failed.'}',
          );
        },

        codeSent: (
          String verificationId,
          int? resendToken,
        ) {
          debugPrint('FIREBASE OTP SENT');

          onCodeSent(
            verificationId,
          );
        },

        codeAutoRetrievalTimeout: (
          String verificationId,
        ) {
          debugPrint(
            'FIREBASE OTP AUTO RETRIEVAL TIMEOUT',
          );
        },
      );
    } on FirebaseAuthException catch (e) {
      onError(
        '${e.code}: '
        '${e.message ?? 'Phone verification failed.'}',
      );
    } catch (e) {
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

    final String cleanOtp = smsCode.trim();

    if (cleanVerificationId.isEmpty) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message:
            'Firebase verification ID is empty.',
      );
    }

    if (!RegExp(r'^[0-9]{6}$').hasMatch(cleanOtp)) {
      throw FirebaseAuthException(
        code: 'invalid-otp-format',
        message:
            'OTP must contain exactly 6 digits.',
      );
    }

    try {
      final PhoneAuthCredential credential =
          PhoneAuthProvider.credential(
        verificationId: cleanVerificationId,
        smsCode: cleanOtp,
      );

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
      // FIRESTORE WALKER ACCOUNT
      // =================================================

      final String walkerId =
          await _ensureWalkerAccount(user);

      // =================================================
      // LOCAL SESSION
      // =================================================

      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        'isLoggedIn',
        true,
      );

      await prefs.setString(
        'walkerId',
        walkerId,
      );

      // =================================================
      // FINAL SESSION CHECK
      // =================================================

      if (_auth.currentUser == null) {
        throw FirebaseAuthException(
          code: 'session-not-created',
          message:
              'Firebase login session was not created.',
        );
      }

      debugPrint('========================================');
      debugPrint('WALKER LOGIN SUCCESS');
      debugPrint(
        'FIREBASE UID: ${_auth.currentUser!.uid}',
      );
      debugPrint(
        'WALKER ID: $walkerId',
      );
      debugPrint('========================================');

      return true;
    } on FirebaseException {
      rethrow;
    } on FirebaseAuthException {
      rethrow;
    } catch (e) {
      debugPrint(
        'WALKER ACCOUNT SETUP ERROR: $e',
      );

      throw FirebaseAuthException(
        code: 'walker-account-setup-failed',
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
  // FIREBASE LOGIN
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

      await prefs.remove(
        'walkerId',
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
