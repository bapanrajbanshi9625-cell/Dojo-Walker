// File: lib/services/profile_setup_service.dart

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
  // COLLECTION
  // ============================================================

  static const String walkersCollection = 'walkers';

  // ============================================================
  // FIELDS
  // ============================================================

  static const String userIdField = 'userId';
  static const String walkerIdField = 'walkerId';

  static const String nameField = 'name';
  static const String phoneField = 'phone';
  static const String dateOfBirthField = 'dateOfBirth';

  static const String addressField = 'address';
  static const String pinCodeField = 'pinCode';

  static const String profileImageField = 'profileImage';

  // ============================================================
  // AADHAAR
  // ============================================================

  static const String aadhaarNumberField = 'aadhaarNumber';
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

  static const String panNumberField = 'panNumber';

  static const String panCardUrlField =
      'panCardUrl';

  static const String panVerifiedField =
      'panVerified';

  // ============================================================
  // SELFIE
  // ============================================================

  static const String selfieUrlField =
      'selfieUrl';

  static const String selfieVerifiedField =
      'selfieVerified';

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
  // TIMESTAMPS
  // ============================================================

  static const String createdAtField =
      'createdAt';

  static const String updatedAtField =
      'updatedAt';

  // ============================================================
  // GET WALKER
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
  // PROFILE COMPLETED
  // ============================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      return false;
    }

    final snapshot = await _firestore
        .collection(walkersCollection)
        .doc(uid)
        .get();

    if (!snapshot.exists) {
      return false;
    }

    return snapshot.data()?[
            profileCompletedField] ==
        true;
  }

  // ============================================================
  // VERIFICATION STATUS
  // ============================================================

  static Future<String> getVerificationStatus({
    required String authUid,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      return 'not_found';
    }

    final snapshot = await _firestore
        .collection(walkersCollection)
        .doc(uid)
        .get();

    if (!snapshot.exists) {
      return 'not_found';
    }

    final value = snapshot.data()?[
        verificationStatusField];

    if (value == null) {
      return 'pending';
    }

    final status =
        value.toString().trim().toLowerCase();

    return status.isEmpty
        ? 'pending'
        : status;
  }

  // ============================================================
  // APPROVAL STATUS
  // ============================================================

  static Future<String> getApprovalStatus({
    required String authUid,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      return 'not_found';
    }

    final snapshot = await _firestore
        .collection(walkersCollection)
        .doc(uid)
        .get();

    if (!snapshot.exists) {
      return 'not_found';
    }

    final value = snapshot.data()?[
        approvalStatusField];

    if (value == null) {
      return 'pending';
    }

    final status =
        value.toString().trim().toLowerCase();

    return status.isEmpty
        ? 'pending'
        : status;
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
  // UPLOAD IMAGE
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

    if (cleanUrl.isNotEmpty) {
      return cleanUrl;
    }

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
  // ============================================================

  static Future<void> saveWalkerProfile({
    required String authUid,
    required String phone,

    // ----------------------------------------------------------
    // BASIC PROFILE
    // ----------------------------------------------------------

    required String name,
    required DateTime dateOfBirth,

    required String address,
    required String pinCode,

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
  }) async {
    // ==========================================================
    // CLEAN VALUES
    // ==========================================================

    final uid = authUid.trim();
    final cleanPhone = phone.trim();
    final cleanName = name.trim();
    final cleanAddress = address.trim();
    final cleanPinCode = pinCode.trim();
    final cleanAadhaar = aadhaarNumber.trim();
    final cleanPan = panNumber.trim().toUpperCase();

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

    if (cleanAddress.isEmpty) {
      throw Exception(
        'Address is required.',
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
    // AADHAAR VALIDATION
    // ==========================================================

    if (!RegExp(r'^\d{12}$').hasMatch(
      cleanAadhaar,
    )) {
      throw Exception(
        'Aadhaar must contain exactly 12 digits.',
      );
    }

    // ==========================================================
    // PAN VALIDATION
    // ==========================================================

    if (!RegExp(
      r'^[A-Z]{5}[0-9]{4}[A-Z]$',
    ).hasMatch(cleanPan)) {
      throw Exception(
        'Invalid PAN number.',
      );
    }

    // ==========================================================
    // WALKER DOCUMENT
    // ==========================================================

    final walkerRef = _firestore
        .collection(walkersCollection)
        .doc(uid);

    final existingSnapshot =
        await walkerRef.get();

    final existingData =
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
    // PROFILE IMAGE
    // ==========================================================

    String finalProfileImage = '';

    if (profileImageUrl != null &&
        profileImageUrl.trim().isNotEmpty) {
      finalProfileImage =
          profileImageUrl.trim();
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
    // PAN CARD
    // ==========================================================

    final finalPanCardUrl =
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

    final dob =
        '${dateOfBirth.year}-'
        '${dateOfBirth.month.toString().padLeft(2, '0')}-'
        '${dateOfBirth.day.toString().padLeft(2, '0')}';

    // ==========================================================
    // IMPORTANT
    //
    // PROFILE SUBMISSION DOES NOT APPROVE WALKER.
    //
    // Admin approval remains pending.
    // ==========================================================

    final Map<String, dynamic> walkerData = {
      // --------------------------------------------------------
      // IDENTITY
      // --------------------------------------------------------

      userIdField: uid,
      walkerIdField: walkerId,

      nameField: cleanName,
      phoneField: cleanPhone,
      dateOfBirthField: dob,

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      addressField: cleanAddress,
      pinCodeField: cleanPinCode,

      // --------------------------------------------------------
      // PROFILE
      // --------------------------------------------------------

      profileImageField: finalProfileImage,

      // --------------------------------------------------------
      // AADHAAR
      // --------------------------------------------------------

      aadhaarNumberField: cleanAadhaar,
      aadhaarFrontUrlField:
          finalAadhaarFrontUrl,
      aadhaarBackUrlField:
          finalAadhaarBackUrl,

      aadhaarFrontVerifiedField: false,
      aadhaarBackVerifiedField: false,

      // --------------------------------------------------------
      // PAN
      // --------------------------------------------------------

      panNumberField: cleanPan,
      panCardUrlField: finalPanCardUrl,
      panVerifiedField: false,

      // --------------------------------------------------------
      // SELFIE
      // --------------------------------------------------------

      selfieUrlField: finalSelfieUrl,
      selfieVerifiedField: false,

      // --------------------------------------------------------
      // PROFILE STATE
      // --------------------------------------------------------

      profileCompletedField: true,

      // --------------------------------------------------------
      // VERIFICATION
      // --------------------------------------------------------

      verificationStatusField: 'pending',
      verifiedAtField: null,

      // --------------------------------------------------------
      // ADMIN APPROVAL
      // --------------------------------------------------------

      approvalStatusField: 'pending',

      adminApprovedField: false,
      adminRejectedField: false,

      approvedField: false,
      isApprovedField: false,

      approvedAtField: null,

      rejectedField: false,
      rejectedAtField: null,

      // --------------------------------------------------------
      // WALKER STATE
      // --------------------------------------------------------

      activeField: false,
      isActiveField: false,
      isAvailableField: false,
      isOnlineField: false,

      statusField: 'pending',

      // --------------------------------------------------------
      // TIMESTAMP
      // --------------------------------------------------------

      updatedAtField:
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
    // WRITE
    // ==========================================================

    await walkerRef.set(
      walkerData,
      SetOptions(merge: true),
    );

    // ==========================================================
    // LOG
    // ==========================================================

    developer.log(
      'Walker profile submitted | '
      'walkerId=$walkerId | '
      'uid=$uid | '
      'verification=pending | '
      'approval=pending',
      name: 'ProfileSetupService',
    );
  }
}
