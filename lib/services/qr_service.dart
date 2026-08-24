// File:
// lib/services/qr_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// QR DATA
/// ============================================================

class QRData {
  final String ownerId;
  final String ownerName;
  final String walkId;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  const QRData({
    required this.ownerId,
    required this.ownerName,
    required this.walkId,
    required this.dogName,
    required this.dogBreed,
    required this.ownerPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': 'dojo_owner_qr',
      'version': 1,
      'ownerId': ownerId,
      'ownerName': ownerName,
      'walkId': walkId,
      'dogName': dogName,
      'dogBreed': dogBreed,
      if (ownerPhone != null && ownerPhone!.isNotEmpty)
        'ownerPhone': ownerPhone,
    };
  }

  String encode() {
    return jsonEncode(toMap());
  }

  factory QRData.fromMap(Map<String, dynamic> map) {
    final String ownerPhone =
        (map['ownerPhone'] ?? '').toString().trim();

    return QRData(
      ownerId: (map['ownerId'] ?? '').toString().trim(),
      ownerName: (map['ownerName'] ?? 'Owner').toString().trim(),
      walkId: (map['walkId'] ?? '').toString().trim(),
      dogName: (map['dogName'] ?? 'Dog').toString().trim(),
      dogBreed: (map['dogBreed'] ?? '').toString().trim(),
      ownerPhone: ownerPhone.isEmpty ? null : ownerPhone,
    );
  }
}

/// ============================================================
/// QR SERVICE
/// ============================================================

class QRService {
  QRService._();

  static final QRService instance = QRService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  /// ==========================================================
  /// GET CURRENT OWNER ID
  /// ==========================================================

  Future<String> getOwnerId() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Owner is not logged in.');
    }

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      throw Exception('Owner account is invalid.');
    }

    final DocumentSnapshot<Map<String, dynamic>> ownerDoc =
        await _firestore.collection('owners').doc(uid).get();

    if (!ownerDoc.exists) {
      throw Exception('Owner profile not found.');
    }

    final Map<String, dynamic> data =
        ownerDoc.data() ?? <String, dynamic>{};

    final String ownerId = (
      data['ownerId'] ??
      data['businessId'] ??
      data['Business ID'] ??
      data['Owner ID'] ??
      ''
    ).toString().trim();

    if (ownerId.isEmpty) {
      throw Exception('Owner ID is missing.');
    }

    return ownerId;
  }

  /// ==========================================================
  /// CREATE WALK ID
  /// ==========================================================

  String createWalkId() {
    return 'walk_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// ==========================================================
  /// GENERATE OWNER QR PAYLOAD
  /// ==========================================================

  Future<String> generateOwnerQR({
    required String walkId,
    String dogName = 'Dog',
    String dogBreed = '',
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Owner is not logged in.');
    }

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      throw Exception('Owner account is invalid.');
    }

    final DocumentSnapshot<Map<String, dynamic>> ownerDoc =
        await _firestore.collection('owners').doc(uid).get();

    if (!ownerDoc.exists) {
      throw Exception('Owner profile not found.');
    }

    final Map<String, dynamic> ownerData =
        ownerDoc.data() ?? <String, dynamic>{};

    final String ownerId = (
      ownerData['ownerId'] ??
      ownerData['businessId'] ??
      ownerData['Business ID'] ??
      ownerData['Owner ID'] ??
      ''
    ).toString().trim();

    if (ownerId.isEmpty) {
      throw Exception('Owner ID is missing.');
    }

    final String ownerName = (
      ownerData['ownerName'] ??
      ownerData['name'] ??
      ownerData['Full Name'] ??
      user.displayName ??
      'Owner'
    ).toString().trim();

    final String ownerPhone = (
      ownerData['ownerPhone'] ??
      ownerData['phoneNumber'] ??
      ownerData['Mobile number'] ??
      user.phoneNumber ??
      ''
    ).toString().trim();

    final String cleanWalkId = walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw Exception('Walk ID is missing.');
    }

    final QRData qrData = QRData(
      ownerId: ownerId,
      ownerName: ownerName.isEmpty ? 'Owner' : ownerName,
      walkId: cleanWalkId,
      dogName: dogName.trim().isEmpty
          ? 'Dog'
          : dogName.trim(),
      dogBreed: dogBreed.trim(),
      ownerPhone: ownerPhone.isEmpty ? null : ownerPhone,
    );

    await _firestore
        .collection('qr_connections')
        .doc(uid)
        .set(
      {
        'type': 'dojo_owner_qr',
        'version': 1,
        'ownerId': ownerId,
        'ownerUid': uid,
        'ownerName': qrData.ownerName,
        'walkId': cleanWalkId,
        'dogName': qrData.dogName,
        'dogBreed': qrData.dogBreed,
        'ownerPhone': qrData.ownerPhone ?? '',
        'scanned': false,
        'connected': false,
        'walkerId': null,
        'walkerName': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    return qrData.encode();
  }

  /// ==========================================================
  /// CREATE NEW WALK + QR
  /// ==========================================================

  Future<String> createOwnerWalkQR({
    String dogName = 'Dog',
    String dogBreed = '',
  }) async {
    final String walkId = createWalkId();

    return generateOwnerQR(
      walkId: walkId,
      dogName: dogName,
      dogBreed: dogBreed,
    );
  }

  /// ==========================================================
  /// WATCH QR CONNECTION
  /// ==========================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      watchOwnerConnection() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('qr_connections')
        .doc(user.uid)
        .snapshots();
  }

  /// ==========================================================
  /// RESET OWNER QR
  /// ==========================================================

  Future<void> resetOwnerQR() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('Owner is not logged in.');
    }

    await _firestore
        .collection('qr_connections')
        .doc(user.uid)
        .set(
      {
        'scanned': false,
        'connected': false,
        'walkerId': null,
        'walkerName': null,
        'activeWalkId': null,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// ==========================================================
  /// PARSE QR PAYLOAD
  /// ==========================================================

  static QRData parseQR(String raw) {
    final String value = raw.trim();

    if (value.isEmpty) {
      throw Exception('QR code is empty.');
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(value);
    } catch (_) {
      throw Exception('Invalid QR data.');
    }

    if (decoded is! Map) {
      throw Exception('Invalid Owner QR Code.');
    }

    final Map<String, dynamic> map =
        Map<String, dynamic>.from(decoded);

    final String type =
        (map['type'] ?? '').toString().trim();

    if (type != 'dojo_owner_qr') {
      throw Exception('This is not a valid Owner QR Code.');
    }

    final String ownerId =
        (map['ownerId'] ?? '').toString().trim();

    if (ownerId.isEmpty) {
      throw Exception('Owner ID is missing from QR.');
    }

    final String walkId =
        (map['walkId'] ?? '').toString().trim();

    if (walkId.isEmpty) {
      throw Exception('Walk ID is missing from QR.');
    }

    return QRData.fromMap(map);
  }

  /// ==========================================================
  /// DATA FROM PAYLOAD
  ///
  /// Used by qr_scanner_screen.dart
  /// ==========================================================

  static QRData dataFromPayload(String payload) {
    return parseQR(payload);
  }
}
