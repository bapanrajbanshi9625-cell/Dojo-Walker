// File:
// lib/features/qr_walk/services/qr_walk_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class QrWalkService {
  QrWalkService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  CollectionReference<Map<String, dynamic>> get _qrConnections =>
      _firestore.collection('qr_connections');

  CollectionReference<Map<String, dynamic>> get _liveWalkSessions =>
      _firestore.collection('liveWalkSessions');

  // ==========================================================
  // PROCESS OWNER QR
  // ==========================================================

  Future<Map<String, dynamic>> processOwnerQr({
    required String rawData,
  }) async {
    _log('========== QR WALK START ==========');

    // ========================================================
    // 1. VALIDATE RAW QR
    // ========================================================

    final String cleanData = rawData.trim();

    _log('STEP 1: Validate QR');

    if (cleanData.isEmpty) {
      _log('STEP 1 FAILED: Empty QR');
      throw Exception('Invalid QR code.');
    }

    _log('STEP 1 OK');

    // ========================================================
    // 2. CURRENT WALKER
    // ========================================================

    _log('STEP 2: Check current Walker');

    final User? walker = _auth.currentUser;

    if (walker == null) {
      _log('STEP 2 FAILED: Walker not logged in');
      throw Exception('Walker is not logged in.');
    }

    final String walkerUid = walker.uid.trim();

    if (walkerUid.isEmpty) {
      _log('STEP 2 FAILED: Walker UID empty');
      throw Exception('Walker Firebase UID is missing.');
    }

    _log('STEP 2 OK: walkerUid=$walkerUid');

    // ========================================================
    // 3. DECODE QR
    // ========================================================

    _log('STEP 3: Decode QR');

    final Map<String, dynamic> qrData = _decodeQrPayload(cleanData);

    _log('STEP 3 OK');

    // ========================================================
    // 4. QR TYPE
    // ========================================================

    _log('STEP 4: Validate QR type');

    final String qrType = _readString(
      qrData,
      <String>['type'],
    );

    if (qrType.isNotEmpty && qrType != 'dojo_owner_qr') {
      _log('STEP 4 FAILED: Invalid QR type=$qrType');
      throw Exception(
        'This QR code is not a valid Dojo Owner QR.',
      );
    }

    _log('STEP 4 OK');

    // ========================================================
    // 5. OWNER BUSINESS ID
    // ========================================================

    _log('STEP 5: Read Owner Business ID');

    final String ownerId = _readString(
      qrData,
      <String>[
        'ownerId',
        'ownerBusinessId',
        'ownerBusinessID',
      ],
    );

    if (ownerId.isEmpty) {
      _log('STEP 5 FAILED: Owner ID missing');
      throw Exception(
        'Owner Business ID is missing from QR code.',
      );
    }

    _log('STEP 5 OK: ownerId=$ownerId');

    // ========================================================
    // 6. REQUEST ID
    // ========================================================

    _log('STEP 6: Read Walk ID');

    String requestId = _readString(
      qrData,
      <String>[
        'requestId',
        'walkId',
        'qrWalkId',
      ],
    );

    if (requestId.isEmpty) {
      _log('STEP 6 FAILED: Walk ID missing');
      throw Exception(
        'Walk ID is missing from QR code.',
      );
    }

    requestId = requestId.trim();

    _log('STEP 6 OK: requestId=$requestId');

    // ========================================================
    // 7. VALIDATE DW ID
    // ========================================================

    _log('STEP 7: Validate DW ID');

    if (!RegExp(r'^DW\d{6}$').hasMatch(requestId)) {
      _log('STEP 7 FAILED: Invalid requestId=$requestId');

      throw Exception(
        'Invalid Walk ID. Expected DW######.',
      );
    }

    _log('STEP 7 OK');

    // ========================================================
    // 8. QR CONNECTION READ
    // ========================================================

    _log(
      'STEP 8: READ qr_connections/$ownerId',
    );

    final DocumentReference<Map<String, dynamic>> connectionRef =
        _qrConnections.doc(ownerId);

    DocumentSnapshot<Map<String, dynamic>> connectionSnapshot;

    try {
      connectionSnapshot = await connectionRef.get();

      _log(
        'STEP 8 OK: qr_connections/$ownerId READ successful',
      );
    } catch (error) {
      _log(
        'STEP 8 FAILED: qr_connections READ',
      );
      _log('ERROR: $error');

      rethrow;
    }

    if (!connectionSnapshot.exists) {
      _log('STEP 8 FAILED: QR document does not exist');

      throw Exception(
        'Owner QR session was not found or has expired.',
      );
    }

    final Map<String, dynamic> connectionData =
        connectionSnapshot.data() ?? <String, dynamic>{};

    _log('STEP 8 DATA OK');

    // ========================================================
    // 9. VERIFY OWNER ID
    // ========================================================

    _log('STEP 9: Verify Owner ID');

    final String firebaseOwnerId = _readString(
      connectionData,
      <String>['ownerId'],
    );

    if (firebaseOwnerId.isEmpty) {
      _log('STEP 9 FAILED: Firebase Owner ID missing');

      throw Exception(
        'Owner Business ID is missing in Firebase.',
      );
    }

    if (firebaseOwnerId != ownerId) {
      _log(
        'STEP 9 FAILED: ownerId mismatch '
        '$firebaseOwnerId != $ownerId',
      );

      throw Exception(
        'Owner Business ID verification failed.',
      );
    }

    _log('STEP 9 OK');

    // ========================================================
    // 10. FIRESTORE REQUEST ID
    // ========================================================

    _log('STEP 10: Read Firestore requestId');

    final String firebaseRequestId = _readString(
      connectionData,
      <String>[
        'requestId',
        'walkId',
        'activeWalkId',
      ],
    );

    if (firebaseRequestId.isEmpty) {
      _log('STEP 10 FAILED: Firebase Walk ID missing');

      throw Exception(
        'Owner Walk ID is missing in Firebase.',
      );
    }

    _log(
      'STEP 10 OK: firebaseRequestId=$firebaseRequestId',
    );

    // ========================================================
    // 11. VALIDATE FIRESTORE REQUEST ID
    // ========================================================

    _log('STEP 11: Validate Firebase Walk ID');

    if (!RegExp(r'^DW\d{6}$').hasMatch(firebaseRequestId)) {
      _log(
        'STEP 11 FAILED: Invalid Firebase Walk ID',
      );

      throw Exception(
        'Invalid Walk ID in Firebase.',
      );
    }

    _log('STEP 11 OK');

    // ========================================================
    // 12. MATCH REQUEST ID
    // ========================================================

    _log('STEP 12: Compare QR and Firebase Walk ID');

    if (firebaseRequestId != requestId) {
      _log(
        'STEP 12 FAILED: '
        '$firebaseRequestId != $requestId',
      );

      throw Exception(
        'Walk ID verification failed.',
      );
    }

    _log('STEP 12 OK');

    // ========================================================
    // 13. OWNER UID
    // ========================================================

    _log('STEP 13: Read Owner Firebase UID');

    final String ownerUid = _readString(
      connectionData,
      <String>[
        'ownerUid',
        'ownerAuthUid',
        'authUid',
        'firebaseUid',
      ],
    );

    if (ownerUid.isEmpty) {
      _log('STEP 13 FAILED: Owner UID missing');

      throw Exception(
        'Owner Firebase UID is missing.',
      );
    }

    _log('STEP 13 OK');

    // ========================================================
    // 14. SELF CONNECTION
    // ========================================================

    _log('STEP 14: Check Owner/Walker identity');

    if (ownerUid == walkerUid) {
      _log('STEP 14 FAILED: Same account');

      throw Exception(
        'Owner and Walker cannot be the same account.',
      );
    }

    _log('STEP 14 OK');

    // ========================================================
    // 15. OWNER DATA
    // ========================================================

    _log('STEP 15: Read Owner data');

    String ownerName = _firstNonEmpty(
      <String?>[
        connectionData['ownerName']?.toString(),
        qrData['ownerName']?.toString(),
      ],
    );

    if (ownerName.isEmpty) {
      ownerName = 'Owner';
    }

    final String ownerPhone = _firstNonEmpty(
      <String?>[
        connectionData['ownerPhone']?.toString(),
        qrData['ownerPhone']?.toString(),
      ],
    );

    _log('STEP 15 OK');

    // ========================================================
    // 16. DOG DATA
    // ========================================================

    _log('STEP 16: Read Dog data');

    String dogName = _firstNonEmpty(
      <String?>[
        connectionData['dogName']?.toString(),
        qrData['dogName']?.toString(),
      ],
    );

    if (dogName.isEmpty) {
      dogName = 'Dog';
    }

    final String dogBreed = _firstNonEmpty(
      <String?>[
        connectionData['dogBreed']?.toString(),
        qrData['dogBreed']?.toString(),
      ],
    );

    _log('STEP 16 OK');

    // ========================================================
    // 17. EXISTING CONNECTION
    // ========================================================

    _log('STEP 17: Check existing QR connection');

    final bool connected =
        connectionData['connected'] == true;

    final String existingWalkerUid = _readString(
      connectionData,
      <String>['walkerUid'],
    );

    if (connected &&
        existingWalkerUid.isNotEmpty &&
        existingWalkerUid != walkerUid) {
      _log(
        'STEP 17 FAILED: Another Walker connected',
      );

      throw Exception(
        'This Owner QR is already connected to another walker.',
      );
    }

    _log('STEP 17 OK');

    // ========================================================
    // 18. WALKER ACCOUNT READ
    // ========================================================

    _log(
      'STEP 18: READ phoneAccounts/$walkerUid',
    );

    DocumentSnapshot<Map<String, dynamic>>
        walkerAccountSnapshot;

    try {
      walkerAccountSnapshot = await _firestore
          .collection('phoneAccounts')
          .doc(walkerUid)
          .get();

      _log(
        'STEP 18 OK: phoneAccounts READ successful',
      );
    } catch (error) {
      _log(
        'STEP 18 FAILED: phoneAccounts READ',
      );
      _log('ERROR: $error');

      rethrow;
    }

    final Map<String, dynamic>? walkerAccountData =
        walkerAccountSnapshot.data();

    _log(
      'STEP 18 DATA: exists=${walkerAccountSnapshot.exists}',
    );

    // ========================================================
    // 19. WALKER BUSINESS ID
    // ========================================================

    _log('STEP 19: Read Walker Business ID');

    final String walkerId = _firstNonEmpty(
      <String?>[
        walkerAccountData?['walkerId']?.toString(),
        walkerAccountData?['Walker Id']?.toString(),
        walkerAccountData?['Walker ID']?.toString(),
        walkerAccountData?['walkerBusinessId']?.toString(),
        walkerAccountData?['walkerBusinessID']?.toString(),
        walkerAccountData?['businessId']?.toString(),
        walkerAccountData?['Business ID']?.toString(),
      ],
    );

    if (walkerId.isEmpty) {
      _log('STEP 19 FAILED: Walker Business ID missing');

      throw Exception(
        'Walker Business ID not found.',
      );
    }

    _log('STEP 19 OK: walkerId=$walkerId');

    // ========================================================
    // 20. WALKER NAME
    // ========================================================

    _log('STEP 20: Read Walker Name');

    String walkerName = _firstNonEmpty(
      <String?>[
        walkerAccountData?['walkerName']?.toString(),
        walkerAccountData?['name']?.toString(),
        walkerAccountData?['Full Name']?.toString(),
        walkerAccountData?['Name']?.toString(),
        walker.displayName,
      ],
    );

    if (walkerName.isEmpty) {
      walkerName = 'Walker';
    }

    _log('STEP 20 OK: walkerName=$walkerName');

    // ========================================================
    // 21. LIVE SESSION REFERENCE
    // ========================================================

    _log(
      'STEP 21: Prepare liveWalkSessions/$requestId',
    );

    final DocumentReference<Map<String, dynamic>> sessionRef =
        _liveWalkSessions.doc(requestId);

    _log('STEP 21 OK');

    // ========================================================
    // 22. LIVE SESSION READ
    // ========================================================

    _log(
      'STEP 22: READ liveWalkSessions/$requestId',
    );

    DocumentSnapshot<Map<String, dynamic>> existingSession;

    try {
      existingSession = await sessionRef.get();

      _log(
        'STEP 22 OK: liveWalkSessions READ successful',
      );
    } catch (error) {
      _log(
        'STEP 22 FAILED: liveWalkSessions READ',
      );
      _log('ERROR: $error');

      rethrow;
    }

    // ========================================================
    // 23. EXISTING LIVE SESSION
    // ========================================================

    _log('STEP 23: Check existing Live Session');

    if (existingSession.exists) {
      final Map<String, dynamic> existingData =
          existingSession.data() ?? <String, dynamic>{};

      final String existingStatus =
          existingData['status']?.toString().trim().toLowerCase() ??
              '';

      final String existingWalker =
          existingData['walkerUid']?.toString().trim() ?? '';

      if (existingWalker.isNotEmpty &&
          existingWalker != walkerUid) {
        _log(
          'STEP 23 FAILED: Another Walker owns session',
        );

        throw Exception(
          'This Live Walk is already connected to another walker.',
        );
      }

      if (existingStatus != 'completed' &&
          existingStatus != 'cancelled' &&
          existingStatus != 'ended') {
        final String existingWalkerId = _firstNonEmpty(
          <String?>[
            existingData['walkerId']?.toString(),
            walkerId,
          ],
        );

        final String existingWalkerName = _firstNonEmpty(
          <String?>[
            existingData['walkerName']?.toString(),
            walkerName,
          ],
        );

        _log(
          'STEP 23 OK: Existing active session found',
        );

        return <String, dynamic>{
          'ownerId': ownerId,
          'ownerUid': ownerUid,
          'ownerName': ownerName,
          'ownerPhone': ownerPhone,
          'walkerId': existingWalkerId,
          'walkerUid': walkerUid,
          'walkerName': existingWalkerName,
          'requestId': requestId,
          'walkId': requestId,
          'liveSessionId': requestId,
          'sessionId': requestId,
          'dogName': dogName,
          'dogBreed': dogBreed,
          'status': existingStatus.isEmpty
              ? 'READY'
              : existingData['status'],
          'source': 'qr',
          'startedFromQr': true,
          'existingSession': true,
        };
      }
    }

    _log('STEP 23 OK: No active existing session');

    // ========================================================
    // 24. PREPARE BATCH
    // ========================================================

    _log('STEP 24: Prepare Firestore batch');

    final FieldValue serverTimestamp =
        FieldValue.serverTimestamp();

    final WriteBatch batch = _firestore.batch();

    _log('STEP 24 OK');

    // ========================================================
    // 25. QR CONNECTION UPDATE
    // ========================================================

    _log(
      'STEP 25: Prepare UPDATE qr_connections/$ownerId',
    );

    batch.set(
      connectionRef,
      <String, dynamic>{
        'type': 'dojo_owner_qr',
        'version': 2,
        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'requestId': requestId,
        'walkId': requestId,
        'dogName': dogName,
        'dogBreed': dogBreed,
        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,
        'scanned': true,
        'connected': true,
        'liveSessionId': requestId,
        'activeWalkId': requestId,
        'scannedAt': serverTimestamp,
        'connectedAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      },
      SetOptions(merge: true),
    );

    _log('STEP 25 OK: QR update prepared');

    // ========================================================
    // 26. LIVE SESSION CREATE / MERGE
    // ========================================================

    _log(
      'STEP 26: Prepare WRITE liveWalkSessions/$requestId',
    );

    batch.set(
      sessionRef,
      <String, dynamic>{
        'sessionId': requestId,
        'requestId': requestId,
        'walkId': requestId,
        'source': 'qr',
        'startedFromQr': true,
        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,
        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,
        'dogName': dogName,
        'dogBreed': dogBreed,
        'currentLocation': <String, double>{
          'lat': 0.0,
          'lng': 0.0,
        },
        'distanceKm': 0.0,
        'elapsedSeconds': 0,
        'peeCount': 0,
        'poopCount': 0,
        'events': <Map<String, dynamic>>[],
        'routeCoordinates': <Map<String, dynamic>>[],
        'status': 'READY',
        'walkStarted': false,
        'walkEnded': false,
        'trackingStarted': false,
        'trackingEnded': false,
        'startedAt': null,
        'endedAt': null,
        'createdAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      },
      SetOptions(merge: true),
    );

    _log(
      'STEP 26 OK: Live session write prepared',
    );

    // ========================================================
    // 27. COMMIT
    // ========================================================

    _log(
      'STEP 27: COMMIT batch',
    );

    try {
      await batch.commit();

      _log(
        'STEP 27 OK: BATCH COMMIT SUCCESS',
      );
    } catch (error) {
      _log(
        'STEP 27 FAILED: BATCH COMMIT',
      );
      _log('ERROR: $error');

      rethrow;
    }

    // ========================================================
    // 28. RETURN RESULT
    // ========================================================

    _log('STEP 28: Return Live Walk data');

    final Map<String, dynamic> result = <String, dynamic>{
      'ownerId': ownerId,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'walkerId': walkerId,
      'walkerUid': walkerUid,
      'walkerName': walkerName,
      'requestId': requestId,
      'walkId': requestId,
      'liveSessionId': requestId,
      'sessionId': requestId,
      'dogName': dogName,
      'dogBreed': dogBreed,
      'status': 'READY',
      'source': 'qr',
      'startedFromQr': true,
      'existingSession': false,
    };

    _log('STEP 28 OK');
    _log('========== QR WALK SUCCESS ==========');

    return result;
  }

  // ==========================================================
  // DECODE QR
  // ==========================================================

  Map<String, dynamic> _decodeQrPayload(
    String rawData,
  ) {
    try {
      final dynamic decoded = jsonDecode(rawData);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // URI fallback below.
    }

    final Uri? uri = Uri.tryParse(rawData);

    if (uri != null && uri.queryParameters.isNotEmpty) {
      return <String, dynamic>{
        ...uri.queryParameters,
      };
    }

    throw Exception(
      'QR code format is invalid.',
    );
  }

  // ==========================================================
  // READ STRING
  // ==========================================================

  String _readString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final dynamic value = data[key];

      if (value == null) {
        continue;
      }

      final String text = value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ==========================================================
  // FIRST NON EMPTY
  // ==========================================================

  String _firstNonEmpty(
    List<String?> values,
  ) {
    for (final String? value in values) {
      final String text = value?.trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ==========================================================
  // DEBUG LOG
  // ==========================================================

  void _log(String message) {
    debugPrint('[QR WALK] $message');
  }
}
