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

  // ============================================================
  // EXACT FIRESTORE FIELD NAMES
  // ============================================================

  static const String _fullNameField = 'Full Name';
  static const String _mobileNumberField = 'Mobile number';
  static const String _dateOfBirthField = 'Date Of Birth';
  static const String _addressField = 'Adress';
  static const String _pinCodeField = 'Pincode';
  static const String _aadhaarNumberField = 'Aadhar Number';
  static const String _profileSelfieField = 'Profile Selfie';
  static const String _walkerUidField = 'Walker Uid';

  static const String _villageField = 'Village';
  static const String _cityField = 'City';
  static const String _districtField = 'District';
  static const String _stateField = 'State';

  static const String _authUidField = 'authUid';
  static const String _roleField = 'role';

  static const String _aadhaarFrontField = 'Aadhaar Front';
  static const String _aadhaarBackField = 'Aadhaar Back';

  static const String _aadhaarVerifiedField =
      'aadhaarVerified';

  static const String _nameMatchedField =
      'nameMatched';

  static const String _dobMatchedField =
      'dobMatched';

  static const String _aadhaarVerifiedNameField =
      'aadhaarVerifiedName';

  static const String _profileCompletedField =
      'profileCompleted';

  static const String _verificationStatusField =
      'verificationStatus';

  static const String _verificationMessageField =
      'verificationMessage';

  static const String _createdAtField = 'createdAt';
  static const String _updatedAtField = 'updatedAt';

  // ============================================================
  // GET PROFILE
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
  // PROFILE COMPLETED
  //
  // ONLY ADMIN APPROVED PROFILE CAN RETURN TRUE.
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
        data[_profileCompletedField] == true;

    final String verificationStatus =
        data[_verificationStatusField]
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    return profileCompleted &&
        verificationStatus == 'approved';
  }

  // ============================================================
  // GET VERIFICATION STATUS
  // ============================================================

  static Future<String> getVerificationStatus({
    required String authUid,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      return 'not_found';
    }

    final DocumentSnapshot<Map<String, dynamic>> document =
        await _firestore
            .collection(_collection)
            .doc(cleanUid)
            .get();

    if (!document.exists) {
      return 'not_found';
    }

    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    return data[_verificationStatusField]
            ?.toString()
            .trim()
            .toLowerCase() ??
        'pending';
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
  // UPLOAD FILE
  // ============================================================

  static Future<String> _uploadFile({
    required String authUid,
    required String folder,
    required String fileName,
    required File file,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      throw Exception('Authentication UID is missing.');
    }

    if (!await file.exists()) {
      throw Exception('Selected image file does not exist.');
    }

    final Reference reference = _storage
        .ref()
        .child('walkerProfiles')
        .child(cleanUid)
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
  // RESOLVE IMAGE
  // ============================================================

  static Future<String> _resolveImage({
    required String authUid,
    required String folder,
    required String fileName,
    File? file,
    String? url,
  }) async {
    final String cleanUrl = url?.trim() ?? '';

    if (cleanUrl.isNotEmpty) {
      return cleanUrl;
    }

    if (file != null) {
      return _uploadFile(
        authUid: authUid,
        folder: folder,
        fileName: fileName,
        file: file,
      );
    }

    throw Exception('Required image is missing.');
  }

  // ============================================================
  // SAVE WALKER PROFILE
  //
  // IMPORTANT:
  // THIS DOES NOT APPROVE THE WALKER.
  //
  // It creates:
  // verificationStatus = pending
  // profileCompleted = false
  // ============================================================

  static Future<void> saveWalkerProfile({
    required String authUid,
    required String phoneNumber,
    required String name,
    required DateTime dateOfBirth,
    required String aadhaar,
    required String village,
    required String city,
    required String district,
    required String state,
    required String pinCode,

    File? selfieFile,
    String? selfieUrl,

    File? aadhaarFrontFile,
    String? aadhaarFrontUrl,

    File? aadhaarBackFile,
    String? aadhaarBackUrl,

    required bool aadhaarVerified,
    required bool nameMatched,
    required bool dobMatched,
    required String aadhaarVerifiedName,
  }) async {
    final String cleanUid = authUid.trim();
    final String cleanPhone = phoneNumber.trim();
    final String cleanName = name.trim();
    final String cleanAadhaar = aadhaar.trim();
    final String cleanVillage = village.trim();
    final String cleanCity = city.trim();
    final String cleanDistrict = district.trim();
    final String cleanState = state.trim();
    final String cleanPinCode = pinCode.trim();
    final String cleanVerifiedName =
        aadhaarVerifiedName.trim();

    if (cleanUid.isEmpty) {
      throw Exception('Authentication UID is missing.');
    }

    if (cleanPhone.isEmpty) {
      throw Exception('Mobile number is required.');
    }

    if (cleanName.isEmpty) {
      throw Exception('Full Name is required.');
    }

    if (!RegExp(r'^\d{12}$').hasMatch(cleanAadhaar)) {
      throw Exception(
        'Aadhaar Number must contain exactly 12 digits.',
      );
    }

    if (cleanVillage.isEmpty) {
      throw Exception('Village / Locality is required.');
    }

    if (cleanCity.isEmpty) {
      throw Exception('City / Town is required.');
    }

    if (cleanDistrict.isEmpty) {
      throw Exception('District is required.');
    }

    if (cleanState.isEmpty) {
      throw Exception('State is required.');
    }

    if (!RegExp(r'^\d{6}$').hasMatch(cleanPinCode)) {
      throw Exception(
        'Pincode must contain exactly 6 digits.',
      );
    }

    // ==========================================================
    // IMAGE UPLOADS
    // ==========================================================

    final String finalSelfieUrl =
        await _resolveImage(
      authUid: cleanUid,
      folder: 'selfie',
      fileName: 'selfie.jpg',
      file: selfieFile,
      url: selfieUrl,
    );

    final String finalFrontUrl =
        await _resolveImage(
      authUid: cleanUid,
      folder: 'aadhaar',
      fileName: 'front.jpg',
      file: aadhaarFrontFile,
      url: aadhaarFrontUrl,
    );

    final String finalBackUrl =
        await _resolveImage(
      authUid: cleanUid,
      folder: 'aadhaar',
      fileName: 'back.jpg',
      file: aadhaarBackFile,
      url: aadhaarBackUrl,
    );

    // ==========================================================
    // PROFILE REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>> profileRef =
        _firestore
            .collection(_collection)
            .doc(cleanUid);

    final DocumentSnapshot<Map<String, dynamic>> existing =
        await profileRef.get();

    final Map<String, dynamic> existingData =
        existing.data() ?? <String, dynamic>{};

    String walkerId =
        existingData[_walkerUidField]
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(cleanUid);
    }

    // ==========================================================
    // DATE
    // ==========================================================

    final String month =
        dateOfBirth.month.toString().padLeft(2, '0');

    final String day =
        dateOfBirth.day.toString().padLeft(2, '0');

    final String formattedDate =
        '${dateOfBirth.year}-$month-$day';

    // ==========================================================
    // FULL ADDRESS
    // ==========================================================

    final String fullAddress =
        '$cleanVillage, '
        '$cleanCity, '
        '$cleanDistrict, '
        '$cleanState - '
        '$cleanPinCode';

    // ==========================================================
    // FIRESTORE DATA
    // ==========================================================

    final Map<String, dynamic> profileData =
        <String, dynamic>{
      _authUidField: cleanUid,
      _roleField: 'walker',

      _fullNameField: cleanName,
      _mobileNumberField: cleanPhone,
      _dateOfBirthField: formattedDate,
      _addressField: fullAddress,
      _pinCodeField: cleanPinCode,
      _aadhaarNumberField: cleanAadhaar,
      _profileSelfieField: finalSelfieUrl,
      _walkerUidField: walkerId,

      _villageField: cleanVillage,
      _cityField: cleanCity,
      _districtField: cleanDistrict,
      _stateField: cleanState,

      _aadhaarFrontField: finalFrontUrl,
      _aadhaarBackField: finalBackUrl,

      // ========================================================
      // MANUAL ADMIN VERIFICATION
      // ========================================================

      _aadhaarVerifiedField: false,
      _nameMatchedField: false,
      _dobMatchedField: false,

      _aadhaarVerifiedNameField:
          cleanVerifiedName,

      _verificationStatusField: 'pending',

      _verificationMessageField:
          'Waiting for admin verification.',

      // ========================================================
      // NOT COMPLETED UNTIL ADMIN APPROVES
      // ========================================================

      _profileCompletedField: false,

      _updatedAtField:
          FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      profileData[_createdAtField] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // SAVE
    // ==========================================================

    await profileRef.set(
      profileData,
      SetOptions(merge: true),
    );

    print('========================================');
    print('WALKER PROFILE SUBMITTED');
    print('COLLECTION: $_collection');
    print('DOCUMENT UID: $cleanUid');
    print('Walker Uid: $walkerId');
    print('verificationStatus: pending');
    print('profileCompleted: false');
    print('========================================');
  }
}
