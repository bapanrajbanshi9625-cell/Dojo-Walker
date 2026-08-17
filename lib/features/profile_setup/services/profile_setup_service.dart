import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileSetupService {
  ProfileSetupService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseStorage _storage =
      FirebaseStorage.instance;

  // =====================================================
  // FIRESTORE COLLECTION
  // =====================================================

  static const String _collection = 'walkerProfiles';

  // =====================================================
  // GET WALKER PROFILE
  // =====================================================

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

  // =====================================================
  // CHECK WALKER PROFILE COMPLETED
  //
  // Firestore:
  //
  // walkerProfiles/{authUid}
  //
  // profileCompleted is NOT required for old documents.
  // Required profile fields are checked instead.
  // =====================================================

  static Future<bool> isWalkerProfileCompleted({
    required String authUid,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      return false;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> document =
          await _firestore
              .collection(_collection)
              .doc(cleanUid)
              .get();

      // ---------------------------------------------------
      // DOCUMENT DOES NOT EXIST
      // ---------------------------------------------------

      if (!document.exists) {
        return false;
      }

      final Map<String, dynamic>? data =
          document.data();

      if (data == null) {
        return false;
      }

      // ---------------------------------------------------
      // AUTH UID
      // ---------------------------------------------------

      final String savedAuthUid =
          data['authUid']?.toString().trim() ?? '';

      if (savedAuthUid.isEmpty ||
          savedAuthUid != cleanUid) {
        return false;
      }

      // ---------------------------------------------------
      // ROLE
      // ---------------------------------------------------

      final String role =
          data['role']?.toString().trim().toLowerCase() ?? '';

      if (role != 'walker') {
        return false;
      }

      // ---------------------------------------------------
      // WALKER ID
      // ---------------------------------------------------

      final String walkerId =
          data['walkerId']?.toString().trim() ?? '';

      // ---------------------------------------------------
      // PERSONAL DETAILS
      // ---------------------------------------------------

      final String fullName =
          data['fullName']?.toString().trim() ?? '';

      final String dateOfBirth =
          data['dateofbirth']?.toString().trim() ?? '';

      final String address =
          data['address']?.toString().trim() ?? '';

      final String pinCode =
          data['pincode']?.toString().trim() ?? '';

      // ---------------------------------------------------
      // AADHAAR
      // ---------------------------------------------------

      final String aadhaarNumber =
          data['aadhaarNumber']?.toString().trim() ?? '';

      final String aadhaarFront =
          data['aadharfront']?.toString().trim() ?? '';

      final String aadhaarBack =
          data['aadharback']?.toString().trim() ?? '';

      // ---------------------------------------------------
      // SELFIE
      // ---------------------------------------------------

      final String selfie =
          data['selfie']?.toString().trim() ?? '';

      // ---------------------------------------------------
      // FINAL PROFILE CHECK
      //
      // profileCompleted field is intentionally NOT
      // required here so older valid profiles work too.
      // ---------------------------------------------------

      final bool completed =
          walkerId.isNotEmpty &&
          fullName.isNotEmpty &&
          dateOfBirth.isNotEmpty &&
          address.isNotEmpty &&
          pinCode.isNotEmpty &&
          aadhaarNumber.isNotEmpty &&
          aadhaarFront.isNotEmpty &&
          aadhaarBack.isNotEmpty &&
          selfie.isNotEmpty;

      // ---------------------------------------------------
      // DEBUG
      // ---------------------------------------------------

      print('========================================');
      print('WALKER PROFILE CHECK');
      print('Collection: $_collection');
      print('Document: $cleanUid');
      print('authUid: $savedAuthUid');
      print('walkerId: $walkerId');
      print('role: $role');
      print('fullName: ${fullName.isNotEmpty}');
      print('dateofbirth: ${dateOfBirth.isNotEmpty}');
      print('address: ${address.isNotEmpty}');
      print('pincode: ${pinCode.isNotEmpty}');
      print('aadhaarNumber: ${aadhaarNumber.isNotEmpty}');
      print('aadharfront: ${aadhaarFront.isNotEmpty}');
      print('aadharback: ${aadhaarBack.isNotEmpty}');
      print('selfie: ${selfie.isNotEmpty}');
      print(
        'profileCompleted field: '
        '${data['profileCompleted']}',
      );
      print('FINAL RESULT: $completed');
      print('========================================');

      return completed;
    } catch (e) {
      print('========================================');
      print('WALKER PROFILE CHECK ERROR');
      print('$e');
      print('========================================');

      // Do NOT treat Firestore/network errors as
      // an incomplete profile.
      rethrow;
    }
  }

  // =====================================================
  // CREATE WALKER ID
  // =====================================================

  static String createWalkerId(String authUid) {
    final String cleanUid = authUid.trim();

    if (cleanUid.length >= 8) {
      return 'WKR-${cleanUid.substring(0, 8).toUpperCase()}';
    }

    return 'WKR-${cleanUid.toUpperCase()}';
  }

  // =====================================================
  // UPLOAD FILE
  // =====================================================

  static Future<String> _uploadFile({
    required String authUid,
    required String folder,
    required String fileName,
    required File file,
  }) async {
    final Reference reference = _storage
        .ref()
        .child('walkerProfiles')
        .child(authUid)
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

  // =====================================================
  // SAVE WALKER PROFILE
  // =====================================================

  static Future<void> saveWalkerProfile({
    required String authUid,
    required String phoneNumber,
    required String name,
    required DateTime dateOfBirth,
    required String aadhaar,
    required String address,
    required String pinCode,
    required File selfieFile,
    required File aadhaarFrontFile,
    required File aadhaarBackFile,
  }) async {
    final String cleanUid = authUid.trim();

    if (cleanUid.isEmpty) {
      throw Exception(
        'Authentication UID is missing.',
      );
    }

    // ===================================================
    // PROFILE DOCUMENT
    // ===================================================

    final DocumentReference<Map<String, dynamic>>
        profileRef = _firestore
            .collection(_collection)
            .doc(cleanUid);

    final DocumentSnapshot<Map<String, dynamic>>
        existing = await profileRef.get();

    // ===================================================
    // WALKER ID
    // ===================================================

    String walkerId =
        existing.data()?['walkerId']
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      walkerId = createWalkerId(cleanUid);
    }

    // ===================================================
    // UPLOAD SELFIE
    // ===================================================

    final String selfieUrl =
        await _uploadFile(
      authUid: cleanUid,
      folder: 'selfie',
      fileName: 'selfie.jpg',
      file: selfieFile,
    );

    // ===================================================
    // UPLOAD AADHAAR FRONT
    // ===================================================

    final String aadhaarFrontUrl =
        await _uploadFile(
      authUid: cleanUid,
      folder: 'aadhaar',
      fileName: 'front.jpg',
      file: aadhaarFrontFile,
    );

    // ===================================================
    // UPLOAD AADHAAR BACK
    // ===================================================

    final String aadhaarBackUrl =
        await _uploadFile(
      authUid: cleanUid,
      folder: 'aadhaar',
      fileName: 'back.jpg',
      file: aadhaarBackFile,
    );

    // ===================================================
    // DATE FORMAT
    // ===================================================

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

    // ===================================================
    // SAVE FIRESTORE
    // ===================================================

    await profileRef.set(
      {
        // -------------------------------------------------
        // BACKEND IDENTITY
        // -------------------------------------------------

        'authUid': cleanUid,
        'walkerId': walkerId,
        'role': 'walker',

        // -------------------------------------------------
        // PERSONAL DETAILS
        // -------------------------------------------------

        'fullName': name.trim(),
        'phoneNumber': phoneNumber.trim(),
        'dateofbirth': formattedDate,
        'address': address.trim(),
        'pincode': pinCode.trim(),

        // -------------------------------------------------
        // AADHAAR
        // -------------------------------------------------

        'aadhaarNumber': aadhaar.trim(),
        'aadharfront': aadhaarFrontUrl,
        'aadharback': aadhaarBackUrl,

        // -------------------------------------------------
        // SELFIE
        // -------------------------------------------------

        'selfie': selfieUrl,

        // -------------------------------------------------
        // STATUS
        // -------------------------------------------------

        'aadhaarFrontUploaded': true,
        'aadhaarBackUploaded': true,

        // Keep this for future/backend use.
        'profileCompleted': true,

        // -------------------------------------------------
        // TIMESTAMPS
        // -------------------------------------------------

        if (!existing.exists)
          'createdAt':
              FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ===================================================
    // VERIFY SAVE
    // ===================================================

    final DocumentSnapshot<Map<String, dynamic>>
        savedProfile =
        await profileRef.get();

    final bool saved =
        savedProfile.exists &&
        savedProfile.data()?['authUid']
                ?.toString()
                .trim() ==
            cleanUid;

    if (!saved) {
      throw Exception(
        'Walker profile could not be verified after saving.',
      );
    }

    print('========================================');
    print('WALKER PROFILE SAVED');
    print('Collection: $_collection');
    print('Document: $cleanUid');
    print('Walker ID: $walkerId');
    print('Profile Completed: true');
    print('========================================');
  }
}
