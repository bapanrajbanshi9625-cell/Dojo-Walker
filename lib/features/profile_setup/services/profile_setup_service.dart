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

    final Map<String, dynamic>? data =
        document.data();

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
    // UPLOAD SELFIE
    // ===================================================

    final Reference photoReference = _storage
        .ref()
        .child('walker_profiles')
        .child(walkerUid)
        .child('selfie.jpg');

    await photoReference.putFile(selfieFile);

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
    // SAVE FIRESTORE
    // ===================================================

    await _firestore
        .collection('walkers')
        .doc(walkerUid)
        .set(
      {
        'uid': walkerUid,
        'role': 'walker',
        'name': name,
        'dateOfBirth': formattedDate,
        'aadhaarNumber': aadhaar,
        'address': address,
        'pinCode': pinCode,
        'phone': phoneNumber,
        'photoUrl': photoUrl,

        // ===============================================
        // IMPORTANT
        // PROFILE COMPLETED
        // ===============================================

        'profileCompleted': true,

        'updatedAt': FieldValue.serverTimestamp(),

        // createdAt ko merge ke saath rakhna safe hai.
        // Existing value ho to overwrite nahi hogi.
        'createdAt': FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }
}
