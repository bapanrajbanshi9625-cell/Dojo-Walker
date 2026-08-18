// File location:
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
  //
  // walkerProfiles/{Firebase Auth UID}
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
  // ADDRESS COMPONENTS
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
  // AADHAAR
  // ============================================================

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
  //
  // Splash / startup flow can use this method.
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
        document.data() ?? <String, dynamic>{};

    // ----------------------------------------------------------
    // PROFILE COMPLETED
    // ----------------------------------------------------------

    if (data[_profileCompletedField] != true) {
      return false;
    }

    // ----------------------------------------------------------
    // REQUIRED MAIN FIELDS
    // ----------------------------------------------------------

    final String walkerUid =
        _stringValue(
      data[_walkerUidField],
    );

    final String fullName =
        _stringValue(
      data[_fullNameField],
    );

    final String mobileNumber =
        _stringValue(
      data[_mobileNumberField],
    );

    final String dateOfBirth =
        _stringValue(
      data[_dateOfBirthField],
    );

    final String address =
        _stringValue(
      data[_addressField],
    );

    final String pinCode =
        _stringValue(
      data[_pinCodeField],
    );

    final String aadhaarNumber =
        _stringValue(
      data[_aadhaarNumberField],
    );

    final String profileSelfie =
        _stringValue(
      data[_profileSelfieField],
    );

    final String aadhaarFront =
        _stringValue(
      data[_aadhaarFrontField],
    );

    final String aadhaarBack =
        _stringValue(
      data[_aadhaarBackField],
    );

    // ----------------------------------------------------------
    // ADDRESS COMPONENTS
    //
    // These are checked too so the profile is actually complete.
    // ----------------------------------------------------------

    final String village =
        _stringValue(
      data[_villageField],
    );

    final String city =
        _stringValue(
      data[_cityField],
    );

    final String district =
        _stringValue(
      data[_districtField],
    );

    final String state =
        _stringValue(
      data[_stateField],
    );

    // ----------------------------------------------------------
    // VERIFICATION
    // ----------------------------------------------------------

    final bool aadhaarVerified =
        data[_aadhaarVerifiedField] == true;

    final bool nameMatched =
        data[_nameMatchedField] == true;

    final bool dobMatched =
        data[_dobMatchedField] == true;

    final String verifiedName =
        _stringValue(
      data[_aadhaarVerifiedNameField],
    );

    // ----------------------------------------------------------
    // FINAL CHECK
    // ----------------------------------------------------------

    return walkerUid.isNotEmpty &&
        fullName.isNotEmpty &&
        mobileNumber.isNotEmpty &&
        dateOfBirth.isNotEmpty &&
        address.isNotEmpty &&
        pinCode.isNotEmpty &&
        aadhaarNumber.isNotEmpty &&
        profileSelfie.isNotEmpty &&
        aadhaarFront.isNotEmpty &&
        aadhaarBack.isNotEmpty &&
        village.isNotEmpty &&
        city.isNotEmpty &&
        district.isNotEmpty &&
        state.isNotEmpty &&
        aadhaarVerified &&
        nameMatched &&
        dobMatched &&
        verifiedName.isNotEmpty;
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  static String _stringValue(
    dynamic value,
  ) {
    return value?.toString().trim() ?? '';
  }

  // ============================================================
  // CREATE FALLBACK WALKER ID
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
  //
  // URL मौजूद है → URL use होगा.
  //
  // File मौजूद है → Firebase Storage upload होगा.
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

    if (!RegExp(r'^\d{12}$').hasMatch(
      cleanAadhaar,
    )) {
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

    if (!RegExp(r'^\d{6}$').hasMatch(
      cleanPinCode,
    )) {
      throw Exception(
        'Pincode must contain exactly 6 digits.',
      );
    }

    // ==========================================================
    // VERIFICATION VALIDATION
    // ==========================================================

    if (!aadhaarVerified) {
      throw Exception(
        'Aadhaar verification is required.',
      );
    }

    if (!nameMatched) {
      throw Exception(
        'Name verification is required.',
      );
    }

    if (!dobMatched) {
      throw Exception(
        'Date of Birth verification is required.',
      );
    }

    if (cleanVerifiedName.isEmpty) {
      throw Exception(
        'Verified Aadhaar name is missing.',
      );
    }

    // ==========================================================
    // PROFILE REFERENCE
    //
    // walkerProfiles/{Firebase Auth UID}
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
        existing.data() ?? <String, dynamic>{};

    // ==========================================================
    // WALKER UID
    // ==========================================================

    String walkerId =
        _stringValue(
      existingData[_walkerUidField],
    );

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(cleanUid);
    }

    // ==========================================================
    // DATE OF BIRTH
    //
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
        '${dateOfBirth.year}-$month-$day';

    // ==========================================================
    // UPLOAD / RESOLVE SELFIE
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
    // UPLOAD / RESOLVE AADHAAR FRONT
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
    // UPLOAD / RESOLVE AADHAAR BACK
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
    // COMPLETE ADDRESS
    //
    // EXACT "Adress" field
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
      // --------------------------------------------------------
      // AUTH
      // --------------------------------------------------------

      _authUidField: cleanUid,

      _roleField: 'walker',

      // --------------------------------------------------------
      // MAIN FIELDS
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
      // --------------------------------------------------------

      _villageField: cleanVillage,

      _cityField: cleanCity,

      _districtField: cleanDistrict,

      _stateField: cleanState,

      // --------------------------------------------------------
      // AADHAAR IMAGES
      // --------------------------------------------------------

      _aadhaarFrontField: finalFrontUrl,

      _aadhaarBackField: finalBackUrl,

      // --------------------------------------------------------
      // VERIFICATION
      // --------------------------------------------------------

      _aadhaarVerifiedField: true,

      _nameMatchedField: true,

      _dobMatchedField: true,

      _aadhaarVerifiedNameField:
          cleanVerifiedName,

      // --------------------------------------------------------
      // PROFILE COMPLETION
      // --------------------------------------------------------

      _profileCompletedField: true,

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
    // FINAL FIRESTORE SAVE
    // ==========================================================

    await profileRef.set(
      profileData,
      SetOptions(merge: true),
    );

    // ==========================================================
    // VERIFY SAVE
    //
    // यह अतिरिक्त check सुनिश्चित करता है कि Firestore में
    // profileCompleted वास्तव में true लिखा गया है.
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        savedProfile = await profileRef.get();

    final Map<String, dynamic> savedData =
        savedProfile.data() ?? <String, dynamic>{};

    if (savedData[_profileCompletedField] != true) {
      throw Exception(
        'Profile was saved, but profileCompleted was not confirmed.',
      );
    }

    // ==========================================================
    // DEBUG LOG
    // ==========================================================

    developer.log(
      'Walker profile saved successfully. '
      'collection=$_collection '
      'uid=$cleanUid '
      'walkerId=$walkerId '
      'profileCompleted=true',
      name: 'ProfileSetupService',
    );
  }
}
