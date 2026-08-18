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

    final String fullName =
        data['fullName']?.toString().trim() ?? '';

    final String phoneNumber =
        data['phoneNumber']?.toString().trim() ?? '';

    final String dateOfBirth =
        data['dateofbirth']?.toString().trim() ?? '';

    final String village =
        data['village']?.toString().trim() ?? '';

    final String city =
        data['city']?.toString().trim() ?? '';

    final String district =
        data['district']?.toString().trim() ?? '';

    final String state =
        data['state']?.toString().trim() ?? '';

    final String pinCode =
        data['pincode']?.toString().trim() ?? '';

    final String aadhaarNumber =
        data['aadhaarNumber']?.toString().trim() ?? '';

    final String selfie =
        data['selfie']?.toString().trim() ?? '';

    final String aadhaarFront =
        data['aadharfront']?.toString().trim() ?? '';

    final String aadhaarBack =
        data['aadharback']?.toString().trim() ?? '';

    final bool aadhaarVerified =
        data['aadhaarVerified'] == true;

    final bool nameMatched =
        data['nameMatched'] == true;

    final bool dobMatched =
        data['dobMatched'] == true;

    return profileCompleted &&
        walkerId.isNotEmpty &&
        fullName.isNotEmpty &&
        phoneNumber.isNotEmpty &&
        dateOfBirth.isNotEmpty &&
        village.isNotEmpty &&
        city.isNotEmpty &&
        district.isNotEmpty &&
        state.isNotEmpty &&
        pinCode.isNotEmpty &&
        aadhaarNumber.isNotEmpty &&
        selfie.isNotEmpty &&
        aadhaarFront.isNotEmpty &&
        aadhaarBack.isNotEmpty &&
        aadhaarVerified &&
        nameMatched &&
        dobMatched;
  }

  // ============================================================
  // CREATE WALKER ID
  // ============================================================

  static String createWalkerId(
    String authUid,
  ) {
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
  // UPLOAD LOCAL FILE TO FIREBASE STORAGE
  // ============================================================

  static Future<String> _uploadFile({
    required String authUid,
    required String folder,
    required String fileName,
    required File file,
  }) async {
    if (!await file.exists()) {
      throw Exception('File does not exist.');
    }

    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      throw Exception('Authentication UID is missing.');
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
  // Existing URL -> use URL directly
  // Local File   -> upload to Firebase Storage
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
    // CLEAN DATA
    // ==========================================================

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

    // ==========================================================
    // BASIC VALIDATION
    // ==========================================================

    if (cleanUid.isEmpty) {
      throw Exception('Authentication UID is missing.');
    }

    if (cleanName.isEmpty) {
      throw Exception('Full name is required.');
    }

    if (cleanPhone.isEmpty) {
      throw Exception('Phone number is required.');
    }

    if (!RegExp(r'^\d{12}$').hasMatch(cleanAadhaar)) {
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
      throw Exception('District is required.');
    }

    if (cleanState.isEmpty) {
      throw Exception('State is required.');
    }

    if (!RegExp(r'^\d{6}$').hasMatch(cleanPinCode)) {
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
    // PROFILE REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>> profileRef =
        _firestore
            .collection(_collection)
            .doc(cleanUid);

    // ==========================================================
    // GET EXISTING PROFILE
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>> existing =
        await profileRef.get();

    String walkerId =
        existing.data()?['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(cleanUid);
    }

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
    // SELFIE
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
    // FULL ADDRESS
    // ==========================================================

    final String fullAddress =
        '$cleanVillage, '
        '$cleanCity, '
        '$cleanDistrict, '
        '$cleanState - '
        '$cleanPinCode';

    // ==========================================================
    // FIRESTORE PROFILE DATA
    // ==========================================================

    final Map<String, dynamic> profileData =
        <String, dynamic>{
      // --------------------------------------------------------
      // IDENTITY
      // --------------------------------------------------------

      'authUid': cleanUid,
      'walkerId': walkerId,
      'role': 'walker',

      // --------------------------------------------------------
      // PERSONAL
      // --------------------------------------------------------

      'fullName': cleanName,
      'phoneNumber': cleanPhone,
      'dateofbirth': formattedDate,

      // --------------------------------------------------------
      // ADDRESS
      // --------------------------------------------------------

      'village': cleanVillage,
      'city': cleanCity,
      'district': cleanDistrict,
      'state': cleanState,
      'pincode': cleanPinCode,
      'address': fullAddress,

      // --------------------------------------------------------
      // AADHAAR
      // --------------------------------------------------------

      'aadhaarNumber': cleanAadhaar,
      'aadharfront': finalFrontUrl,
      'aadharback': finalBackUrl,

      // --------------------------------------------------------
      // SELFIE
      // --------------------------------------------------------

      'selfie': finalSelfieUrl,

      // --------------------------------------------------------
      // AADHAAR VERIFICATION
      // --------------------------------------------------------

      'aadhaarVerified': aadhaarVerified,
      'nameMatched': nameMatched,
      'dobMatched': dobMatched,
      'aadhaarVerifiedName': cleanVerifiedName,

      // --------------------------------------------------------
      // PROFILE STATUS
      // --------------------------------------------------------

      'profileCompleted': true,

      // --------------------------------------------------------
      // TIMESTAMP
      // --------------------------------------------------------

      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // CREATED AT
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
