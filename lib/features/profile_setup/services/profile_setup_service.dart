// File location:
// lib/features/profile_setup/services/profile_setup_service.dart

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
  // FIRESTORE COLLECTION
  // ============================================================

  static const String _collection = 'walkerProfiles';

  // ============================================================
  // FIRESTORE FIELD NAMES
  //
  // IMPORTANT:
  // These names must match your Firestore database exactly.
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
  // ADDITIONAL INTERNAL FIELDS
  //
  // These are kept in the same walkerProfiles document.
  // ============================================================

  static const String _authUidField = 'authUid';

  static const String _roleField = 'role';

  static const String _villageField = 'Village';

  static const String _cityField = 'City';

  static const String _districtField = 'District';

  static const String _stateField = 'State';

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

  static const String _createdAtField = 'createdAt';

  static const String _updatedAtField = 'updatedAt';

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
  // CHECK PROFILE COMPLETION
  //
  // This checks the EXACT Firestore field names.
  // ============================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      return false;
    }

    try {
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

      // ========================================================
      // REQUIRED PROFILE STATUS
      // ========================================================

      final bool profileCompleted =
          data[_profileCompletedField] == true;

      // ========================================================
      // EXACT FIELD NAMES
      // ========================================================

      final String walkerId =
          data[_walkerUidField]
                  ?.toString()
                  .trim() ??
              '';

      final String fullName =
          data[_fullNameField]
                  ?.toString()
                  .trim() ??
              '';

      final String phoneNumber =
          data[_mobileNumberField]
                  ?.toString()
                  .trim() ??
              '';

      final String dateOfBirth =
          data[_dateOfBirthField]
                  ?.toString()
                  .trim() ??
              '';

      final String address =
          data[_addressField]
                  ?.toString()
                  .trim() ??
              '';

      final String pinCode =
          data[_pinCodeField]
                  ?.toString()
                  .trim() ??
              '';

      final String aadhaarNumber =
          data[_aadhaarNumberField]
                  ?.toString()
                  .trim() ??
              '';

      final String selfie =
          data[_profileSelfieField]
                  ?.toString()
                  .trim() ??
              '';

      // ========================================================
      // AADHAAR DOCUMENTS
      // ========================================================

      final String aadhaarFront =
          data[_aadhaarFrontField]
                  ?.toString()
                  .trim() ??
              '';

      final String aadhaarBack =
          data[_aadhaarBackField]
                  ?.toString()
                  .trim() ??
              '';

      // ========================================================
      // VERIFICATION FLAGS
      // ========================================================

      final bool aadhaarVerified =
          data[_aadhaarVerifiedField] == true;

      final bool nameMatched =
          data[_nameMatchedField] == true;

      final bool dobMatched =
          data[_dobMatchedField] == true;

      // ========================================================
      // FINAL CHECK
      // ========================================================

      return profileCompleted &&
          walkerId.isNotEmpty &&
          fullName.isNotEmpty &&
          phoneNumber.isNotEmpty &&
          dateOfBirth.isNotEmpty &&
          address.isNotEmpty &&
          pinCode.isNotEmpty &&
          aadhaarNumber.isNotEmpty &&
          selfie.isNotEmpty &&
          aadhaarFront.isNotEmpty &&
          aadhaarBack.isNotEmpty &&
          aadhaarVerified &&
          nameMatched &&
          dobMatched;
    } catch (e) {
      // ========================================================
      // DO NOT HIDE FIRESTORE ERRORS
      // ========================================================

      rethrow;
    }
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
        'File does not exist.',
      );
    }

    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
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
  //
  // Existing URL -> use URL
  // Local File   -> upload
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

    // Existing Firebase/download URL.
    if (cleanUrl.isNotEmpty) {
      return cleanUrl;
    }

    // Local image file.
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
    // ==========================================================
    // CLEAN UID
    // ==========================================================

    final String cleanUid =
        authUid.trim();

    // ==========================================================
    // CLEAN PERSONAL DATA
    // ==========================================================

    final String cleanPhone =
        phoneNumber.trim();

    final String cleanName =
        name.trim();

    final String cleanAadhaar =
        aadhaar.trim();

    // ==========================================================
    // CLEAN ADDRESS PARTS
    // ==========================================================

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

    // ==========================================================
    // CLEAN VERIFIED NAME
    // ==========================================================

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

    if (cleanName.isEmpty) {
      throw Exception(
        'Full name is required.',
      );
    }

    if (cleanPhone.isEmpty) {
      throw Exception(
        'Phone number is required.',
      );
    }

    if (!RegExp(r'^\d{12}$')
        .hasMatch(cleanAadhaar)) {
      throw Exception(
        'Aadhaar number must contain 12 digits.',
      );
    }

    if (cleanVillage.isEmpty) {
      throw Exception(
        'Village or locality is required.',
      );
    }

    if (cleanCity.isEmpty) {
      throw Exception(
        'City or town is required.',
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
        'PIN code must contain 6 digits.',
      );
    }

    // ==========================================================
    // AADHAAR VERIFICATION VALIDATION
    // ==========================================================

    if (!aadhaarVerified) {
      throw Exception(
        'Aadhaar has not been verified.',
      );
    }

    if (!nameMatched) {
      throw Exception(
        'Name has not been matched.',
      );
    }

    if (!dobMatched) {
      throw Exception(
        'Date of Birth has not been matched.',
      );
    }

    // ==========================================================
    // PROFILE DOCUMENT
    //
    // walkerProfiles/{Firebase Auth UID}
    // ==========================================================

    final DocumentReference<
        Map<String, dynamic>> profileRef =
        _firestore
            .collection(_collection)
            .doc(cleanUid);

    // ==========================================================
    // GET EXISTING PROFILE
    // ==========================================================

    final DocumentSnapshot<
        Map<String, dynamic>> existing =
        await profileRef.get();

    // ==========================================================
    // KEEP EXISTING WALKER UID
    // ==========================================================

    String walkerId =
        existing.data()?[
                    _walkerUidField]
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      walkerId =
          createWalkerId(cleanUid);
    }

    // ==========================================================
    // DATE FORMAT
    // YYYY-MM-DD
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
    // PROFILE SELFIE
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
    // AADHAAR FRONT
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
    // AADHAAR BACK
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
    // COMBINED ADDRESS
    //
    // Village + City + District + State + PIN
    // are stored together in "Adress".
    // ==========================================================

    final String fullAddress =
        '$cleanVillage, '
        '$cleanCity, '
        '$cleanDistrict, '
        '$cleanState - '
        '$cleanPinCode';

    // ==========================================================
    // FIRESTORE DATA
    //
    // IMPORTANT:
    // Main user-facing fields use your EXACT names.
    // ==========================================================

    final Map<String, dynamic> profileData =
        <String, dynamic>{
      // --------------------------------------------------------
      // AUTH / ROLE
      // --------------------------------------------------------

      _authUidField: cleanUid,

      _roleField: 'walker',

      // --------------------------------------------------------
      // EXACT PROFILE FIELDS
      // --------------------------------------------------------

      _fullNameField: cleanName,

      _mobileNumberField: cleanPhone,

      _dateOfBirthField: formattedDate,

      _addressField: fullAddress,

      _pinCodeField: cleanPinCode,

      _aadhaarNumberField: cleanAadhaar,

      _profileSelfieField: finalSelfieUrl,

      _walkerUidField: walkerId,

      // --------------------------------------------------------
      // ADDRESS COMPONENTS
      //
      // These are also stored individually for future use,
      // while "Adress" contains the complete address.
      // --------------------------------------------------------

      _villageField: cleanVillage,

      _cityField: cleanCity,

      _districtField: cleanDistrict,

      _stateField: cleanState,

      // --------------------------------------------------------
      // AADHAAR IMAGES
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

      // --------------------------------------------------------
      // PROFILE STATUS
      // --------------------------------------------------------

      _profileCompletedField:
          true,

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
      SetOptions(
        merge: true,
      ),
    );
  }
}
