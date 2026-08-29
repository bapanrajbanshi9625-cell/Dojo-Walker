// File:
// lib/features/qr_walk/services/qr_walk_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  //
  // QR FLOW:
  //
  // QR SCAN
  //    ↓
  // LIVE WALK DIRECTLY
  //
  // No Active Walk screen in QR flow.
  // ==========================================================

  Future<Map<String, dynamic>> processOwnerQr({
    required String rawData,
  }) async {
    // ========================================================
    // 1. VALIDATE QR
    // ========================================================

    final String cleanData = rawData.trim();

    if (cleanData.isEmpty) {
      throw Exception('Invalid QR code.');
    }

    // ========================================================
    // 2. CURRENT WALKER
    // ========================================================

    final User? walker = _auth.currentUser;

    if (walker == null) {
      throw Exception('Walker is not logged in.');
    }

    final String walkerUid = walker.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception('Walker Firebase UID is missing.');
    }

    // ========================================================
    // 3. DECODE QR
    // ========================================================

    final Map<String, dynamic> qrData =
        _decodeQrPayload(cleanData);

    // ========================================================
    // 4. OWNER BUSINESS ID
    // ========================================================

    final String ownerId = _readString(
      qrData,
      <String>[
        'ownerId',
        'ownerBusinessId',
        'ownerBusinessID',
      ],
    );

    if (ownerId.isEmpty) {
      throw Exception(
        'Owner Business ID is missing from QR code.',
      );
    }

    // ========================================================
    // 5. WALK ID
    // ========================================================

    final String qrWalkId = _readString(
      qrData,
      <String>[
        'walkId',
        'qrWalkId',
      ],
    );

    if (qrWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing from QR code.',
      );
    }

    // ========================================================
    // 6. QR CONNECTION
    //
    // qr_connections/{ownerId}
    // ========================================================

    final DocumentReference<Map<String, dynamic>> connectionRef =
        _qrConnections.doc(ownerId);

    final DocumentSnapshot<Map<String, dynamic>>
        connectionSnapshot =
        await connectionRef.get();

    if (!connectionSnapshot.exists) {
      throw Exception(
        'Owner QR session was not found or has expired.',
      );
    }

    final Map<String, dynamic> connectionData =
        connectionSnapshot.data() ??
            <String, dynamic>{};

    // ========================================================
    // 7. VERIFY OWNER ID
    // ========================================================

    final String firebaseOwnerId = _readString(
      connectionData,
      <String>[
        'ownerId',
      ],
    );

    if (firebaseOwnerId.isEmpty) {
      throw Exception(
        'Owner Business ID is missing in Firebase.',
      );
    }

    if (firebaseOwnerId != ownerId) {
      throw Exception(
        'Owner Business ID verification failed.',
      );
    }

    // ========================================================
    // 8. VERIFY WALK ID
    // ========================================================

    final String firebaseWalkId = _readString(
      connectionData,
      <String>[
        'walkId',
      ],
    );

    if (firebaseWalkId.isEmpty) {
      throw Exception(
        'Owner Walk ID is missing in Firebase.',
      );
    }

    if (firebaseWalkId != qrWalkId) {
      throw Exception(
        'Walk ID verification failed.',
      );
    }

    // ========================================================
    // 9. OWNER FIREBASE UID
    // ========================================================

    final String ownerUid = _readString(
      connectionData,
      <String>[
        'ownerUid',
        'ownerAuthUid',
        'authUid',
      ],
    );

    if (ownerUid.isEmpty) {
      throw Exception(
        'Owner Firebase UID is missing.',
      );
    }

    // ========================================================
    // 10. PREVENT SELF CONNECTION
    // ========================================================

    if (ownerUid == walkerUid) {
      throw Exception(
        'Owner and Walker cannot be the same account.',
      );
    }

    // ========================================================
    // 11. EXISTING CONNECTION
    // ========================================================

    final bool connected =
        connectionData['connected'] == true;

    final String existingWalkerUid = _readString(
      connectionData,
      <String>[
        'walkerUid',
      ],
    );

    final String existingLiveSessionId = _readString(
      connectionData,
      <String>[
        'liveSessionId',
      ],
    );

    // ========================================================
    // ANOTHER WALKER
    // ========================================================

    if (connected &&
        existingWalkerUid.isNotEmpty &&
        existingWalkerUid != walkerUid) {
      throw Exception(
        'This Owner QR is already connected to another walker.',
      );
    }

    // ========================================================
    // SAME WALKER / EXISTING SESSION
    // ========================================================

    if (connected &&
        existingWalkerUid == walkerUid &&
        existingLiveSessionId.isNotEmpty) {
      throw Exception(
        'You are already connected to this Live Walk.',
      );
    }

    // ========================================================
    // 12. GET WALKER ACCOUNT
    // ========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        walkerAccountSnapshot =
        await _firestore
            .collection('phoneAccounts')
            .doc(walkerUid)
            .get();

    final Map<String, dynamic>? walkerAccountData =
        walkerAccountSnapshot.data();

    // ========================================================
    // 13. WALKER BUSINESS ID
    // ========================================================

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
      throw Exception(
        'Walker Business ID not found.',
      );
    }

    // ========================================================
    // 14. WALKER NAME
    // ========================================================

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

    // ========================================================
    // 15. OWNER DATA
    // ========================================================

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

    // ========================================================
    // 16. DOG DATA
    // ========================================================

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

    // ========================================================
    // 17. CREATE LIVE SESSION
    // ========================================================

    final DocumentReference<Map<String, dynamic>>
        sessionRef =
        _liveWalkSessions.doc();

    final String liveSessionId = sessionRef.id;

    // ========================================================
    // 18. SERVER TIMESTAMP
    // ========================================================

    final FieldValue serverTimestamp =
        FieldValue.serverTimestamp();

    // ========================================================
    // 19. FIRESTORE BATCH
    // ========================================================

    final WriteBatch batch = _firestore.batch();

    // ========================================================
    // 20. UPDATE QR CONNECTION
    // ========================================================

    batch.set(
      connectionRef,
      <String, dynamic>{
        // ----------------------------------------------------
        // TYPE
        // ----------------------------------------------------

        'type': 'dojo_owner_qr',
        'version': 1,

        // ----------------------------------------------------
        // OWNER
        // ----------------------------------------------------

        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // ----------------------------------------------------
        // WALK
        // ----------------------------------------------------

        'walkId': firebaseWalkId,

        // ----------------------------------------------------
        // DOG
        // ----------------------------------------------------

        'dogName': dogName,
        'dogBreed': dogBreed,

        // ----------------------------------------------------
        // WALKER
        // ----------------------------------------------------

        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,

        // ----------------------------------------------------
        // CONNECTION
        // ----------------------------------------------------

        'scanned': true,
        'connected': true,

        // ----------------------------------------------------
        // LIVE SESSION
        // ----------------------------------------------------

        'liveSessionId': liveSessionId,

        // ----------------------------------------------------
        // TIMESTAMPS
        // ----------------------------------------------------

        'scannedAt': serverTimestamp,
        'connectedAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      },
      SetOptions(merge: true),
    );

    // ========================================================
    // 21. CREATE LIVE WALK SESSION
    //
    // QR FLOW DIRECTLY STARTS LIVE WALK.
    // ========================================================

    batch.set(
      sessionRef,
      <String, dynamic>{
        // ----------------------------------------------------
        // SESSION
        // ----------------------------------------------------

        'sessionId': liveSessionId,
        'walkId': firebaseWalkId,

        // ----------------------------------------------------
        // SOURCE
        // ----------------------------------------------------

        'source': 'qr',
        'startedFromQr': true,

        // ----------------------------------------------------
        // OWNER
        // ----------------------------------------------------

        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // ----------------------------------------------------
        // WALKER
        // ----------------------------------------------------

        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,

        // ----------------------------------------------------
        // DOG
        // ----------------------------------------------------

        'dogName': dogName,
        'dogBreed': dogBreed,

        // ----------------------------------------------------
        // LOCATION
        // ----------------------------------------------------

        'currentLocation': <String, double>{
          'lat': 0.0,
          'lng': 0.0,
        },

        // ----------------------------------------------------
        // STATS
        // ----------------------------------------------------

        'distanceKm': 0.0,
        'elapsedSeconds': 0,
        'steps': 0,
        'peeCount': 0,
        'poopCount': 0,

        // ----------------------------------------------------
        // EVENTS
        // ----------------------------------------------------

        'events': <Map<String, dynamic>>[],

        // ----------------------------------------------------
        // ROUTE
        // ----------------------------------------------------

        'routeCoordinates':
            <Map<String, dynamic>>[],

        // ----------------------------------------------------
        // STATUS
        //
        // QR SCAN = LIVE WALK DIRECTLY
        // ----------------------------------------------------

        'status': 'ACTIVE',
        'walkStarted': true,
        'walkEnded': false,

        // ----------------------------------------------------
        // GPS TRACKING
        //
        // GPS can be started by central tracking service.
        // ----------------------------------------------------

        'trackingStarted': false,
        'trackingEnded': false,

        // ----------------------------------------------------
        // TIMESTAMPS
        // ----------------------------------------------------

        'startedAt': serverTimestamp,
        'endedAt': null,
        'createdAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      },
    );

    // ========================================================
    // 22. COMMIT
    // ========================================================

    await batch.commit();

    // ========================================================
    // 23. RETURN LIVE WALK DATA
    //
    // QR SCREEN MUST NAVIGATE USING liveSessionId.
    // ========================================================

    return <String, dynamic>{
      // ------------------------------------------------------
      // OWNER
      // ------------------------------------------------------

      'ownerId': ownerId,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,

      // ------------------------------------------------------
      // WALKER
      // ------------------------------------------------------

      'walkerId': walkerId,
      'walkerUid': walkerUid,
      'walkerName': walkerName,

      // ------------------------------------------------------
      // WALK
      // ------------------------------------------------------

      'walkId': firebaseWalkId,
      'liveSessionId': liveSessionId,

      // ------------------------------------------------------
      // DOG
      // ------------------------------------------------------

      'dogName': dogName,
      'dogBreed': dogBreed,

      // ------------------------------------------------------
      // LIVE STATUS
      // ------------------------------------------------------

      'status': 'ACTIVE',
      'walkStarted': true,
      'walkEnded': false,

      // ------------------------------------------------------
      // SOURCE
      // ------------------------------------------------------

      'source': 'qr',
      'startedFromQr': true,
    };
  }

  // ==========================================================
  // DECODE QR PAYLOAD
  // ==========================================================

  Map<String, dynamic> _decodeQrPayload(
    String rawData,
  ) {
    // --------------------------------------------------------
    // JSON QR
    // --------------------------------------------------------

    try {
      final dynamic decoded = jsonDecode(rawData);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      // Not JSON.
    }

    // --------------------------------------------------------
    // URL / QUERY PARAMETER QR
    // --------------------------------------------------------

    final Uri? uri = Uri.tryParse(rawData);

    if (uri != null &&
        uri.queryParameters.isNotEmpty) {
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
}
