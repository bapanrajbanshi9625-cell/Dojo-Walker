// File:
// lib/features/profile_setup/services/profile_setup_service.dart

import 'dart:developer' as developer;
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

  // ============================================================
  // COLLECTION
  // ============================================================

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

  // ============================================================
  // ADDRESS
  // ============================================================

  static const String _villageField = 'Village';
  static const String _cityField = 'City';
  static const String _districtField = 'District';
  static const String _stateField = 'State';

  // ============================================================
  // AUTH / ROLE
  // ============================================================

  static const String _authUidField = 'authUid';
  static const String _roleField = 'role';

  // ============================================================
  // AADHAAR DOCUMENTS
  // ============================================================

  static const String _aadhaarFrontField = 'Aadhaar Front';
  static const String _aadhaarBackField = 'Aadhaar Back';

  // ============================================================
  // VERIFICATION
  // ============================================================

  static const String _aadhaarVerifiedField =
      'aadhaarVerified';

  static const String _nameMatchedField =
      'nameMatched';

  static const String _dobMatchedField =
      'dobMatched';

  static const String _aadhaarVerifiedNameField =
      'aadhaarVerifiedName';

  static const String _verificationStatusField =
      'verificationStatus';

  static const String _verificationMessageField =
      'verificationMessage';

  static const String _verifiedByField =
      'verifiedBy';

  static const String _verifiedAtField =
      'verifiedAt';

  // ============================================================
  // PROFILE STATUS
  // ============================================================

  static const String _profileCompletedField =
      'profileCompleted';

  static const String _createdAtField =
      'createdAt';

  static const String _updatedAtField =
      'updatedAt';

  // ============================================================
  // GET WALKER PROFILE
  // ============================================================

  static Future<DocumentSnapshot<Map<String, dynamic>>>
      getWalkerProfile({
    required String authUid,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    return _firestore
        .collection(_collection)
        .doc(cleanUid)
        .get();
  }

  // ============================================================
  // CHECK PROFILE COMPLETED
  // ============================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      return false;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        document = await _firestore
            .collection(_collection)
            .doc(cleanUid)
            .get();

    if (!document.exists) {
      return false;
    }

    final Map<String, dynamic> data =
        document.data() ??
            <String, dynamic>{};

    return data[_profileCompletedField] == true;
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

    final DocumentSnapshot<Map<String, dynamic>>
        document = await _firestore
            .collection(_collection)
            .doc(cleanUid)
            .get();

    if (!document.exists) {
      return 'not_found';
    }

    final Map<String, dynamic> data =
        document.data() ??
            <String, dynamic>{};

    final String status = _stringValue(
      data[_verificationStatusField],
    ).toLowerCase();

    return status.isEmpty ? 'pending' : status;
  }

  // ============================================================
  // CREATE WALKER ID
  // ============================================================

  static String createWalkerId(
    String authUid,
  ) {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    if (cleanUid.length >= 8) {
      return 'WKR-${cleanUid.substring(0, 8).toUpperCase()}';
    }

    return 'WKR-${cleanUid.toUpperCase()}';
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  static String _stringValue(dynamic value) {
    return value?.toString().trim() ?? '';
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
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    if (!await file.exists()) {
      throw Exception(
        'Selected image file does not exist.',
      );
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
    final String cleanUrl =
        url?.trim() ?? '';

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

    throw Exception(
      'Required image is missing.',
    );
  }

  // ============================================================
  // SAVE WALKER PROFILE
  //
  // If verification is successful:
  //
  // aadhaarVerified = true
  // nameMatched = true
  // dobMatched = true
  // verificationStatus = approved
  // profileCompleted = true
  //
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

    // ==========================================================
    // VERIFICATION PARAMETERS
    // ==========================================================

    bool aadhaarVerified = false,
    bool nameMatched = false,
    bool dobMatched = false,
    String aadhaarVerifiedName = '',
  }) async {
    // ==========================================================
    // CLEAN DATA
    // ==========================================================

    final String cleanUid =
        authUid.trim();

    final String cleanPhone =
        phoneNumber.trim();

    final String cleanName =
        name.trim();

    final String cleanAadhaar =
        aadhaar.trim();

    final String cleanVillage =
        village.trim();

    final String cleanCity =
        city.trim();

    final String cleanDistrict =
        district.trim();

    final String cleanState =
        state.trim();

    final String cleanPinCode =
        pinCode.trim();

    final String cleanVerifiedName =
        aadhaarVerifiedName.trim();

    // ==========================================================
    // BASIC VALIDATION
    // ==========================================================

    if (cleanUid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    if (cleanPhone.isEmpty) {
      throw Exception(
        'Mobile number is required.',
      );
    }

    if (cleanName.isEmpty) {
      throw Exception(
        'Full Name is required.',
      );
    }

    if (!RegExp(r'^\d{12}$')
        .hasMatch(cleanAadhaar)) {
      throw Exception(
        'Aadhaar Number must contain exactly 12 digits.',
      );
    }

    if (cleanVillage.isEmpty) {
      throw Exception(
        'Village / Locality is required.',
      );
    }

    if (cleanCity.isEmpty) {
      throw Exception(
        'City / Town is required.',
      );
    }

    if (cleanDistrict.isEmpty) {
      throw Exception(
        'District is required.',
      );
    }

    if (cleanState.isEmpty) {
      throw Exception(
        'State is required.',
      );
    }

    if (!RegExp(r'^\d{6}$')
        .hasMatch(cleanPinCode)) {
      throw Exception(
        'Pincode must contain exactly 6 digits.',
      );
    }

    // ==========================================================
    // SECURITY:
    // PROFILE CAN ONLY BE COMPLETED WHEN ALL MATCHES ARE TRUE
    // ==========================================================

    final bool profileCompleted =
        aadhaarVerified &&
        nameMatched &&
        dobMatched;

    final String verificationStatus =
        profileCompleted
            ? 'approved'
            : 'pending';

    final String verificationMessage =
        profileCompleted
            ? 'Aadhaar, Name and Date of Birth verified successfully.'
            : 'Documents submitted. Waiting for verification.';

    // ==========================================================
    // UPLOAD SELFIE
    // ==========================================================

    final String finalSelfieUrl =
        await _resolveImage(
      authUid: cleanUid,
      folder: 'selfie',
      fileName: 'selfie.jpg',
      file: selfieFile,
      url: selfieUrl,
    );

    // ==========================================================
    // UPLOAD AADHAAR FRONT
    // ==========================================================

    final String finalFrontUrl =
        await _resolveImage(
      authUid: cleanUid,
      folder: 'aadhaar',
      fileName: 'front.jpg',
      file: aadhaarFrontFile,
      url: aadhaarFrontUrl,
    );

    // ==========================================================
    // UPLOAD AADHAAR BACK
    // ==========================================================

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

    final DocumentReference<Map<String, dynamic>>
        profileRef = _firestore
            .collection(_collection)
            .doc(cleanUid);

    // ==========================================================
    // EXISTING PROFILE
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        existing = await profileRef.get();

    final Map<String, dynamic> existingData =
        existing.data() ??
            <String, dynamic>{};

    // ==========================================================
    // WALKER ID
    // ==========================================================

    String walkerId =
        _stringValue(
      existingData[_walkerUidField],
    );

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(
        cleanUid,
      );
    }

    // ==========================================================
    // DATE
    // ==========================================================

    final String month =
        dateOfBirth.month
            .toString()
            .padLeft(2, '0');

    final String day =
        dateOfBirth.day
            .toString()
            .padLeft(2, '0');

    final String formattedDate =
        '${dateOfBirth.year}-'
        '$month-'
        '$day';

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

    final Map<String, dynamic>
        profileData =
        <String, dynamic>{
      // --------------------------------------------------------
      // AUTH
      // --------------------------------------------------------

      _authUidField:
          cleanUid,

      _roleField:
          'walker',

      // --------------------------------------------------------
      // MAIN PROFILE
      // --------------------------------------------------------

      _fullNameField:
          cleanName,

      _mobileNumberField:
          cleanPhone,

      _dateOfBirthField:
          formattedDate,

      _addressField:
          fullAddress,

      _pinCodeField:
          cleanPinCode,

      _aadhaarNumberField:
          cleanAadhaar,

      _profileSelfieField:
          finalSelfieUrl,

      _walkerUidField:
          walkerId,

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      _villageField:
          cleanVillage,

      _cityField:
          cleanCity,

      _districtField:
          cleanDistrict,

      _stateField:
          cleanState,

      // --------------------------------------------------------
      // AADHAAR
      // --------------------------------------------------------

      _aadhaarFrontField:
          finalFrontUrl,

      _aadhaarBackField:
          finalBackUrl,

      // --------------------------------------------------------
      // VERIFICATION
      // --------------------------------------------------------

      _aadhaarVerifiedField:
          aadhaarVerified,

      _nameMatchedField:
          nameMatched,

      _dobMatchedField:
          dobMatched,

      _aadhaarVerifiedNameField:
          cleanVerifiedName,

      _verificationStatusField:
          verificationStatus,

      _verificationMessageField:
          verificationMessage,

      _verifiedByField:
          profileCompleted
              ? 'system'
              : '',

      _verifiedAtField:
          profileCompleted
              ? FieldValue.serverTimestamp()
              : null,

      // --------------------------------------------------------
      // PROFILE COMPLETION
      // --------------------------------------------------------

      _profileCompletedField:
          profileCompleted,

      // --------------------------------------------------------
      // UPDATED
      // --------------------------------------------------------

      _updatedAtField:
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // CREATED AT
    // ==========================================================

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

    // ==========================================================
    // VERIFY SAVE
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        saved = await profileRef.get();

    final Map<String, dynamic> savedData =
        saved.data() ??
            <String, dynamic>{};

    final bool savedCompleted =
        savedData[_profileCompletedField] == true;

    if (profileCompleted && !savedCompleted) {
      throw Exception(
        'Profile was saved but profileCompleted could not be confirmed.',
      );
    }

    // ==========================================================
    // LOG
    // ==========================================================

    developer.log(
      'Walker profile saved successfully. '
      'uid=$cleanUid '
      'walkerId=$walkerId '
      'verificationStatus=$verificationStatus '
      'profileCompleted=$profileCompleted',
      name: 'ProfileSetupService',
    );
  }
}
