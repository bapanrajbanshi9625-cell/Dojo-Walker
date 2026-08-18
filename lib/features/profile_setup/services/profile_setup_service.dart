import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileSetupService {
  ProfileSetupService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const String _collection =
      'walkerProfiles';

  // ============================================================
  // GET PROFILE
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>> getWalkerProfile({
    required String authUid,
  }) async {
    final String uid = authUid.trim();

    if (uid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    return _firestore
        .collection(_collection)
        .doc(uid)
        .get();
  }

  // ============================================================
  // CHECK PROFILE COMPLETE
  // ============================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final String uid = authUid.trim();

    if (uid.isEmpty) {
      return false;
    }

    final DocumentSnapshot<
        Map<String, dynamic>> doc =
        await _firestore
            .collection(_collection)
            .doc(uid)
            .get();

    if (!doc.exists) {
      return false;
    }

    final Map<String, dynamic> data =
        doc.data() ?? <String, dynamic>{};

    return data['profileCompleted'] == true &&
        data['aadhaarVerified'] == true &&
        data['nameMatched'] == true &&
        data['dobMatched'] == true &&
        (data['selfie']?.toString().trim().isNotEmpty ??
            false) &&
        (data['aadharfront']?.toString().trim().isNotEmpty ??
            false) &&
        (data['aadharback']?.toString().trim().isNotEmpty ??
            false);
  }

  // ============================================================
  // WALKER ID
  // ============================================================

  static String createWalkerId(
    String authUid,
  ) {
    final String uid = authUid.trim();

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
  // SAVE FINAL PROFILE
  //
  // IMPORTANT:
  // This method must ONLY be called after successful
  // verification.
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

    required String selfieUrl,
    required String aadhaarFrontUrl,
    required String aadhaarBackUrl,

    required bool aadhaarVerified,
    required bool nameMatched,
    required bool dobMatched,

    required String aadhaarVerifiedName,
  }) async {
    final String uid =
        authUid.trim();

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

    final String cleanSelfieUrl =
        selfieUrl.trim();

    final String cleanFrontUrl =
        aadhaarFrontUrl.trim();

    final String cleanBackUrl =
        aadhaarBackUrl.trim();

    final String cleanVerifiedName =
        aadhaarVerifiedName.trim();

    // ==========================================================
    // VALIDATION
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

    if (!RegExp(r'^\d{12}$')
        .hasMatch(cleanAadhaar)) {
      throw Exception(
        'Aadhaar number must contain 12 digits.',
      );
    }

    if (!RegExp(r'^\d{6}$')
        .hasMatch(cleanPinCode)) {
      throw Exception(
        'PIN code must contain 6 digits.',
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

    if (cleanSelfieUrl.isEmpty) {
      throw Exception(
        'Selfie URL is required.',
      );
    }

    if (cleanFrontUrl.isEmpty) {
      throw Exception(
        'Aadhaar front URL is required.',
      );
    }

    if (cleanBackUrl.isEmpty) {
      throw Exception(
        'Aadhaar back URL is required.',
      );
    }

    // ==========================================================
    // NEVER COMPLETE WITHOUT VERIFICATION
    // ==========================================================

    if (!aadhaarVerified) {
      throw Exception(
        'Aadhaar verification is required.',
      );
    }

    if (!nameMatched) {
      throw Exception(
        'Aadhaar name verification failed.',
      );
    }

    if (!dobMatched) {
      throw Exception(
        'Aadhaar date of birth verification failed.',
      );
    }

    if (cleanVerifiedName.isEmpty) {
      throw Exception(
        'Verified Aadhaar name is missing.',
      );
    }

    // ==========================================================
    // PROFILE REF
    // ==========================================================

    final DocumentReference<
        Map<String, dynamic>> profileRef =
        _firestore
            .collection(_collection)
            .doc(uid);

    final DocumentSnapshot<
        Map<String, dynamic>> existing =
        await profileRef.get();

    String walkerId =
        existing.data()?['walkerId']
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      walkerId =
          createWalkerId(uid);
    }

    // ==========================================================
    // DOB
    // ==========================================================

    final String month =
        dateOfBirth.month
            .toString()
            .padLeft(2, '0');

    final String day =
        dateOfBirth.day
            .toString()
            .padLeft(2, '0');

    final String formattedDob =
        '${dateOfBirth.year}-$month-$day';

    // ==========================================================
    // PROFILE DATA
    // ==========================================================

    final Map<String, dynamic> data =
        <String, dynamic>{
      // Backend identity
      'authUid': uid,
      'walkerId': walkerId,
      'role': 'walker',

      // Personal
      'fullName': cleanName,
      'phoneNumber': phoneNumber.trim(),
      'dateofbirth': formattedDob,

      // Address
      'village': cleanVillage,
      'city': cleanCity,
      'district': cleanDistrict,
      'state': cleanState,
      'pincode': cleanPinCode,

      // Aadhaar
      'aadhaarNumber': cleanAadhaar,
      'aadharfront': cleanFrontUrl,
      'aadharback': cleanBackUrl,

      // Verification
      'aadhaarVerified': true,
      'nameMatched': true,
      'dobMatched': true,
      'aadhaarVerifiedName':
          cleanVerifiedName,

      // Selfie
      'selfie': cleanSelfieUrl,

      // Completion
      'profileCompleted': true,

      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (!existing.exists) {
      data['createdAt'] =
          FieldValue.serverTimestamp();
    }

    // ==========================================================
    // FINAL SAVE
    // ==========================================================

    await profileRef.set(
      data,
      SetOptions(merge: true),
    );
  }
}
