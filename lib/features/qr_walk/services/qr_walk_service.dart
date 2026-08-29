// File:
// lib/features/qr_walk/services/qr_walk_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QrWalkService {
  QrWalkService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth =
            auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  CollectionReference<Map<String, dynamic>>
      get _qrConnections =>
          _firestore.collection('qr_connections');

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  // ==========================================================
  // PROCESS OWNER QR
  //
  // QR FLOW:
  //
  // Scan QR
  //    ↓
  // Verify Owner
  //    ↓
  // Verify Walk
  //    ↓
  // Connect Walker
  //    ↓
  // Create Live Session
  //    ↓
  // Open Live Walk Screen
  //
  // IMPORTANT:
  // QR scan itself does NOT officially start the walk.
  // LiveWalkSessionService.startWalk() will do that.
  // ==========================================================

  Future<Map<String, dynamic>> processOwnerQr({
    required String rawData,
  }) async {
    // ========================================================
    // 1. VALIDATE QR
    // ========================================================

    final String cleanData = rawData.trim();

    if (cleanData.isEmpty) {
      throw Exception(
        'Invalid QR code.',
      );
    }

    // ========================================================
    // 2. CURRENT WALKER
    // ========================================================

    final User? walker = _auth.currentUser;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid = walker.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker Firebase UID is missing.',
      );
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
    // 6. FIND OWNER QR CONNECTION
    //
    // qr_connections/{ownerId}
    // ========================================================

    final DocumentReference<Map<String, dynamic>>
        connectionRef =
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

    final String existingWalkerUid =
        _readString(
      connectionData,
      <String>[
        'walkerUid',
      ],
    );

    final String existingLiveSessionId =
        _readString(
      connectionData,
      <String>[
        'liveSessionId',
      ],
    );

    // ========================================================
    // ANOTHER WALKER ALREADY CONNECTED
    // ========================================================

    if (connected &&
        existingWalkerUid.isNotEmpty &&
        existingWalkerUid != walkerUid) {
      throw Exception(
        'This Owner QR is already connected to another walker.',
      );
    }

    // ========================================================
    // SAME WALKER + EXISTING SESSION
    //
    // Return existing session instead of creating duplicate.
    // ========================================================

    if (connected &&
        existingWalkerUid == walkerUid &&
        existingLiveSessionId.isNotEmpty) {
      final DocumentSnapshot<Map<String, dynamic>>
          existingSession =
          await _liveWalkSessions
              .doc(existingLiveSessionId)
              .get();

      if (existingSession.exists) {
        final Map<String, dynamic> existingData =
            existingSession.data() ??
                <String, dynamic>{};

        final String existingStatus =
            existingData['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (existingStatus != 'completed' &&
            existingStatus != 'cancelled' &&
            existingStatus != 'ended') {
          return <String, dynamic>{
            'ownerId': ownerId,
            'ownerUid': ownerUid,
            'ownerName': _readOwnerName(
              connectionData,
              qrData,
            ),
            'ownerPhone': _readOwnerPhone(
              connectionData,
              qrData,
            ),
            'walkerId': _readWalkerId(
              walkerUid,
              walker,
            ),
            'walkerUid': walkerUid,
            'walkerName': _readWalkerName(
              walkerUid,
              walker,
            ),
            'walkId': firebaseWalkId,
            'liveSessionId':
                existingLiveSessionId,
            'dogName': _readDogName(
              connectionData,
              qrData,
            ),
            'dogBreed': _readDogBreed(
              connectionData,
              qrData,
            ),
            'status': existingStatus.isEmpty
                ? 'READY'
                : existingData['status'],
            'source': 'qr',
            'startedFromQr': true,
            'existingSession': true,
          };
        }
      }
    }

    // ========================================================
    // 12. WALKER ACCOUNT
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
        walkerAccountData?['walkerBusinessId']
            ?.toString(),
        walkerAccountData?['walkerBusinessID']
            ?.toString(),
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

    final FieldValue serverTimestamp =
        FieldValue.serverTimestamp();

    // ========================================================
    // 18. BATCH
    // ========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ========================================================
    // 19. UPDATE QR CONNECTION
    // ========================================================

    batch.set(
      connectionRef,
      <String, dynamic>{
        'type': 'dojo_owner_qr',
        'version': 1,

        // OWNER
        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // WALK
        'walkId': firebaseWalkId,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // WALKER
        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,

        // CONNECTION
        'scanned': true,
        'connected': true,

        // LIVE SESSION
        'liveSessionId': liveSessionId,

        // TIMESTAMPS
        'scannedAt': serverTimestamp,
        'connectedAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      },
      SetOptions(merge: true),
    );

    // ========================================================
    // 20. CREATE LIVE WALK SESSION
    //
    // IMPORTANT:
    // status = READY
    // walkStarted = false
    //
    // QR creates the session.
    // Actual walk start happens later.
    // ========================================================

    batch.set(
      sessionRef,
      <String, dynamic>{
        // SESSION
        'sessionId': liveSessionId,
        'walkId': firebaseWalkId,

        // SOURCE
        'source': 'qr',
        'startedFromQr': true,

        // OWNER
        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // WALKER
        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // LOCATION
        'currentLocation': <String, double>{
          'lat': 0.0,
          'lng': 0.0,
        },

        // STATS
        'distanceKm': 0.0,
        'elapsedSeconds': 0,
        'peeCount': 0,
        'poopCount': 0,

        // EVENTS
        'events': <Map<String, dynamic>>[],

        // ROUTE
        'routeCoordinates':
            <Map<String, dynamic>>[],

        // STATUS
        'status': 'READY',
        'walkStarted': false,
        'walkEnded': false,

        // TRACKING
        'trackingStarted': false,
        'trackingEnded': false,

        // TIMESTAMPS
        'startedAt': null,
        'endedAt': null,
        'createdAt': serverTimestamp,
        'updatedAt': serverTimestamp,
      },
    );

    // ========================================================
    // 21. COMMIT
    // ========================================================

    await batch.commit();

    // ========================================================
    // 22. RETURN RESULT
    // ========================================================

    return <String, dynamic>{
      // OWNER
      'ownerId': ownerId,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,

      // WALKER
      'walkerId': walkerId,
      'walkerUid': walkerUid,
      'walkerName': walkerName,

      // WALK
      'walkId': firebaseWalkId,
      'liveSessionId': liveSessionId,

      // DOG
      'dogName': dogName,
      'dogBreed': dogBreed,

      // STATUS
      'status': 'READY',

      // SOURCE
      'source': 'qr',
      'startedFromQr': true,
      'existingSession': false,
    };
  }

  // ==========================================================
  // OWNER NAME
  // ==========================================================

  String _readOwnerName(
    Map<String, dynamic> connectionData,
    Map<String, dynamic> qrData,
  ) {
    final String value = _firstNonEmpty(
      <String?>[
        connectionData['ownerName']?.toString(),
        qrData['ownerName']?.toString(),
      ],
    );

    return value.isEmpty ? 'Owner' : value;
  }

  // ==========================================================
  // OWNER PHONE
  // ==========================================================

  String _readOwnerPhone(
    Map<String, dynamic> connectionData,
    Map<String, dynamic> qrData,
  ) {
    return _firstNonEmpty(
      <String?>[
        connectionData['ownerPhone']?.toString(),
        qrData['ownerPhone']?.toString(),
      ],
    );
  }

  // ==========================================================
  // DOG NAME
  // ==========================================================

  String _readDogName(
    Map<String, dynamic> connectionData,
    Map<String, dynamic> qrData,
  ) {
    final String value = _firstNonEmpty(
      <String?>[
        connectionData['dogName']?.toString(),
        qrData['dogName']?.toString(),
      ],
    );

    return value.isEmpty ? 'Dog' : value;
  }

  // ==========================================================
  // DOG BREED
  // ==========================================================

  String _readDogBreed(
    Map<String, dynamic> connectionData,
    Map<String, dynamic> qrData,
  ) {
    return _firstNonEmpty(
      <String?>[
        connectionData['dogBreed']?.toString(),
        qrData['dogBreed']?.toString(),
      ],
    );
  }

  // ==========================================================
  // WALKER ID
  // ==========================================================

  String _readWalkerId(
    String walkerUid,
    User walker,
  ) {
    // This helper is only used when an existing session
    // already contains the walker information.
    //
    // The actual new-session path gets the business ID
    // from phoneAccounts.
    return walkerUid;
  }

  // ==========================================================
  // WALKER NAME
  // ==========================================================

  String _readWalkerName(
    String walkerUid,
    User walker,
  ) {
    final String name =
        walker.displayName?.trim() ?? '';

    return name.isEmpty ? 'Walker' : name;
  }

  // ==========================================================
  // DECODE QR PAYLOAD
  // ==========================================================

  Map<String, dynamic> _decodeQrPayload(
    String rawData,
  ) {
    try {
      final dynamic decoded =
          jsonDecode(rawData);

      if (decoded is Map) {
        return Map<String, dynamic>.from(
          decoded,
        );
      }
    } catch (_) {
      // QR may not be JSON.
    }

    // ========================================================
    // URI FALLBACK
    // ========================================================

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

      final String text =
          value.toString().trim();

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
      final String text =
          value?.trim() ?? '';

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
  }
}
