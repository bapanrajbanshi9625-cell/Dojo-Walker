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

  static const String collection = 'walkers';

  // ============================================================
  // EXACT FIRESTORE FIELDS
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
  static const String profileCompletedField = 'profileCompleted';

  static const String roleField = 'role';
  static const String selfieField = 'selfie';
  static const String updatedAtField = 'updatedAt';
  static const String walkerIdField = 'walkerId';

  static const String verificationStatusField =
      'verificationStatus';

  static const String verificationMessageField =
      'verificationMessage';

  // Optional address details
  static const String villageField = 'village';
  static const String cityField = 'city';
  static const String districtField = 'district';
  static const String stateField = 'state';
  static const String pinCodeField = 'pincode';

  // Emergency
  static const String emergencyNameField =
      'emergencyContactName';

  static const String emergencyMobileField =
      'emergencyContactMobile';

  // ============================================================
  // GET PROFILE
  // ============================================================

  static Future<DocumentSnapshot<Map<String, dynamic>>>
      getWalkerProfile({
    required String authUid,
  }) {
    return _firestore
        .collection(collection)
        .doc(authUid.trim())
        .get();
  }

  // ============================================================
  // PROFILE COMPLETED
  // ============================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) return false;

    final doc = await _firestore
        .collection(collection)
        .doc(uid)
        .get();

    if (!doc.exists) return false;

    return doc.data()?[profileCompletedField] == true;
  }

  // ============================================================
  // VERIFICATION STATUS
  // ============================================================

  static Future<String> getVerificationStatus({
    required String authUid,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) return 'not_found';

    final doc = await _firestore
        .collection(collection)
        .doc(uid)
        .get();

    if (!doc.exists) return 'not_found';

    final value =
        doc.data()?[verificationStatusField];

    if (value == null ||
        value.toString().trim().isEmpty) {
      return 'pending';
    }

    return value.toString().trim().toLowerCase();
  }

  // ============================================================
  // WALKER ID
  // ============================================================

  static String createWalkerId(String authUid) {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      throw Exception('Authentication UID is missing.');
    }

    if (uid.length >= 8) {
      return 'WKR-${uid.substring(0, 8).toUpperCase()}';
    }

    return 'WKR-${uid.toUpperCase()}';
  }

  // ============================================================
  // UPLOAD FILE -> URL
  // ============================================================

  static Future<String> uploadFile({
    required String authUid,
    required String folder,
    required String fileName,
    required File file,
  }) async {
    final uid = authUid.trim();

    if (uid.isEmpty) {
      throw Exception('Authentication UID is missing.');
    }

    if (!await file.exists()) {
      throw Exception('Selected image does not exist.');
    }

    final ref = _storage
        .ref()
        .child('walkers')
        .child(uid)
        .child(folder)
        .child(fileName);

    await ref.putFile(
      file,
      SettableMetadata(
        contentType: 'image/jpeg',
      ),
    );

    return ref.getDownloadURL();
  }

  // ============================================================
  // CAMERA OR URL
  //
  // URL -> SAME URL
  // FILE -> UPLOAD -> DOWNLOAD URL
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
    required String phoneNumber,
    required String name,
    required DateTime dateOfBirth,
    required String gender,
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

    String emergencyName = '',
    String emergencyMobile = '',

    bool aadhaarVerified = false,
    bool nameMatched = false,
    bool dobMatched = false,
  }) async {
    final uid = authUid.trim();
    final phone = phoneNumber.trim();
    final cleanName = name.trim();
    final cleanGender = gender.trim();
    final cleanAadhaar = aadhaar.trim();

    if (uid.isEmpty) {
      throw Exception('Authentication UID is missing.');
    }

    if (cleanName.isEmpty) {
      throw Exception('Full name is required.');
    }

    if (cleanGender != 'Male' &&
        cleanGender != 'Female') {
      throw Exception('Gender must be Male or Female.');
    }

    if (!RegExp(r'^\d{12}$').hasMatch(cleanAadhaar)) {
      throw Exception(
        'Aadhaar must contain exactly 12 digits.',
      );
    }

    if (!RegExp(r'^\d{6}$').hasMatch(pinCode.trim())) {
      throw Exception('Invalid PIN code.');
    }

    // ==========================================================
    // IMAGE URLS
    // ==========================================================

    final finalSelfieUrl = await resolveImage(
      authUid: uid,
      folder: 'selfie',
      fileName: 'selfie.jpg',
      file: selfieFile,
      url: selfieUrl,
    );

    final finalAadhaarFrontUrl = await resolveImage(
      authUid: uid,
      folder: 'aadhaar',
      fileName: 'front.jpg',
      file: aadhaarFrontFile,
      url: aadhaarFrontUrl,
    );

    final finalAadhaarBackUrl = await resolveImage(
      authUid: uid,
      folder: 'aadhaar',
      fileName: 'back.jpg',
      file: aadhaarBackFile,
      url: aadhaarBackUrl,
    );

    // ==========================================================
    // WALKER ID
    // ==========================================================

    final ref = _firestore
        .collection(collection)
        .doc(uid);

    final existing = await ref.get();

    final existingData =
        existing.data() ?? <String, dynamic>{};

    String walkerId =
        existingData[walkerIdField]?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(uid);
    }

    // ==========================================================
    // DATE
    // ==========================================================

    final dob =
        '${dateOfBirth.year}-'
        '${dateOfBirth.month.toString().padLeft(2, '0')}-'
        '${dateOfBirth.day.toString().padLeft(2, '0')}';

    // ==========================================================
    // ADDRESS
    // ==========================================================

    final fullAddress =
        '${village.trim()}, '
        '${city.trim()}, '
        '${district.trim()}, '
        '${state.trim()} - '
        '${pinCode.trim()}';

    // ==========================================================
    // IMPORTANT
    //
    // Initial submission DOES NOT approve profile.
    // Admin / verification system will update these later.
    // ==========================================================

    final data = <String, dynamic>{
      aadhaarNumberField: cleanAadhaar,

      aadhaarVerifiedField: aadhaarVerified,

      aadhaarBackField: finalAadhaarBackUrl,

      aadhaarFrontField: finalAadhaarFrontUrl,

      addressField: fullAddress,

      authUidField: uid,

      dateOfBirthField: dob,

      dobMatchedField: dobMatched,

      fullNameField: cleanName,

      genderField: cleanGender,

      nameMatchedField: nameMatched,

      phoneNumberField: phone,

      profileCompletedField:
          false,

      roleField: 'walker',

      selfieField: finalSelfieUrl,

      walkerIdField: walkerId,

      verificationStatusField:
          'pending',

      verificationMessageField:
          'Documents submitted. Waiting for verification.',

      villageField:
          village.trim(),

      cityField:
          city.trim(),

      districtField:
          district.trim(),

      stateField:
          state.trim(),

      pinCodeField:
          pinCode.trim(),

      emergencyNameField:
          emergencyName.trim(),

      emergencyMobileField:
          emergencyMobile.trim(),

      updatedAtField:
          FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      data[createdAtField] =
          FieldValue.serverTimestamp();
    }

    await ref.set(
      data,
      SetOptions(merge: true),
    );

    developer.log(
      'Walker profile submitted: '
      'uid=$uid '
      'walkerId=$walkerId',
      name: 'ProfileSetupService',
    );
  }
}
