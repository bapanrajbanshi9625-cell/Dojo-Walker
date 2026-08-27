// File:
// lib/features/profile_setup/services/profile_setup_service.dart

import 'dart:developer' as developer;
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'profile_setup_service_helpers.dart';

class ProfileSetupService {
  ProfileSetupService._();

  // ============================================================
  // FIREBASE
  // ============================================================

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  static const String walkersCollection = 'walkers';

  // ============================================================
  // IDENTITY
  // ============================================================

  static const String userIdField = 'userId';
  static const String authUidField = 'authUid';
  static const String uidField = 'uid';

  static const String walkerIdField = 'walkerId';
  static const String roleField = 'role';

  // ============================================================
  // BASIC PROFILE
  // ============================================================

  static const String nameField = 'name';
  static const String fullNameField = 'fullName';

  static const String phoneField = 'phone';
  static const String phoneNumberField = 'phoneNumber';

  static const String dateOfBirthField = 'dateOfBirth';
  static const String genderField = 'gender';

  // ============================================================
  // ADDRESS
  // ============================================================

  static const String addressField = 'address';
  static const String pinCodeField = 'pinCode';

  static const String villageField = 'village';
  static const String cityField = 'city';
  static const String districtField = 'district';
  static const String stateField = 'state';

  // ============================================================
  // PROFILE IMAGE
  // ============================================================

  static const String profileImageField = 'profileImage';

  static const String profileImageUrlField =
      'profileImageUrl';

  // ============================================================
  // SELFIE
  // ============================================================

  static const String selfieField = 'selfie';

  static const String selfieUrlField = 'selfieUrl';

  static const String selfieVerifiedField =
      'selfieVerified';

  // ============================================================
  // AADHAAR
  // ============================================================

  static const String aadhaarNumberField =
      'aadhaarNumber';

  static const String aadhaarFrontUrlField =
      'aadhaarFrontUrl';

  static const String aadhaarBackUrlField =
      'aadhaarBackUrl';

  static const String aadhaarFrontVerifiedField =
      'aadhaarFrontVerified';

  static const String aadhaarBackVerifiedField =
      'aadhaarBackVerified';

  // ============================================================
  // PAN
  // ============================================================

  static const String panNumberField =
      'panNumber';

  static const String panCardUrlField =
      'panCardUrl';

  static const String panVerifiedField =
      'panVerified';

  // ============================================================
  // VERIFICATION
  // ============================================================

  static const String verificationStatusField =
      'verificationStatus';

  static const String verifiedAtField =
      'verifiedAt';

  // ============================================================
  // ADMIN APPROVAL
  // ============================================================

  static const String approvalStatusField =
      'approvalStatus';

  static const String adminApprovedField =
      'adminApproved';

  static const String adminRejectedField =
      'adminRejected';

  static const String approvedField =
      'approved';

  static const String isApprovedField =
      'isApproved';

  static const String approvedAtField =
      'approvedAt';

  static const String rejectedField =
      'rejected';

  static const String rejectedAtField =
      'rejectedAt';

  // ============================================================
  // WALKER STATE
  // ============================================================

  static const String activeField = 'active';
  static const String isActiveField = 'isActive';
  static const String isAvailableField = 'isAvailable';
  static const String isOnlineField = 'isOnline';

  static const String statusField = 'status';

  static const String profileCompletedField =
      'profileCompleted';

  // ============================================================
  // EMERGENCY
  // ============================================================

  static const String emergencyContactNameField =
      'emergencyContactName';

  static const String emergencyContactMobileField =
      'emergencyContactMobile';

  // ============================================================
  // TIMESTAMPS
  // ============================================================

  static const String createdAtField = 'createdAt';
  static const String updatedAtField = 'updatedAt';
  static const String submittedAtField = 'submittedAt';

  // ============================================================
  // GET WALKER PROFILE
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>>
      getWalkerProfile({
    required String authUid,
  }) async {
    final String uid = authUid.trim();

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
  // CHECK PROFILE COMPLETED
  // ============================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final String uid = authUid.trim();

    if (uid.isEmpty) {
      return false;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection(walkersCollection)
            .doc(uid)
            .get();

    if (!snapshot.exists) {
      return false;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    return data[profileCompletedField] == true;
  }

  // ============================================================
  // GET VERIFICATION STATUS
  // ============================================================

  static Future<String> getVerificationStatus({
    required String authUid,
  }) async {
    final String uid = authUid.trim();

    if (uid.isEmpty) {
      return 'not_found';
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection(walkersCollection)
            .doc(uid)
            .get();

    if (!snapshot.exists) {
      return 'not_found';
    }

    final dynamic value =
        snapshot.data()?[verificationStatusField];

    if (value == null) {
      return 'pending';
    }

    final String status =
        value.toString().trim().toLowerCase();

    return status.isEmpty ? 'pending' : status;
  }

  // ============================================================
  // GET APPROVAL STATUS
  // ============================================================

  static Future<String> getApprovalStatus({
    required String authUid,
  }) async {
    final String uid = authUid.trim();

    if (uid.isEmpty) {
      return 'not_found';
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection(walkersCollection)
            .doc(uid)
            .get();

    if (!snapshot.exists) {
      return 'not_found';
    }

    final dynamic value =
        snapshot.data()?[approvalStatusField];

    if (value == null) {
      return 'pending';
    }

    final String status =
        value.toString().trim().toLowerCase();

    return status.isEmpty ? 'pending' : status;
  }

  // ============================================================
  // CREATE WALKER ID
  // ============================================================

  static String createWalkerId(
    String authUid,
  ) {
    return ProfileSetupServiceHelpers.createWalkerId(
      authUid,
    );
  }

  // ============================================================
  // URL VALIDATION
  // ============================================================

  static bool isValidUrl(
    String value,
  ) {
    return ProfileSetupServiceHelpers.isValidUrl(
      value,
    );
  }

  // ============================================================
  // UPLOAD FILE
  // ============================================================

  static Future<String> uploadFile({
    required String authUid,
    required String folder,
    required String fileName,
    required File file,
  }) {
    return ProfileSetupServiceHelpers.uploadFile(
      authUid: authUid,
      folder: folder,
      fileName: fileName,
      file: file,
    );
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
  }) {
    return ProfileSetupServiceHelpers.resolveImage(
      authUid: authUid,
      folder: folder,
      fileName: fileName,
      file: file,
      url: url,
    );
  }

  // ============================================================
  // SAVE WALKER PROFILE
  // ============================================================

  static Future<void> saveWalkerProfile({
    required String authUid,
    required String phone,

    // ----------------------------------------------------------
    // BASIC
    // ----------------------------------------------------------

    required String name,
    required DateTime dateOfBirth,

    required String address,
    required String pinCode,

    String? gender,

    String? profileImageUrl,

    // ----------------------------------------------------------
    // AADHAAR
    // ----------------------------------------------------------

    required String aadhaarNumber,

    File? aadhaarFrontFile,
    String? aadhaarFrontUrl,

    File? aadhaarBackFile,
    String? aadhaarBackUrl,

    // ----------------------------------------------------------
    // PAN
    // ----------------------------------------------------------

    required String panNumber,

    File? panCardFile,
    String? panCardUrl,

    // ----------------------------------------------------------
    // SELFIE
    // ----------------------------------------------------------

    File? selfieFile,
    String? selfieUrl,

    // ----------------------------------------------------------
    // EMERGENCY
    // ----------------------------------------------------------

    String? emergencyContactName,
    String? emergencyContactMobile,
  }) async {
    // ==========================================================
    // CLEAN VALUES
    // ==========================================================

    final String uid = authUid.trim();

    final String cleanPhone = phone.trim();

    final String cleanName = name.trim();

    final String cleanAddress = address.trim();

    final String cleanPinCode = pinCode.trim();

    final String cleanAadhaar =
        aadhaarNumber.trim();

    final String cleanPan =
        panNumber.trim().toUpperCase();

    final String cleanGender =
        gender?.trim() ?? '';

    final String cleanEmergencyName =
        emergencyContactName?.trim() ?? '';

    final String cleanEmergencyMobile =
        emergencyContactMobile?.trim() ?? '';

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
        'Name is required.',
      );
    }

    if (cleanPhone.isEmpty) {
      throw Exception(
        'Phone number is required.',
      );
    }

    if (dateOfBirth.isAfter(DateTime.now())) {
      throw Exception(
        'Invalid date of birth.',
      );
    }

    if (cleanAddress.isEmpty) {
      throw Exception(
        'Address is required.',
      );
    }

    if (!ProfileSetupServiceHelpers.isValidPin(
      cleanPinCode,
    )) {
      throw Exception(
        'Invalid PIN code.',
      );
    }

    // ==========================================================
    // GENDER
    // ==========================================================

    if (cleanGender.isNotEmpty &&
        cleanGender != 'Male' &&
        cleanGender != 'Female') {
      throw Exception(
        'Invalid gender.',
      );
    }

    // ==========================================================
    // AADHAAR
    // ==========================================================

    if (!ProfileSetupServiceHelpers.isValidAadhaar(
      cleanAadhaar,
    )) {
      throw Exception(
        'Aadhaar must contain exactly 12 digits.',
      );
    }

    // ==========================================================
    // PAN
    // ==========================================================

    if (!ProfileSetupServiceHelpers.isValidPan(
      cleanPan,
    )) {
      throw Exception(
        'Invalid PAN number.',
      );
    }

    // ==========================================================
    // EMERGENCY
    // ==========================================================

    if (cleanEmergencyName.isNotEmpty ||
        cleanEmergencyMobile.isNotEmpty) {
      if (cleanEmergencyName.isEmpty) {
        throw Exception(
          'Emergency contact name is required.',
        );
      }

      if (!ProfileSetupServiceHelpers.isValidMobile(
        cleanEmergencyMobile,
      )) {
        throw Exception(
          'Invalid emergency mobile number.',
        );
      }
    }

    // ==========================================================
    // WALKER REFERENCE
    // ==========================================================

    final DocumentReference<
            Map<String, dynamic>>
        walkerRef =
        _firestore
            .collection(walkersCollection)
            .doc(uid);

    // ==========================================================
    // EXISTING PROFILE
    // ==========================================================

    final DocumentSnapshot<
            Map<String, dynamic>>
        existingSnapshot =
        await walkerRef.get();

    final Map<String, dynamic> existingData =
        existingSnapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // WALKER BUSINESS ID
    // ==========================================================

    String walkerId =
        existingData[walkerIdField]
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(uid);
    }

    // ==========================================================
    // SELFIE
    // ==========================================================

    final String finalSelfieUrl =
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

    final String finalAadhaarFrontUrl =
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

    final String finalAadhaarBackUrl =
        await resolveImage(
      authUid: uid,
      folder: 'aadhaar',
      fileName: 'back.jpg',
      file: aadhaarBackFile,
      url: aadhaarBackUrl,
    );

    // ==========================================================
    // PAN CARD
    // ==========================================================

    final String finalPanCardUrl =
        await resolveImage(
      authUid: uid,
      folder: 'pan',
      fileName: 'pan.jpg',
      file: panCardFile,
      url: panCardUrl,
    );

    // ==========================================================
    // DATE
    // ==========================================================

    final String dob =
        ProfileSetupServiceHelpers.formatDateOfBirth(
      dateOfBirth,
    );

    // ==========================================================
    // PROFILE IMAGE
    // ==========================================================

    String finalProfileImage =
        profileImageUrl?.trim() ?? '';

    if (finalProfileImage.isEmpty) {
      finalProfileImage = finalSelfieUrl;
    }

    // ==========================================================
    // WALKER DATA
    // ==========================================================

    final Map<String, dynamic> walkerData =
        <String, dynamic>{
      // --------------------------------------------------------
      // IDENTITY
      // --------------------------------------------------------

      userIdField: uid,
      authUidField: uid,
      uidField: uid,

      walkerIdField: walkerId,

      roleField: 'walker',

      'Walker Uid': uid,
      'walkerUid': uid,
      'Walker ID': walkerId,

      // --------------------------------------------------------
      // BASIC
      // --------------------------------------------------------

      nameField: cleanName,
      fullNameField: cleanName,

      'Full Name': cleanName,

      phoneField: cleanPhone,
      phoneNumberField: cleanPhone,

      'Mobile number': cleanPhone,
      'mobileNumber': cleanPhone,

      dateOfBirthField: dob,
      'dateofbirth': dob,
      'Date Of Birth': dob,

      // --------------------------------------------------------
      // GENDER
      // --------------------------------------------------------

      if (cleanGender.isNotEmpty)
        genderField: cleanGender,

      if (cleanGender.isNotEmpty)
        'Gender': cleanGender,

      // --------------------------------------------------------
      // PROFILE IMAGE
      // --------------------------------------------------------

      profileImageField: finalProfileImage,

      profileImageUrlField: finalProfileImage,

      // --------------------------------------------------------
      // SELFIE
      // --------------------------------------------------------

      selfieField: finalSelfieUrl,

      selfieUrlField: finalSelfieUrl,

      'Profile Selfie': finalSelfieUrl,
      'profileSelfie': finalSelfieUrl,

      selfieVerifiedField: false,

      // --------------------------------------------------------
      // AADHAAR
      // --------------------------------------------------------

      aadhaarNumberField: cleanAadhaar,

      'Aadhar Number': cleanAadhaar,
      'Aadhaar Number': cleanAadhaar,

      aadhaarFrontUrlField:
          finalAadhaarFrontUrl,

      aadhaarBackUrlField:
          finalAadhaarBackUrl,

      'aadhaarfront':
          finalAadhaarFrontUrl,

      'aadhaarFront':
          finalAadhaarFrontUrl,

      'aadhaar_front':
          finalAadhaarFrontUrl,

      'Aadhaar Front':
          finalAadhaarFrontUrl,

      'aadhaarback':
          finalAadhaarBackUrl,

      'aadhaarBack':
          finalAadhaarBackUrl,

      'aadhaar_back':
          finalAadhaarBackUrl,

      'Aadhaar Back':
          finalAadhaarBackUrl,

      'aadhaar_front_uploaded':
          true,

      'aadhaarFrontUploaded':
          true,

      'aadhaar_back_uploaded':
          true,

      'aadhaarBackUploaded':
          true,

      aadhaarFrontVerifiedField:
          false,

      aadhaarBackVerifiedField:
          false,

      // --------------------------------------------------------
      // PAN
      // --------------------------------------------------------

      panNumberField: cleanPan,

      panCardUrlField:
          finalPanCardUrl,

      'panCard':
          finalPanCardUrl,

      'pan_card':
          finalPanCardUrl,

      'pan_card_url':
          finalPanCardUrl,

      'PAN Card':
          finalPanCardUrl,

      'PAN Card URL':
          finalPanCardUrl,

      'pan_card_uploaded':
          true,

      'panCardUploaded':
          true,

      panVerifiedField:
          false,

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      addressField: cleanAddress,

      pinCodeField: cleanPinCode,

      'Adress': cleanAddress,
      'Address': cleanAddress,

      'Pincode': cleanPinCode,
      'pincode': cleanPinCode,
      'pinCode': cleanPinCode,

      // --------------------------------------------------------
      // EMERGENCY
      // --------------------------------------------------------

      emergencyContactNameField:
          cleanEmergencyName,

      emergencyContactMobileField:
          cleanEmergencyMobile,

      // --------------------------------------------------------
      // PROFILE COMPLETED
      // --------------------------------------------------------

      profileCompletedField: true,

      'profile_completed': true,
      'isProfileCompleted': true,

      // --------------------------------------------------------
      // VERIFICATION
      // --------------------------------------------------------

      verificationStatusField:
          'pending',

      verifiedAtField: null,

      // --------------------------------------------------------
      // ADMIN APPROVAL
      // --------------------------------------------------------

      approvalStatusField:
          'pending',

      adminApprovedField:
          false,

      adminRejectedField:
          false,

      approvedField:
          false,

      isApprovedField:
          false,

      approvedAtField:
          null,

      rejectedField:
          false,

      rejectedAtField:
          null,

      // --------------------------------------------------------
      // WALKER STATE
      // --------------------------------------------------------

      activeField:
          false,

      isActiveField:
          false,

      isAvailableField:
          false,

      isOnlineField:
          false,

      statusField:
          'pending',

      // --------------------------------------------------------
      // TIMESTAMPS
      // --------------------------------------------------------

      updatedAtField:
          FieldValue.serverTimestamp(),

      submittedAtField:
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // CREATED AT
    // ==========================================================

    if (!existingSnapshot.exists) {
      walkerData[createdAtField] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // FIRESTORE WRITE
    // ==========================================================

    await walkerRef.set(
      walkerData,
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // LOG
    // ==========================================================

    developer.log(
      'Walker profile submitted | '
      'uid=$uid | '
      'walkerId=$walkerId | '
      'profileCompleted=true | '
      'verification=pending | '
      'approval=pending',
      name: 'ProfileSetupService',
    );
  }
}
