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
  //
  // Priority:
  //
  // 1. Valid URL
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
    final String cleanUrl = url?.trim() ?? '';

    // ----------------------------------------------------------
    // URL
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
    // FILE
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
  // DATE FORMAT
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
}
