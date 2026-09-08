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
  // FINAL QR FLOW
  //
  // Scan Owner QR
  //       ↓
  // Read requestId = DW######
  //       ↓
  // Verify Owner
  //       ↓
  // Verify QR Connection
  //       ↓
  // Connect Walker
  //       ↓
  // Create liveWalkSessions/{requestId}
  //       ↓
  // Return data
  //       ↓
  // Scanner opens LiveWalkScreen
  //
  // IMPORTANT:
  // QR scan does NOT start the walk.
  // LiveWalkSessionController / Service starts it later.
  // ==========================================================

  Future<Map<String, dynamic>> processOwnerQr({
    required String rawData,
  }) async {
    // ========================================================
    // 1. VALIDATE RAW QR
    // ========================================================

    final String cleanData =
        rawData.trim();

    if (cleanData.isEmpty) {
      throw Exception(
        'Invalid QR code.',
      );
    }

    // ========================================================
    // 2. CURRENT WALKER
    // ========================================================

    final User? walker =
        _auth.currentUser;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        walker.uid.trim();

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
    // 4. QR TYPE
    // ========================================================

    final String qrType =
        _readString(
      qrData,
      <String>[
        'type',
      ],
    );

    if (qrType.isNotEmpty &&
        qrType != 'dojo_owner_qr') {
      throw Exception(
        'This QR code is not a valid Dojo Owner QR.',
      );
    }

    // ========================================================
    // 5. OWNER BUSINESS ID
    // ========================================================

    final String ownerId =
        _readString(
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
    // 6. CANONICAL WALK / REQUEST ID
    //
    // NEW:
    // requestId = DW000001
    //
    // OLD COMPATIBILITY:
    // walkId / qrWalkId
    // ========================================================

    String requestId =
        _readString(
      qrData,
      <String>[
        'requestId',
        'walkId',
        'qrWalkId',
      ],
    );

    if (requestId.isEmpty) {
      throw Exception(
        'Walk ID is missing from QR code.',
      );
    }

    requestId =
        requestId.trim();

    // ========================================================
    // 7. VALIDATE CANONICAL DW ID
    // ========================================================

    if (!RegExp(
      r'^DW\d{6}$',
    ).hasMatch(requestId)) {
      throw Exception(
        'Invalid Walk ID. Expected DW######.',
      );
    }

    // ========================================================
    // 8. QR CONNECTION
    //
    // qr_connections/{ownerId}
    // ========================================================

    final DocumentReference<
            Map<String, dynamic>>
        connectionRef =
        _qrConnections.doc(ownerId);

    final DocumentSnapshot<
            Map<String, dynamic>>
        connectionSnapshot =
        await connectionRef.get();

    if (!connectionSnapshot.exists) {
      throw Exception(
        'Owner QR session was not found or has expired.',
      );
    }

    final Map<String, dynamic>
        connectionData =
        connectionSnapshot.data() ??
            <String, dynamic>{};

    // ========================================================
    // 9. VERIFY OWNER ID
    // ========================================================

    final String firebaseOwnerId =
        _readString(
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
    // 10. READ CANONICAL FIRESTORE REQUEST ID
    //
    // New document:
    // requestId = DW######
    //
    // Backward compatibility:
    // walkId
    // ========================================================

    final String firebaseRequestId =
        _readString(
      connectionData,
      <String>[
        'requestId',
        'walkId',
        'activeWalkId',
      ],
    );

    if (firebaseRequestId.isEmpty) {
      throw Exception(
        'Owner Walk ID is missing in Firebase.',
      );
    }

    // ========================================================
    // 11. VALIDATE FIRESTORE REQUEST ID
    // ========================================================

    if (!RegExp(
      r'^DW\d{6}$',
    ).hasMatch(firebaseRequestId)) {
      throw Exception(
        'Invalid Walk ID in Firebase.',
      );
    }

    // ========================================================
    // 12. QR ID MUST MATCH FIRESTORE
    // ========================================================

    if (firebaseRequestId != requestId) {
      throw Exception(
        'Walk ID verification failed.',
      );
    }

    // ========================================================
    // 13. OWNER FIREBASE UID
    // ========================================================

    final String ownerUid =
        _readString(
      connectionData,
      <String>[
        'ownerUid',
        'ownerAuthUid',
        'authUid',
        'firebaseUid',
      ],
    );

    if (ownerUid.isEmpty) {
      throw Exception(
        'Owner Firebase UID is missing.',
      );
    }

    // ========================================================
    // 14. PREVENT SELF CONNECTION
    // ========================================================

    if (ownerUid == walkerUid) {
      throw Exception(
        'Owner and Walker cannot be the same account.',
      );
    }

    // ========================================================
    // 15. OWNER DATA
    // ========================================================

    String ownerName =
        _firstNonEmpty(
      <String?>[
        connectionData['ownerName']
            ?.toString(),
        qrData['ownerName']
            ?.toString(),
      ],
    );

    if (ownerName.isEmpty) {
      ownerName = 'Owner';
    }

    final String ownerPhone =
        _firstNonEmpty(
      <String?>[
        connectionData['ownerPhone']
            ?.toString(),
        qrData['ownerPhone']
            ?.toString(),
      ],
    );

    // ========================================================
    // 16. DOG DATA
    // ========================================================

    String dogName =
        _firstNonEmpty(
      <String?>[
        connectionData['dogName']
            ?.toString(),
        qrData['dogName']
            ?.toString(),
      ],
    );

    if (dogName.isEmpty) {
      dogName = 'Dog';
    }

    final String dogBreed =
        _firstNonEmpty(
      <String?>[
        connectionData['dogBreed']
            ?.toString(),
        qrData['dogBreed']
            ?.toString(),
      ],
    );

    // ========================================================
    // 17. EXISTING CONNECTION
    // ========================================================

    final bool connected =
        connectionData['connected'] ==
            true;

    final String existingWalkerUid =
        _readString(
      connectionData,
      <String>[
        'walkerUid',
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
    // 18. WALKER ACCOUNT
    // ========================================================

    final DocumentSnapshot<
            Map<String, dynamic>>
        walkerAccountSnapshot =
        await _firestore
            .collection('phoneAccounts')
            .doc(walkerUid)
            .get();

    final Map<String, dynamic>?
        walkerAccountData =
        walkerAccountSnapshot.data();

    // ========================================================
    // 19. WALKER BUSINESS ID
    // ========================================================

    final String walkerId =
        _firstNonEmpty(
      <String?>[
        walkerAccountData?['walkerId']
            ?.toString(),
        walkerAccountData?['Walker Id']
            ?.toString(),
        walkerAccountData?['Walker ID']
            ?.toString(),
        walkerAccountData?['walkerBusinessId']
            ?.toString(),
        walkerAccountData?['walkerBusinessID']
            ?.toString(),
        walkerAccountData?['businessId']
            ?.toString(),
        walkerAccountData?['Business ID']
            ?.toString(),
      ],
    );

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker Business ID not found.',
      );
    }

    // ========================================================
    // 20. WALKER NAME
    // ========================================================

    String walkerName =
        _firstNonEmpty(
      <String?>[
        walkerAccountData?['walkerName']
            ?.toString(),
        walkerAccountData?['name']
            ?.toString(),
        walkerAccountData?['Full Name']
            ?.toString(),
        walkerAccountData?['Name']
            ?.toString(),
        walker.displayName,
      ],
    );

    if (walkerName.isEmpty) {
      walkerName = 'Walker';
    }

    // ========================================================
    // 21. CANONICAL LIVE SESSION
    //
    // IMPORTANT:
    //
    // liveWalkSessions/{requestId}
    //
    // NOT:
    //
    // liveWalkSessions/{randomFirestoreId}
    // ========================================================

    final DocumentReference<
            Map<String, dynamic>>
        sessionRef =
        _liveWalkSessions.doc(
      requestId,
    );

    final DocumentSnapshot<
            Map<String, dynamic>>
        existingSession =
        await sessionRef.get();

    // ========================================================
    // 22. EXISTING LIVE SESSION
    // ========================================================

    if (existingSession.exists) {
      final Map<String, dynamic>
          existingData =
          existingSession.data() ??
              <String, dynamic>{};

      final String existingStatus =
          existingData['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      final String existingWalker =
          existingData['walkerUid']
                  ?.toString()
                  .trim() ??
              '';

      // --------------------------------------------
      // Another walker owns this session
      // --------------------------------------------

      if (existingWalker.isNotEmpty &&
          existingWalker != walkerUid) {
        throw Exception(
          'This Live Walk is already connected to another walker.',
        );
      }

      // --------------------------------------------
      // Existing active session
      // --------------------------------------------

      if (existingStatus !=
              'completed' &&
          existingStatus !=
              'cancelled' &&
          existingStatus !=
              'ended') {
        final String existingWalkerId =
            _firstNonEmpty(
          <String?>[
            existingData['walkerId']
                ?.toString(),
            walkerId,
          ],
        );

        final String existingWalkerName =
            _firstNonEmpty(
          <String?>[
            existingData['walkerName']
                ?.toString(),
            walkerName,
          ],
        );

        return <String, dynamic>{
          // OWNER
          'ownerId': ownerId,
          'ownerUid': ownerUid,
          'ownerName': ownerName,
          'ownerPhone': ownerPhone,

          // WALKER
          'walkerId':
              existingWalkerId,
          'walkerUid': walkerUid,
          'walkerName':
              existingWalkerName,

          // CANONICAL WALK ID
          'requestId': requestId,
          'walkId': requestId,

          // SESSION
          'liveSessionId':
              requestId,
          'sessionId':
              requestId,

          // DOG
          'dogName': dogName,
          'dogBreed': dogBreed,

          // STATUS
          'status':
              existingStatus.isEmpty
                  ? 'READY'
                  : existingData['status'],

          // SOURCE
          'source': 'qr',
          'startedFromQr': true,
          'existingSession': true,
        };
      }
    }

    // ========================================================
    // 23. SERVER TIMESTAMP
    // ========================================================

    final FieldValue
        serverTimestamp =
        FieldValue.serverTimestamp();

    // ========================================================
    // 24. WRITE BATCH
    // ========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ========================================================
    // 25. UPDATE QR CONNECTION
    // ========================================================

    batch.set(
      connectionRef,
      <String, dynamic>{
        // QR
        'type':
            'dojo_owner_qr',
        'version': 2,

        // OWNER
        'ownerId': ownerId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // CANONICAL WALK
        'requestId':
            requestId,
        'walkId':
            requestId,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // WALKER
        'walkerId':
            walkerId,
        'walkerUid':
            walkerUid,
        'walkerName':
            walkerName,

        // CONNECTION
        'scanned': true,
        'connected': true,

        // SESSION
        'liveSessionId':
            requestId,
        'activeWalkId':
            requestId,

        // TIMESTAMPS
        'scannedAt':
            serverTimestamp,
        'connectedAt':
            serverTimestamp,
        'updatedAt':
            serverTimestamp,
      },
      SetOptions(
        merge: true,
      ),
    );

    // ========================================================
    // 26. CREATE LIVE WALK SESSION
    //
    // DOCUMENT:
    //
    // liveWalkSessions/DW000001
    //
    // STATUS:
    // READY
    //
    // The actual walk starts later.
    // ========================================================

    batch.set(
      sessionRef,
      <String, dynamic>{
        // ====================================================
        // CANONICAL IDs
        // ====================================================

        'sessionId':
            requestId,
        'requestId':
            requestId,
        'walkId':
            requestId,

        // ====================================================
        // SOURCE
        // ====================================================

        'source':
            'qr',
        'startedFromQr':
            true,

        // ====================================================
        // OWNER
        // ====================================================

        'ownerId':
            ownerId,
        'ownerUid':
            ownerUid,
        'ownerName':
            ownerName,
        'ownerPhone':
            ownerPhone,

        // ====================================================
        // WALKER
        // ====================================================

        'walkerId':
            walkerId,
        'walkerUid':
            walkerUid,
        'walkerName':
            walkerName,

        // ====================================================
        // DOG
        // ====================================================

        'dogName':
            dogName,
        'dogBreed':
            dogBreed,

        // ====================================================
        // LOCATION
        // ====================================================

        'currentLocation':
            <String, double>{
          'lat': 0.0,
          'lng': 0.0,
        },

        // ====================================================
        // STATS
        // ====================================================

        'distanceKm':
            0.0,
        'elapsedSeconds':
            0,
        'peeCount':
            0,
        'poopCount':
            0,

        // ====================================================
        // EVENTS
        // ====================================================

        'events':
            <Map<String, dynamic>>[],

        // ====================================================
        // ROUTE
        // ====================================================

        'routeCoordinates':
            <Map<String, dynamic>>[],

        // ====================================================
        // STATUS
        // ====================================================

        'status':
            'READY',
        'walkStarted':
            false,
        'walkEnded':
            false,

        // ====================================================
        // TRACKING
        // ====================================================

        'trackingStarted':
            false,
        'trackingEnded':
            false,

        // ====================================================
        // TIMESTAMPS
        // ====================================================

        'startedAt':
            null,
        'endedAt':
            null,
        'createdAt':
            serverTimestamp,
        'updatedAt':
            serverTimestamp,
      },
      SetOptions(
        merge: true,
      ),
    );

    // ========================================================
    // 27. COMMIT
    // ========================================================

    await batch.commit();

    // ========================================================
    // 28. RETURN RESULT
    //
    // Scanner uses this result to open:
    //
    // LiveWalkScreen(
    //   ownerUid: ...,
    //   ownerName: ...,
    //   requestId: DW######,
    //   dogName: ...,
    //   dogBreed: ...,
    //   ownerPhone: ...,
    // )
    // ========================================================

    return <String, dynamic>{
      // OWNER
      'ownerId':
          ownerId,
      'ownerUid':
          ownerUid,
      'ownerName':
          ownerName,
      'ownerPhone':
          ownerPhone,

      // WALKER
      'walkerId':
          walkerId,
      'walkerUid':
          walkerUid,
      'walkerName':
          walkerName,

      // CANONICAL WALK
      'requestId':
          requestId,
      'walkId':
          requestId,

      // LIVE SESSION
      'liveSessionId':
          requestId,
      'sessionId':
          requestId,

      // DOG
      'dogName':
          dogName,
      'dogBreed':
          dogBreed,

      // STATUS
      'status':
          'READY',

      // SOURCE
      'source':
          'qr',
      'startedFromQr':
          true,
      'existingSession':
          false,
    };
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
      // Continue with URI fallback.
    }

    // ========================================================
    // URI FALLBACK
    // ========================================================

    final Uri? uri =
        Uri.tryParse(rawData);

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
      final dynamic value =
          data[key];

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
