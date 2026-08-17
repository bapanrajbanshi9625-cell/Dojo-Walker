import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileSetupService {
  ProfileSetupService._();

  // ============================================================
  // FIREBASE
  // ============================================================

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  static const String _collection = 'walkerProfiles';

  // ============================================================
  // GET WALKER PROFILE
  // ============================================================

  static Future<DocumentSnapshot<Map<String, dynamic>>>
      getWalkerProfile({
    required String authUid,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      throw Exception('Authentication UID is missing.');
    }

    return _firestore
        .collection(_collection)
        .doc(cleanUid)
        .get();
  }

  // ============================================================
  // CHECK PROFILE COMPLETION
  //
  // OTP SCREEN CALLS THIS METHOD.
  //
  // Profile is considered complete only when:
  //
  // profileCompleted == true
  // walkerId exists
  // selfie URL exists
  // Aadhaar front URL exists
  // Aadhaar back URL exists
  //
  // ============================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>> document =
        await _firestore
            .collection(_collection)
            .doc(cleanUid)
            .get();

    if (!document.exists) {
      return false;
    }

    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    final bool profileCompleted =
        data['profileCompleted'] == true;

    final String walkerId =
        data['walkerId']?.toString().trim() ?? '';

    final String selfie =
        data['selfie']?.toString().trim() ?? '';

    final String aadhaarFront =
        data['aadharfront']?.toString().trim() ?? '';

    final String aadhaarBack =
        data['aadharback']?.toString().trim() ?? '';

    return profileCompleted &&
        walkerId.isNotEmpty &&
        selfie.isNotEmpty &&
        aadhaarFront.isNotEmpty &&
        aadhaarBack.isNotEmpty;
  }

  // ============================================================
  // CREATE WALKER ID
  // ============================================================

  static String createWalkerId(String authUid) {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      throw Exception('Authentication UID is missing.');
    }

    if (cleanUid.length >= 8) {
      return 'WKR-${cleanUid.substring(0, 8).toUpperCase()}';
    }

    return 'WKR-${cleanUid.toUpperCase()}';
  }

  // ============================================================
  // UPLOAD FILE TO FIREBASE STORAGE
  // ============================================================

  static Future<String> _uploadFile({
    required String authUid,
    required String folder,
    required String fileName,
    required File file,
  }) async {
    if (!await file.exists()) {
      throw Exception(
        'File does not exist: ${file.path}',
      );
    }

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

  // ============================================================
  // SAVE WALKER PROFILE
  // ============================================================

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
    // ==========================================================
    // CLEAN DATA
    // ==========================================================

    final String cleanUid = authUid.trim();
    final String cleanPhone = phoneNumber.trim();
    final String cleanName = name.trim();
    final String cleanAadhaar = aadhaar.trim();
    final String cleanAddress = address.trim();
    final String cleanPinCode = pinCode.trim();

    // ==========================================================
    // BASIC VALIDATION
    // ==========================================================

    if (cleanUid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    if (cleanName.isEmpty) {
      throw Exception(
        'Full name is required.',
      );
    }

    if (cleanAadhaar.length != 12) {
      throw Exception(
        'Aadhaar number must contain 12 digits.',
      );
    }

    if (cleanPinCode.length != 6) {
      throw Exception(
        'PIN code must contain 6 digits.',
      );
    }

    if (cleanAddress.isEmpty) {
      throw Exception(
        'Address is required.',
      );
    }

    // ==========================================================
    // FIRESTORE PROFILE REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>> profileRef =
        _firestore
            .collection(_collection)
            .doc(cleanUid);

    // ==========================================================
    // CHECK EXISTING PROFILE
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>> existing =
        await profileRef.get();

    // ==========================================================
    // WALKER ID
    //
    // Existing Walker ID is preserved.
    // Otherwise create a new one.
    // ==========================================================

    String walkerId =
        existing.data()?['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(cleanUid);
    }

    // ==========================================================
    // UPLOAD PROFILE SELFIE
    // ==========================================================

    final String selfieUrl = await _uploadFile(
      authUid: cleanUid,
      folder: 'selfie',
      fileName: 'selfie.jpg',
      file: selfieFile,
    );

    // ==========================================================
    // UPLOAD AADHAAR FRONT
    // ==========================================================

    final String aadhaarFrontUrl = await _uploadFile(
      authUid: cleanUid,
      folder: 'aadhaar',
      fileName: 'front.jpg',
      file: aadhaarFrontFile,
    );

    // ==========================================================
    // UPLOAD AADHAAR BACK
    // ==========================================================

    final String aadhaarBackUrl = await _uploadFile(
      authUid: cleanUid,
      folder: 'aadhaar',
      fileName: 'back.jpg',
      file: aadhaarBackFile,
    );

    // ==========================================================
    // DATE FORMAT
    // ==========================================================

    final String month =
        dateOfBirth.month.toString().padLeft(2, '0');

    final String day =
        dateOfBirth.day.toString().padLeft(2, '0');

    final String formattedDate =
        '${dateOfBirth.year}-$month-$day';

    // ==========================================================
    // FIRESTORE DATA
    //
    // IMPORTANT:
    //
    // aadharfront = actual Aadhaar front image URL
    // aadharback  = actual Aadhaar back image URL
    // selfie      = actual selfie image URL
    //
    // profileCompleted = completion status
    //
    // No duplicate upload-status fields.
    // ==========================================================

    final Map<String, dynamic> profileData =
        <String, dynamic>{
      // --------------------------------------------------------
      // BACKEND IDENTITY
      // --------------------------------------------------------

      'authUid': cleanUid,
      'walkerId': walkerId,
      'role': 'walker',

      // --------------------------------------------------------
      // PERSONAL INFORMATION
      // --------------------------------------------------------

      'fullName': cleanName,
      'phoneNumber': cleanPhone,
      'dateofbirth': formattedDate,
      'address': cleanAddress,
      'pincode': cleanPinCode,

      // --------------------------------------------------------
      // AADHAAR
      // --------------------------------------------------------

      'aadhaarNumber': cleanAadhaar,
      'aadharfront': aadhaarFrontUrl,
      'aadharback': aadhaarBackUrl,

      // --------------------------------------------------------
      // SELFIE
      // --------------------------------------------------------

      'selfie': selfieUrl,

      // --------------------------------------------------------
      // PROFILE STATUS
      // --------------------------------------------------------

      'profileCompleted': true,

      // --------------------------------------------------------
      // UPDATED TIME
      // --------------------------------------------------------

      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // CREATED TIME
    //
    // Only added when profile document is created for
    // the first time.
    // ==========================================================

    if (!existing.exists) {
      profileData['createdAt'] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // SAVE TO FIRESTORE
    // ==========================================================

    await profileRef.set(
      profileData,
      SetOptions(merge: true),
    );
  }
}
