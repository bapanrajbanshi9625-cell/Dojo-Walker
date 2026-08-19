import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileSetupService {
  ProfileSetupService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  // Admin / verification collection
  static const String walkersCollection = 'walkers';

  // Walker app profile collection
  static const String walkerProfilesCollection = 'walkerProfiles';

  // ============================================================
  // FIRESTORE FIELDS
  // ============================================================

  static const String aadhaarNumberField = 'aadhaarNumber';
  static const String aadhaarVerifiedField = 'aadhaarVerified';

  static const String aadhaarBackField = 'aadhaarback';
  static const String aadhaarFrontField = 'aadhaarfront';

  static const String addressField = 'address';

  static const String authUidField = 'authUid';

  static const String createdAtField = 'createdAt';

  static const String dateOfBirthField = 'dateofbirth';

  static const String dobMatchedField = 'dobMatched';

  static const String fullNameField = 'fullName';

  static const String genderField = 'gender';

  static const String nameMatchedField = 'nameMatched';

  static const String phoneNumberField = 'phoneNumber';

  static const String profileCompletedField =
      'profileCompleted';

  static const String roleField = 'role';

  static const String selfieField = 'selfie';

  static const String updatedAtField = 'updatedAt';

  static const String walkerIdField = 'walkerId';

  static const String verificationStatusField =
      'verificationStatus';

  static const String verificationMessageField =
      'verificationMessage';

  // ============================================================
  // ADDRESS FIELDS
  // ============================================================

  static const String villageField = 'village';

  static const String cityField = 'city';

  static const String districtField = 'district';

  static const String stateField = 'state';

  static const String pinCodeField = 'pincode';

  // ============================================================
  // EMERGENCY CONTACT
  // ============================================================

  static const String emergencyNameField =
      'emergencyContactName';

  static const String emergencyMobileField =
      'emergencyContactMobile';

  // ============================================================
  // GET WALKER PROFILE
  //
  // Admin / verification profile
  // ============================================================

  static Future<DocumentSnapshot<Map<String, dynamic>>>
      getWalkerProfile({
    required String authUid,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    return _firestore
        .collection(walkersCollection)
        .doc(uid)
        .get();
  }

  // ============================================================
  // GET WALKER APP PROFILE
  //
  // walkerProfiles/{UID}
  // ============================================================

  static Future<DocumentSnapshot<Map<String, dynamic>>>
      getWalkerAppProfile({
    required String authUid,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    return _firestore
        .collection(walkerProfilesCollection)
        .doc(uid)
        .get();
  }

  // ============================================================
  // CHECK PROFILE COMPLETED
  //
  // First check walkers.
  // Then fallback to walkerProfiles.
  // ============================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      return false;
    }

    final walkerDoc = await _firestore
        .collection(walkersCollection)
        .doc(uid)
        .get();

    if (walkerDoc.exists) {
      final walkerData = walkerDoc.data();

      if (walkerData?[profileCompletedField] == true) {
        return true;
      }
    }

    final profileDoc = await _firestore
        .collection(walkerProfilesCollection)
        .doc(uid)
        .get();

    if (!profileDoc.exists) {
      return false;
    }

    return profileDoc.data()?[profileCompletedField] == true;
  }

  // ============================================================
  // GET VERIFICATION STATUS
  //
  // Admin status always comes from walkers.
  // ============================================================

  static Future<String> getVerificationStatus({
    required String authUid,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      return 'not_found';
    }

    final doc = await _firestore
        .collection(walkersCollection)
        .doc(uid)
        .get();

    if (!doc.exists) {
      return 'not_found';
    }

    final value =
        doc.data()?[verificationStatusField];

    if (value == null) {
      return 'pending';
    }

    final status =
        value.toString().trim().toLowerCase();

    if (status.isEmpty) {
      return 'pending';
    }

    return status;
  }

  // ============================================================
  // CREATE WALKER ID
  // ============================================================

  static String createWalkerId(
    String authUid,
  ) {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    if (uid.length >= 8) {
      return 'WKR-${uid.substring(0, 8).toUpperCase()}';
    }

    return 'WKR-${uid.toUpperCase()}';
  }

  // ============================================================
  // UPLOAD FILE
  // ============================================================

  static Future<String> uploadFile({
    required String authUid,
    required String folder,
    required String fileName,
    required File file,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    if (!await file.exists()) {
      throw Exception(
        'Selected image does not exist.',
      );
    }

    final storageRef = _storage
        .ref()
        .child('walkers')
        .child(uid)
        .child(folder)
        .child(fileName);

    await storageRef.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
      ),
    );

    return storageRef.getDownloadURL();
  }

  // ============================================================
  // RESOLVE IMAGE
  // ============================================================

  static Future<String> resolveImage({
    required String authUid,
    required String folder,
    required String fileName,
    File? file,
    String? url,
  }) async {
    final cleanUrl = url?.trim() ?? '';

    // Existing URL
    if (cleanUrl.isNotEmpty) {
      return cleanUrl;
    }

    // Local file
    if (file != null) {
      return uploadFile(
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
  // SAVES TO:
  //
  // 1. walkers/{UID}
  //    Admin / verification data
  //
  // 2. walkerProfiles/{UID}
  //    Walker app profile data
  // ============================================================

  static Future<void> saveWalkerProfile({
    required String authUid,
    required String phoneNumber,

    // SCREEN 1
    required String name,
    required DateTime dateOfBirth,
    required String gender,

    File? selfieFile,
    String? selfieUrl,

    // SCREEN 2
    required String aadhaar,

    required String village,
    required String city,
    required String district,
    required String state,
    required String pinCode,

    File? aadhaarFrontFile,
    String? aadhaarFrontUrl,

    File? aadhaarBackFile,
    String? aadhaarBackUrl,

    // OPTIONAL
    String emergencyName = '',
    String emergencyMobile = '',

    // VERIFICATION FLAGS
    bool aadhaarVerified = false,
    bool nameMatched = false,
    bool dobMatched = false,
  }) async {
    // ==========================================================
    // CLEAN VALUES
    // ==========================================================

    final uid = authUid.trim();

    final phone = phoneNumber.trim();

    final cleanName = name.trim();

    final cleanGender = gender.trim();

    final cleanAadhaar = aadhaar.trim();

    final cleanVillage = village.trim();

    final cleanCity = city.trim();

    final cleanDistrict = district.trim();

    final cleanState = state.trim();

    final cleanPinCode = pinCode.trim();

    final cleanEmergencyName =
        emergencyName.trim();

    final cleanEmergencyMobile =
        emergencyMobile.trim();

    // ==========================================================
    // BASIC VALIDATION
    // ==========================================================

    if (uid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    if (cleanName.isEmpty) {
      throw Exception(
        'Full name is required.',
      );
    }

    // ==========================================================
    // GENDER
    // ==========================================================

    if (cleanGender != 'Male' &&
        cleanGender != 'Female') {
      throw Exception(
        'Gender must be Male or Female.',
      );
    }

    // ==========================================================
    // AADHAAR
    // ==========================================================

    if (!RegExp(r'^\d{12}$').hasMatch(
      cleanAadhaar,
    )) {
      throw Exception(
        'Aadhaar must contain exactly 12 digits.',
      );
    }

    // ==========================================================
    // ADDRESS
    // ==========================================================

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

    if (!RegExp(r'^\d{6}$').hasMatch(
      cleanPinCode,
    )) {
      throw Exception(
        'Invalid PIN code.',
      );
    }

    // ==========================================================
    // WALKERS DOCUMENT
    // ==========================================================

    final walkerRef = _firestore
        .collection(walkersCollection)
        .doc(uid);

    final existingWalker =
        await walkerRef.get();

    final existingWalkerData =
        existingWalker.data() ??
            <String, dynamic>{};

    // ==========================================================
    // WALKER ID
    // ==========================================================

    String walkerId =
        existingWalkerData[walkerIdField]
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(uid);
    }

    // ==========================================================
    // SELFIE
    // ==========================================================

    final finalSelfieUrl =
        await resolveImage(
      authUid: uid,
      folder: 'selfie',
      fileName: 'selfie.jpg',
      file: selfieFile,
      url: selfieUrl,
    );

    // ==========================================================
    // AADHAAR FRONT
    // ==========================================================

    final finalAadhaarFrontUrl =
        await resolveImage(
      authUid: uid,
      folder: 'aadhaar',
      fileName: 'front.jpg',
      file: aadhaarFrontFile,
      url: aadhaarFrontUrl,
    );

    // ==========================================================
    // AADHAAR BACK
    // ==========================================================

    final finalAadhaarBackUrl =
        await resolveImage(
      authUid: uid,
      folder: 'aadhaar',
      fileName: 'back.jpg',
      file: aadhaarBackFile,
      url: aadhaarBackUrl,
    );

    // ==========================================================
    // DATE OF BIRTH
    // ==========================================================

    final dob =
        '${dateOfBirth.year}-'
        '${dateOfBirth.month.toString().padLeft(2, '0')}-'
        '${dateOfBirth.day.toString().padLeft(2, '0')}';

    // ==========================================================
    // FULL ADDRESS
    // ==========================================================

    final fullAddress =
        '$cleanVillage, '
        '$cleanCity, '
        '$cleanDistrict, '
        '$cleanState - '
        '$cleanPinCode';

    // ==========================================================
    // EXISTING STATUS
    // ==========================================================

    final bool existingProfileCompleted =
        existingWalkerData[
                profileCompletedField] ==
            true;

    final String existingVerificationStatus =
        existingWalkerData[
                    verificationStatusField]
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    final bool shouldPreserveApprovedState =
        existingProfileCompleted ||
        existingVerificationStatus == 'approved';

    final bool finalProfileCompleted =
        shouldPreserveApprovedState
            ? existingProfileCompleted
            : true;

    final String finalVerificationStatus =
        shouldPreserveApprovedState
            ? existingVerificationStatus.isEmpty
                ? 'approved'
                : existingVerificationStatus
            : 'pending';

    // ==========================================================
    // WALKERS DATA
    //
    // ADMIN / VERIFICATION
    // ==========================================================

    final Map<String, dynamic> walkerData = {
      // Walker information
      fullNameField: cleanName,
      dateOfBirthField: dob,
      genderField: cleanGender,
      selfieField: finalSelfieUrl,

      // Aadhaar / documents
      aadhaarNumberField: cleanAadhaar,
      aadhaarFrontField: finalAadhaarFrontUrl,
      aadhaarBackField: finalAadhaarBackUrl,

      // Address
      addressField: fullAddress,
      villageField: cleanVillage,
      cityField: cleanCity,
      districtField: cleanDistrict,
      stateField: cleanState,
      pinCodeField: cleanPinCode,

      // Auth
      authUidField: uid,
      phoneNumberField: phone,
      roleField: 'walker',
      walkerIdField: walkerId,

      // Verification
      aadhaarVerifiedField: aadhaarVerified,
      nameMatchedField: nameMatched,
      dobMatchedField: dobMatched,

      profileCompletedField:
          finalProfileCompleted,

      verificationStatusField:
          finalVerificationStatus,

      verificationMessageField:
          finalVerificationStatus == 'approved'
              ? 'Profile approved.'
              : 'Documents submitted. Waiting for verification.',

      // Emergency
      emergencyNameField:
          cleanEmergencyName,

      emergencyMobileField:
          cleanEmergencyMobile,

      // Timestamp
      updatedAtField:
          FieldValue.serverTimestamp(),
    };

    if (!existingWalker.exists) {
      walkerData[createdAtField] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // WALKER PROFILES DATA
    //
    // WALKER APP PROFILE
    //
    // Aadhaar number and Aadhaar document URLs are NOT copied
    // here because this collection is for the app-facing profile.
    // ==========================================================

    final Map<String, dynamic> walkerProfileData = {
      // Identity
      authUidField: uid,
      walkerIdField: walkerId,
      roleField: 'walker',
      phoneNumberField: phone,

      // Profile
      fullNameField: cleanName,
      dateOfBirthField: dob,
      genderField: cleanGender,
      selfieField: finalSelfieUrl,

      // Address
      addressField: fullAddress,
      villageField: cleanVillage,
      cityField: cleanCity,
      districtField: cleanDistrict,
      stateField: cleanState,
      pinCodeField: cleanPinCode,

      // Profile state
      profileCompletedField:
          finalProfileCompleted,

      // Public/app-facing verification state
      verificationStatusField:
          finalVerificationStatus,

      // Emergency contact
      emergencyNameField:
          cleanEmergencyName,

      emergencyMobileField:
          cleanEmergencyMobile,

      // Timestamp
      updatedAtField:
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // CREATED AT FOR WALKER PROFILE
    // ==========================================================

    final walkerProfileRef = _firestore
        .collection(walkerProfilesCollection)
        .doc(uid);

    final existingWalkerProfile =
        await walkerProfileRef.get();

    if (!existingWalkerProfile.exists) {
      walkerProfileData[createdAtField] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // ATOMIC WRITE
    //
    // BOTH DOCUMENTS ARE WRITTEN TOGETHER.
    //
    // If one write fails, the batch does not partially commit.
    // ==========================================================

    final batch = _firestore.batch();

    batch.set(
      walkerRef,
      walkerData,
      SetOptions(merge: true),
    );

    batch.set(
      walkerProfileRef,
      walkerProfileData,
      SetOptions(merge: true),
    );

    await batch.commit();

    // ==========================================================
    // LOG
    // ==========================================================

    developer.log(
      'Walker profile saved successfully | '
      'walkers/$uid | '
      'walkerProfiles/$uid | '
      'walkerId=$walkerId | '
      'status=$finalVerificationStatus | '
      'completed=$finalProfileCompleted',
      name: 'ProfileSetupService',
    );
  }
}
