import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileSetupService {
  ProfileSetupService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  static const String _collection = 'walkerProfiles';

  // =====================================================
  // GET WALKER PROFILE
  // =====================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>> getWalkerProfile({
    required String authUid,
  }) async {
    return _firestore
        .collection(_collection)
        .doc(authUid)
        .get();
  }

  // =====================================================
  // CHECK WALKER PROFILE COMPLETED
  // =====================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>> document =
        await _firestore
            .collection(_collection)
            .doc(authUid)
            .get();

    if (!document.exists) {
      return false;
    }

    final Map<String, dynamic>? data =
        document.data();

    // New structure
    final String selfie =
        data?['selfie']?.toString().trim() ?? '';

    final String aadhaarFront =
        data?['aadharfront']?.toString().trim() ?? '';

    final String aadhaarBack =
        data?['aadharback']?.toString().trim() ?? '';

    final String walkerId =
        data?['walkerId']?.toString().trim() ?? '';

    final bool profileCompleted =
        data?['profileCompleted'] == true;

    return profileCompleted &&
        walkerId.isNotEmpty &&
        selfie.isNotEmpty &&
        aadhaarFront.isNotEmpty &&
        aadhaarBack.isNotEmpty;
  }

  // =====================================================
  // CREATE / GET WALKER ID
  // =====================================================

  static String createWalkerId(String authUid) {
    final String cleanUid = authUid.trim();

    if (cleanUid.length >= 8) {
      return 'WKR-${cleanUid.substring(0, 8).toUpperCase()}';
    }

    return 'WKR-${cleanUid.toUpperCase()}';
  }

  // =====================================================
  // UPLOAD FILE
  // =====================================================

  static Future<String> _uploadFile({
    required String authUid,
    required String folder,
    required String fileName,
    required File file,
  }) async {
    final Reference reference = _storage
        .ref()
        .child('walkerProfiles')
        .child(authUid)
        .child(folder)
        .child(fileName);

    await reference.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
      ),
    );

    return reference.getDownloadURL();
  }

  // =====================================================
  // SAVE WALKER PROFILE
  // =====================================================

  static Future<void> saveWalkerProfile({
    required String authUid,
    required String phoneNumber,
    required String name,
    required DateTime dateOfBirth,
    required String aadhaar,
    required String address,
    required String pinCode,
    required File selfieFile,
    required File aadhaarFrontFile,
    required File aadhaarBackFile,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      throw Exception('Authentication UID is missing.');
    }

    // ===================================================
    // WALKER ID
    // ===================================================

    final DocumentReference<Map<String, dynamic>>
        profileRef = _firestore
            .collection(_collection)
            .doc(cleanUid);

    final DocumentSnapshot<Map<String, dynamic>>
        existing = await profileRef.get();

    String walkerId = '';

    if (existing.exists) {
      walkerId =
          existing.data()?['walkerId']
                  ?.toString()
                  .trim() ??
              '';
    }

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(cleanUid);
    }

    // ===================================================
    // UPLOAD SELFIE
    // ===================================================

    final String selfieUrl = await _uploadFile(
      authUid: cleanUid,
      folder: 'selfie',
      fileName: 'selfie.jpg',
      file: selfieFile,
    );

    // ===================================================
    // UPLOAD AADHAAR FRONT
    // ===================================================

    final String aadhaarFrontUrl =
        await _uploadFile(
      authUid: cleanUid,
      folder: 'aadhaar',
      fileName: 'front.jpg',
      file: aadhaarFrontFile,
    );

    // ===================================================
    // UPLOAD AADHAAR BACK
    // ===================================================

    final String aadhaarBackUrl =
        await _uploadFile(
      authUid: cleanUid,
      folder: 'aadhaar',
      fileName: 'back.jpg',
      file: aadhaarBackFile,
    );

    // ===================================================
    // DATE FORMAT
    // ===================================================

    final String month =
        dateOfBirth.month.toString().padLeft(2, '0');

    final String day =
        dateOfBirth.day.toString().padLeft(2, '0');

    final String formattedDate =
        '${dateOfBirth.year}-$month-$day';

    // ===================================================
    // FIRESTORE
    // ===================================================

    await profileRef.set(
      {
        // ===============================================
        // BACKEND IDENTITY
        // ===============================================

        'authUid': cleanUid,
        'walkerId': walkerId,
        'role': 'walker',

        // ===============================================
        // PROFILE
        // ===============================================

        'fullName': name.trim(),
        'phoneNumber': phoneNumber.trim(),
        'dateofbirth': formattedDate,
        'address': address.trim(),
        'pincode': pinCode.trim(),

        // ===============================================
        // AADHAAR
        // ===============================================

        'aadhaarNumber': aadhaar.trim(),
        'aadharfront': aadhaarFrontUrl,
        'aadharback': aadhaarBackUrl,

        // ===============================================
        // SELFIE
        // ===============================================

        'selfie': selfieUrl,

        // ===============================================
        // STATUS
        // ===============================================

        'aadhaarFrontUploaded': true,
        'aadhaarBackUploaded': true,
        'profileCompleted': true,

        // ===============================================
        // TIMESTAMPS
        // ===============================================

        if (!existing.exists)
          'createdAt': FieldValue.serverTimestamp(),

        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
