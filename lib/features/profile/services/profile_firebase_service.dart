import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileFirebaseService {
  ProfileFirebaseService._();

  static final FirebaseAuth auth =
      FirebaseAuth.instance;

  static final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage storage =
      FirebaseStorage.instance;

  // ==========================================================
  // CURRENT USER
  // ==========================================================

  static User get currentUser {
    final User? user = auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Login session not found.',
      );
    }

    return user;
  }

  static String get uid => currentUser.uid;

  // ==========================================================
  // WALKER DOCUMENT
  // ==========================================================

  static DocumentReference<Map<String, dynamic>>
      get walkerDocument {
    return firestore
        .collection('walkers')
        .doc(uid);
  }

  // ==========================================================
  // UPLOAD AADHAAR
  // ==========================================================

  static Future<String> uploadAadhaar({
    required File file,
    required bool isFront,
  }) async {
    final String side =
        isFront ? 'aadhaar_front' : 'aadhaar_back';

    final String path =
        'walkers/$uid/documents/$side.jpg';

    final Reference reference =
        storage.ref().child(path);

    final SettableMetadata metadata =
        SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uid': uid,
        'document': side,
      },
    );

    await reference.putFile(
      file,
      metadata,
    );

    final String downloadUrl =
        await reference.getDownloadURL();

    await walkerDocument.set(
      {
        side: downloadUrl,
        '${side}_uploaded': true,
        '${side}_uploadedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return downloadUrl;
  }

  // ==========================================================
  // CURRENT PHONE OTP
  // ==========================================================

  static Future<void> sendCurrentPhoneOtp({
    required void Function(
      String verificationId,
    ) onCodeSent,
    required void Function(
      FirebaseAuthException error,
    ) onVerificationFailed,
  }) async {
    final String? phoneNumber =
        currentUser.phoneNumber;

    if (phoneNumber == null ||
        phoneNumber.isEmpty) {
      throw FirebaseAuthException(
        code: 'phone-not-found',
        message:
            'Current mobile number not found.',
      );
    }

    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,

      verificationCompleted:
          (PhoneAuthCredential credential) {},

      verificationFailed:
          onVerificationFailed,

      codeSent: (
        String verificationId,
        int? resendToken,
      ) {
        onCodeSent(
          verificationId,
        );
      },

      codeAutoRetrievalTimeout:
          (String verificationId) {},
    );
  }

  // ==========================================================
  // VERIFY CURRENT PHONE OTP
  // ==========================================================

  static Future<void>
      verifyCurrentPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final PhoneAuthCredential credential =
        PhoneAuthProvider.credential(
      verificationId:
          verificationId,
      smsCode: smsCode,
    );

    await currentUser
        .reauthenticateWithCredential(
      credential,
    );
  }

  // ==========================================================
  // SEND NEW PHONE OTP
  // ==========================================================

  static Future<void> sendNewPhoneOtp({
    required String newPhoneNumber,
    required void Function(
      String verificationId,
    ) onCodeSent,
    required void Function(
      FirebaseAuthException error,
    ) onVerificationFailed,
  }) async {
    await auth.verifyPhoneNumber(
      phoneNumber: newPhoneNumber,

      verificationCompleted:
          (PhoneAuthCredential credential) {},

      verificationFailed:
          onVerificationFailed,

      codeSent: (
        String verificationId,
        int? resendToken,
      ) {
        onCodeSent(
          verificationId,
        );
      },

      codeAutoRetrievalTimeout:
          (String verificationId) {},
    );
  }

  // ==========================================================
  // VERIFY NEW PHONE + UPDATE
  // ==========================================================

  static Future<void>
      verifyAndUpdateNewPhone({
    required String verificationId,
    required String smsCode,
    required String newPhoneNumber,
  }) async {
    final PhoneAuthCredential credential =
        PhoneAuthProvider.credential(
      verificationId:
          verificationId,
      smsCode: smsCode,
    );

    // Firebase Auth
    await currentUser.updatePhoneNumber(
      credential,
    );

    // Firestore
    await walkerDocument.set(
      {
        'phone': newPhoneNumber,
        'phoneUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
