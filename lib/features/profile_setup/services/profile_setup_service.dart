import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileSetupService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // =====================================================
  // CHECK WALKER PROFILE
  // =====================================================

  static Future<bool> isWalkerProfileCompleted({
    required String walkerUid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> document =
        await _firestore
            .collection('walkers')
            .doc(walkerUid)
            .get();

    if (!document.exists) {
      return false;
    }

    final Map<String, dynamic>? data = document.data();

    return data?['profileCompleted'] == true;
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
    // UPLOAD PROFILE SELFIE
    // ===================================================

    final Reference photoReference = _storage
        .ref()
        .child('walker_profiles')
        .child(walkerUid)
        .child('selfie.jpg');

    await photoReference.putFile(
      selfieFile,
      SettableMetadata(
        contentType: 'image/jpeg',
      ),
    );

    final String photoUrl =
        await photoReference.getDownloadURL();

    // ===================================================
    // FORMAT DATE
    // ===================================================

    final String month =
        dateOfBirth.month.toString().padLeft(2, '0');

    final String day =
        dateOfBirth.day.toString().padLeft(2, '0');

    final String formattedDate =
        '${dateOfBirth.year}-$month-$day';

    // ===================================================
    // SAVE TO FIRESTORE
    // ===================================================

    await _firestore
        .collection('walkers')
        .doc(walkerUid)
        .set(
      {
        // -------------------------------------------------
        // PROFILE INFORMATION
        // -------------------------------------------------

        'Aadhar Number': aadhaar.trim(),

        'Adress': address.trim(),

        'Date Of Birth': formattedDate,

        'Full Name': name.trim(),

        'Mobile number': phoneNumber.trim(),

        'Pincode': pinCode.trim(),

        'Profile Selfie': photoUrl,

        'Walker Uid': walkerUid,

        // -------------------------------------------------
        // AADHAAR UPLOAD STATUS
        // -------------------------------------------------

        'aadhaar_front_uploaded': false,

        'aadhaar_back_uploaded': false,

        // -------------------------------------------------
        // PROFILE COMPLETION
        // -------------------------------------------------

        'profileCompleted': true,
      },
      SetOptions(
        merge: true,
      ),
    );
  }
}
