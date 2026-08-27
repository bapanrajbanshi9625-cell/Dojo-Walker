// File:
// lib/features/profile_setup/services/profile_setup_service_helpers.dart

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

class ProfileSetupServiceHelpers {
  ProfileSetupServiceHelpers._();

  // ============================================================
  // FIREBASE STORAGE
  // ============================================================

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

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
  // UPLOAD FILE
  //
  // Firebase Storage path:
  //
  // walkers/{uid}/{folder}/{fileName}
  //
  // ============================================================

  static Future<String> uploadFile({
    required String authUid,
    required String folder,
    required String fileName,
    required File file,
  }) async {
    final String uid = authUid.trim();

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

    final Reference storageRef = _storage
        .ref()
        .child('walkers')
        .child(uid)
        .child(folder)
        .child(fileName);

    try {
      await storageRef.putFile(
        file,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      return await storageRef.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'unauthorized' ||
          e.code == 'permission-denied') {
        throw Exception(
          'Firebase Storage permission denied.',
        );
      }

      if (e.code == 'canceled') {
        throw Exception(
          'Image upload was cancelled.',
        );
      }

      if (e.code == 'retry-limit-exceeded') {
        throw Exception(
          'Image upload timed out. Please try again.',
        );
      }

      throw Exception(
        e.message ??
            'Unable to upload image.',
      );
    }
  }

  // ============================================================
  // RESOLVE IMAGE
  //
  // Priority:
  //
  // 1. URL
  // 2. Firebase Storage file
  //
  // ============================================================

  static Future<String> resolveImage({
    required String authUid,
    required String folder,
    required String fileName,
    File? file,
    String? url,
  }) async {
    final String cleanUrl =
        url?.trim() ?? '';

    // ----------------------------------------------------------
    // URL FALLBACK
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
    // FIREBASE STORAGE FILE
    // ----------------------------------------------------------

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
  // PROFILE SELFIE
  // ============================================================

  static Future<String> resolveSelfie({
    required String authUid,
    File? file,
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
    File? file,
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
    File? file,
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
    File? file,
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
