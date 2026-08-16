import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileSetupService {
  ProfileSetupService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // =====================================================
  // WALKER DOCUMENT
  // =====================================================

  static DocumentReference<Map<String, dynamic>>
      _walkerDocument(String walkerUid) {
    return _firestore
        .collection('walkers')
        .doc(walkerUid);
  }

  // =====================================================
  // CHECK WALKER PROFILE
  // =====================================================

  static Future<bool> isWalkerProfileCompleted({
    required String walkerUid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>>
        document =
        await _walkerDocument(walkerUid).get();

    if (!document.exists) {
      return false;
    }

    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return data['profileCompleted'] == true;
  }

  // =====================================================
  // SAVE WALKER PROFILE
  // =====================================================

  static Future<void> saveWalkerProfile({
    required String walkerUid,
    required String phoneNumber,
    required String name,
    required DateTime dateOfBirth,
    required String aadhaar,
    required String address,
    required String pinCode,
    required File selfieFile,
  }) async {
    // ===================================================
    // VALIDATION
    // ===================================================

    if (walkerUid.trim().isEmpty) {
      throw Exception(
        'Walker UID is required.',
      );
    }

    if (name.trim().isEmpty) {
      throw Exception(
        'Full name is required.',
      );
    }

    if (phoneNumber.trim().isEmpty) {
      throw Exception(
        'Mobile number is required.',
      );
    }

    if (aadhaar.trim().isEmpty) {
      throw Exception(
        'Aadhaar number is required.',
      );
    }

    if (address.trim().isEmpty) {
      throw Exception(
        'Address is required.',
      );
    }

    if (pinCode.trim().isEmpty) {
      throw Exception(
        'PIN code is required.',
      );
    }

    // ===================================================
    // UPLOAD PROFILE SELFIE
    // ===================================================

    final Reference photoReference = _storage
        .ref()
        .child('walker_profiles')
        .child(walkerUid)
        .child('selfie.jpg');

    final SettableMetadata metadata =
        SettableMetadata(
      contentType: 'image/jpeg',
      customMetadata: {
        'uid': walkerUid,
        'type': 'profile_selfie',
      },
    );

    await photoReference.putFile(
      selfieFile,
      metadata,
    );

    final String photoUrl =
        await photoReference.getDownloadURL();

    // ===================================================
    // FORMAT DATE
    // YYYY-MM-DD
    // ===================================================

    final String month =
        dateOfBirth.month
            .toString()
            .padLeft(2, '0');

    final String day =
        dateOfBirth.day
            .toString()
            .padLeft(2, '0');

    final String formattedDate =
        '${dateOfBirth.year}-$month-$day';

    // ===================================================
    // SAVE FIRESTORE
    //
    // IMPORTANT:
    // Aadhaar front/back status is NOT written here.
    //
    // Therefore existing:
    // aadhaar_front_uploaded
    // aadhaar_back_uploaded
    //
    // will NOT be reset to false.
    // ===================================================

    await _walkerDocument(walkerUid).set(
      {
        // -------------------------------------------------
        // PROFILE INFORMATION
        // -------------------------------------------------

        'Full Name': name.trim(),

        'Date Of Birth': formattedDate,

        'Aadhar Number': aadhaar.trim(),

        // IMPORTANT:
        // Firestore already uses "Adress"
        'Adress': address.trim(),

        'Pincode': pinCode.trim(),

        'Mobile number': phoneNumber.trim(),

        'Profile Selfie': photoUrl,

        'Walker Uid': walkerUid,

        // -------------------------------------------------
        // PROFILE STATUS
        // -------------------------------------------------

        'profileCompleted': true,

        // -------------------------------------------------
        // ACCOUNT INFORMATION
        // -------------------------------------------------

        'role': 'walker',

        'updatedAt':
            FieldValue.serverTimestamp(),
      },

      // Existing fields are preserved.
      SetOptions(
        merge: true,
      ),
    );
  }

  // =====================================================
  // GET WALKER PROFILE
  // =====================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>>
      getWalkerProfile({
    required String walkerUid,
  }) async {
    return _walkerDocument(walkerUid).get();
  }
}
