// File:
// lib/features/profile_setup/services/profile_setup_service_helpers.dart

class ProfileSetupServiceHelpers {
  ProfileSetupServiceHelpers._();

  // ============================================================
  // URL VALIDATION
  // ============================================================

  static bool isValidUrl(String value) {
    final String cleanValue = value.trim();

    if (cleanValue.isEmpty) {
      return false;
    }

    final Uri? uri = Uri.tryParse(cleanValue);

    if (uri == null || uri.host.isEmpty) {
      return false;
    }

    return uri.scheme == 'http' ||
        uri.scheme == 'https';
  }

  // ============================================================
  // RESOLVE IMAGE
  //
  // IMPORTANT:
  //
  // Images are uploaded to Cloudinary from the UI.
  //
  // This service only receives the Cloudinary URL
  // and saves/returns that URL for Firestore.
  //
  // No Firebase Storage upload is performed here.
  //
  // Priority:
  //
  // 1. Cloudinary URL
  // 2. Otherwise error
  //
  // ============================================================

  static Future<String> resolveImage({
    required String authUid,
    required String folder,
    required String fileName,
    Object? file,
    String? url,
  }) async {
    final String cleanUrl = url?.trim() ?? '';

    // ----------------------------------------------------------
    // UID CHECK
    // ----------------------------------------------------------

    final String uid = authUid.trim();

    if (uid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    // ----------------------------------------------------------
    // CLOUDINARY URL
    // ----------------------------------------------------------

    if (cleanUrl.isNotEmpty) {
      if (!isValidUrl(cleanUrl)) {
        throw Exception(
          'Invalid image URL.',
        );
      }

      return cleanUrl;
    }

    // ----------------------------------------------------------
    // NO URL
    // ----------------------------------------------------------

    throw Exception(
      'Required image is missing.',
    );
  }

  // ============================================================
  // PROFILE SELFIE
  // ============================================================

  static Future<String> resolveSelfie({
    required String authUid,
    Object? file,
    String? url,
  }) async {
    return resolveImage(
      authUid: authUid,
      folder: 'selfie',
      fileName: 'selfie.jpg',
      file: file,
      url: url,
    );
  }

  // ============================================================
  // AADHAAR FRONT
  // ============================================================

  static Future<String> resolveAadhaarFront({
    required String authUid,
    Object? file,
    String? url,
  }) async {
    return resolveImage(
      authUid: authUid,
      folder: 'aadhaar',
      fileName: 'front.jpg',
      file: file,
      url: url,
    );
  }

  // ============================================================
  // AADHAAR BACK
  // ============================================================

  static Future<String> resolveAadhaarBack({
    required String authUid,
    Object? file,
    String? url,
  }) async {
    return resolveImage(
      authUid: authUid,
      folder: 'aadhaar',
      fileName: 'back.jpg',
      file: file,
      url: url,
    );
  }

  // ============================================================
  // PAN CARD
  // ============================================================

  static Future<String> resolvePanCard({
    required String authUid,
    Object? file,
    String? url,
  }) async {
    return resolveImage(
      authUid: authUid,
      folder: 'pan',
      fileName: 'pan.jpg',
      file: file,
      url: url,
    );
  }

  // ============================================================
  // DATE OF BIRTH
  // ============================================================

  static String formatDateOfBirth(
    DateTime dateOfBirth,
  ) {
    return '${dateOfBirth.year}-'
        '${dateOfBirth.month.toString().padLeft(2, '0')}-'
        '${dateOfBirth.day.toString().padLeft(2, '0')}';
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
  // AADHAAR VALIDATION
  // ============================================================

  static bool isValidAadhaar(
    String value,
  ) {
    return RegExp(
      r'^\d{12}$',
    ).hasMatch(
      value.trim(),
    );
  }

  // ============================================================
  // PIN VALIDATION
  // ============================================================

  static bool isValidPin(
    String value,
  ) {
    return RegExp(
      r'^\d{6}$',
    ).hasMatch(
      value.trim(),
    );
  }

  // ============================================================
  // PAN VALIDATION
  // ============================================================

  static bool isValidPan(
    String value,
  ) {
    return RegExp(
      r'^[A-Z]{5}[0-9]{4}[A-Z]$',
    ).hasMatch(
      value.trim().toUpperCase(),
    );
  }

  // ============================================================
  // MOBILE VALIDATION
  // ============================================================

  static bool isValidMobile(
    String value,
  ) {
    return RegExp(
      r'^\d{10}$',
    ).hasMatch(
      value.trim(),
    );
  }

  // ============================================================
  // CLEAN STRING
  // ============================================================

  static String clean(
    String? value,
  ) {
    return value?.trim() ?? '';
  }

  // ============================================================
  // EMERGENCY CONTACT VALIDATION
  // ============================================================

  static bool isValidEmergencyContact({
    required String name,
    required String mobile,
  }) {
    final String cleanName =
        name.trim();

    final String cleanMobile =
        mobile.trim();

    // Both empty = optional and valid.
    if (cleanName.isEmpty &&
        cleanMobile.isEmpty) {
      return true;
    }

    // If one is provided, both are required.
    if (cleanName.isEmpty ||
        cleanMobile.isEmpty) {
      return false;
    }

    return isValidMobile(cleanMobile);
  }
}
