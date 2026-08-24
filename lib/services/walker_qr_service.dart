// File:
// lib/services/walker_qr_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// WALKER QR SERVICE
///
/// Purpose:
/// - Walker द्वारा Owner QR scan करने का नया flow
/// - QR से ownerId + walkId पहचानना
/// - Firestore में active_walk + liveWalkSessions से connection
///
/// IMPORTANT:
/// - Insta Walk / WalkRequestService को touch नहीं करता.
/// - Existing qr_scanner_screen.dart अलग रहेगा.
/// ============================================================

class WalkerQrService {
  WalkerQrService._();

  static final WalkerQrService instance =
      WalkerQrService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _activeWalks =>
          _firestore.collection('active_walk');

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  CollectionReference<Map<String, dynamic>>
      get _qrConnections =>
          _firestore.collection('qr_connections');

  // ============================================================
  // CURRENT WALKER
  // ============================================================

  User get _currentWalker {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    if (user.uid.trim().isEmpty) {
      throw Exception(
        'Walker account is invalid.',
      );
    }

    return user;
  }

  // ============================================================
  // PARSE OWNER QR
  // ============================================================

  WalkerQrData parseOwnerQr(
    String scannedData,
  ) {
    final String rawQr =
        scannedData.trim();

    if (rawQr.isEmpty) {
      throw Exception(
        'QR code is empty.',
      );
    }

    dynamic decoded;

    try {
      decoded = jsonDecode(rawQr);
    } catch (_) {
      throw Exception(
        'Invalid Owner QR Code.',
      );
    }

    if (decoded is! Map) {
      throw Exception(
        'Invalid Owner QR Code.',
      );
    }

    final Map<String, dynamic> qr =
        Map<String, dynamic>.from(
      decoded,
    );

    // ----------------------------------------------------------
    // OWNER ID
    // ----------------------------------------------------------

    final String ownerId =
        _readString(
      qr,
      <String>[
        'ownerId',
        'ownerID',
        'owner_id',
      ],
    );

    // ----------------------------------------------------------
    // OWNER AUTH UID
    // ----------------------------------------------------------

    final String ownerAuthUid =
        _readString(
      qr,
      <String>[
        'ownerAuthUid',
        'ownerUid',
        'ownerUID',
      ],
    );

    // ----------------------------------------------------------
    // OWNER NAME
    // ----------------------------------------------------------

    final String ownerName =
        _readString(
      qr,
      <String>[
        'ownerName',
        'name',
        'fullName',
      ],
    );

    // ----------------------------------------------------------
    // WALK ID
    // ----------------------------------------------------------

    final String walkId =
        _readString(
      qr,
      <String>[
        'walkId',
        'walkID',
        'walk_id',
      ],
    );

    // ----------------------------------------------------------
    // SESSION ID
    // ----------------------------------------------------------

    String sessionId =
        _readString(
      qr,
      <String>[
        'sessionId',
        'liveWalkSessionId',
        'sessionID',
      ],
    );

    if (sessionId.isEmpty &&
        walkId.isNotEmpty) {
      sessionId =
          'session-$walkId';
    }

    // ----------------------------------------------------------
    // DOG
    // ----------------------------------------------------------

    final String dogName =
        _readString(
      qr,
      <String>[
        'dogName',
        'petName',
      ],
    );

    final String dogBreed =
        _readString(
      qr,
      <String>[
        'dogBreed',
        'breed',
      ],
    );

    // ----------------------------------------------------------
    // VALIDATION
    // ----------------------------------------------------------

    if (ownerId.isEmpty) {
      throw Exception(
        'Owner ID is missing from QR.',
      );
    }

    if (walkId.isEmpty) {
      throw Exception(
        'Walk ID is missing from QR.',
      );
    }

    return WalkerQrData(
      ownerId: ownerId,
      ownerAuthUid: ownerAuthUid,
      ownerName:
          ownerName.isEmpty
              ? 'Owner'
              : ownerName,
      walkId: walkId,
      sessionId: sessionId,
      dogName:
          dogName.isEmpty
              ? 'Dog'
              : dogName,
      dogBreed: dogBreed,
    );
  }

  // ============================================================
  // CONNECT SCANNED OWNER
  // ============================================================

  Future<WalkerQrData> connectOwner(
    WalkerQrData qrData,
  ) async {
    final User walker =
        _currentWalker;

    final String walkerUid =
        walker.uid.trim();

    // ----------------------------------------------------------
    // READ WALKER ID
    // ----------------------------------------------------------

    String walkerId =
        _readWalkerId(walker);

    // ----------------------------------------------------------
    // VERIFY / READ ACTIVE WALK
    // ----------------------------------------------------------

    final DocumentReference<
            Map<String, dynamic>>
        activeRef =
        _activeWalks.doc(
      qrData.walkId,
    );

    final DocumentSnapshot<
            Map<String, dynamic>>
        activeSnapshot =
        await activeRef.get();

    Map<String, dynamic> activeData =
        <String, dynamic>{};

    if (activeSnapshot.exists) {
      activeData =
          activeSnapshot.data() ??
              <String, dynamic>{};

      final String existingOwner =
          _string(
        activeData['ownerId'],
      );

      final String existingWalker =
          _string(
        activeData['walkerUid'],
      );

      final String status =
          _string(
        activeData['status'],
      ).toLowerCase();

      // --------------------------------------------------------
      // ANOTHER WALKER ALREADY CONNECTED
      // --------------------------------------------------------

      if (status == 'active' &&
          existingWalker.isNotEmpty &&
          existingWalker != walkerUid) {
        throw Exception(
          'This walk is already connected to another walker.',
        );
      }

      // --------------------------------------------------------
      // OWNER MISMATCH
      // --------------------------------------------------------

      if (existingOwner.isNotEmpty &&
          existingOwner != qrData.ownerId) {
        throw Exception(
          'Owner does not match this walk.',
        );
      }

      // --------------------------------------------------------
      // SAME WALKER ALREADY CONNECTED
      // --------------------------------------------------------

      if (status == 'active' &&
          existingWalker == walkerUid) {
        return qrData;
      }
    }

    // ----------------------------------------------------------
    // CREATE SESSION ID
    // ----------------------------------------------------------

    final String sessionId =
        qrData.sessionId.isNotEmpty
            ? qrData.sessionId
            : 'session-${qrData.walkId}';

    final DocumentReference<
            Map<String, dynamic>>
        sessionRef =
        _liveWalkSessions.doc(
      sessionId,
    );

    // ----------------------------------------------------------
    // BATCH
    // ----------------------------------------------------------

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // ACTIVE WALK
    // ==========================================================

    batch.set(
      activeRef,
      {
        'walkId': qrData.walkId,

        // OWNER
        'ownerId': qrData.ownerId,
        'ownerAuthUid':
            qrData.ownerAuthUid,
        'ownerUid':
            qrData.ownerAuthUid,

        'ownerName':
            qrData.ownerName,

        // WALKER
        'walkerId': walkerId,
        'walkerUid': walkerUid,

        'walkerName':
            _walkerName(walker),

        'walkerPhone':
            _walkerPhone(walker),

        // DOG
        'dogName':
            qrData.dogName,

        'dogBreed':
            qrData.dogBreed,

        // CONNECTION
        'connectionType': 'qr',
        'connectedBy':
            walkerUid,

        'connectionStatus':
            'connected',

        // STATUS
        'status': 'active',
        'isLive': true,

        // SESSION
        'activeWalkId':
            qrData.walkId,

        'liveWalkSessionId':
            sessionId,

        // LOCATION
        'currentLat': 0.0,
        'currentLng': 0.0,

        // METRICS
        'distanceKm': 0.0,
        'elapsedSeconds': 0,
        'steps': 0,

        'peeCount': 0,
        'poopCount': 0,

        // TIME
        'startedAt':
            FieldValue.serverTimestamp(),

        'connectedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // LIVE WALK SESSION
    // ==========================================================

    batch.set(
      sessionRef,
      {
        'id': sessionId,

        'walkId':
            qrData.walkId,

        // OWNER
        'ownerId':
            qrData.ownerId,

        'ownerAuthUid':
            qrData.ownerAuthUid,

        'ownerUid':
            qrData.ownerAuthUid,

        'ownerName':
            qrData.ownerName,

        // WALKER
        'walkerId':
            walkerId,

        'walkerUid':
            walkerUid,

        'walkerName':
            _walkerName(walker),

        // DOG
        'dogName':
            qrData.dogName,

        'dogBreed':
            qrData.dogBreed,

        // LOCATION
        'currentLocation': {
          'lat': 0.0,
          'lng': 0.0,
        },

        // METRICS
        'distanceKm': 0.0,

        'elapsedSeconds': 0,

        'steps': 0,

        'peeCount': 0,

        'poopCount': 0,

        // ARRAYS
        'events':
            <Map<String, dynamic>>[],

        'routeCoordinates':
            <Map<String, dynamic>>[],

        // CONNECTION
        'connectionType': 'qr',

        'connectionStatus':
            'connected',

        // STATUS
        'status': 'ACTIVE',

        'isLive': true,

        // TIME
        'startedAt':
            FieldValue.serverTimestamp(),

        'connectedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // QR CONNECTION
    // ==========================================================

    final DocumentReference<
            Map<String, dynamic>>
        qrRef =
        _qrConnections.doc(
      qrData.ownerId,
    );

    batch.set(
      qrRef,
      {
        'ownerId':
            qrData.ownerId,

        'ownerAuthUid':
            qrData.ownerAuthUid,

        'walkerId':
            walkerId,

        'walkerUid':
            walkerUid,

        'walkerName':
            _walkerName(walker),

        'walkId':
            qrData.walkId,

        'activeWalkId':
            qrData.walkId,

        'liveWalkSessionId':
            sessionId,

        'connectionType':
            'qr',

        'scanned':
            true,

        'connected':
            true,

        'connectedAt':
            FieldValue.serverTimestamp(),

        'scannedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await batch.commit();

    return qrData.copyWith(
      sessionId: sessionId,
    );
  }

  // ============================================================
  // SCAN DATA + CONNECT
  // ============================================================

  Future<WalkerQrData> scanDataAndConnect(
    String scannedData,
  ) async {
    final WalkerQrData qrData =
        parseOwnerQr(
      scannedData,
    );

    return connectOwner(
      qrData,
    );
  }

  // ============================================================
  // RESET QR CONNECTION
  // ============================================================

  Future<void> resetOwnerQrConnection({
    required String ownerId,
    required String walkId,
  }) async {
    if (ownerId.trim().isEmpty) {
      return;
    }

    await _qrConnections
        .doc(ownerId.trim())
        .set(
      {
        'scanned': false,
        'connected': false,

        'walkerId': null,
        'walkerUid': null,
        'walkerName': null,

        'activeWalkId': null,
        'liveWalkSessionId': null,

        'lastCompletedWalkId':
            walkId,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // WALKER ID
  // ============================================================

  String _readWalkerId(
    User walker,
  ) {
    // Firebase Auth UID हमेशा available है.
    //
    // अगर आगे Firestore में अलग walkerId चाहिए,
    // तो इसे बाद में profile document से resolve
    // किया जा सकता है.
    return walker.uid.trim();
  }

  // ============================================================
  // WALKER NAME
  // ============================================================

  String _walkerName(
    User walker,
  ) {
    final String name =
        walker.displayName
                ?.trim() ??
            '';

    if (name.isNotEmpty) {
      return name;
    }

    return 'Walker';
  }

  // ============================================================
  // WALKER PHONE
  // ============================================================

  String _walkerPhone(
    User walker,
  ) {
    final String phone =
        walker.phoneNumber
                ?.trim() ??
            '';

    return phone;
  }

  // ============================================================
  // READ STRING
  // ============================================================

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

      final String result =
          value.toString().trim();

      if (result.isNotEmpty) {
        return result;
      }
    }

    return '';
  }

  // ============================================================
  // STRING
  // ============================================================

  String _string(
    dynamic value,
  ) {
    return value
            ?.toString()
            .trim() ??
        '';
  }
}

/// ============================================================
/// WALKER QR DATA
/// ============================================================

class WalkerQrData {
  final String ownerId;
  final String ownerAuthUid;
  final String ownerName;

  final String walkId;
  final String sessionId;

  final String dogName;
  final String dogBreed;

  const WalkerQrData({
    required this.ownerId,
    required this.ownerAuthUid,
    required this.ownerName,
    required this.walkId,
    required this.sessionId,
    required this.dogName,
    required this.dogBreed,
  });

  WalkerQrData copyWith({
    String? ownerId,
    String? ownerAuthUid,
    String? ownerName,
    String? walkId,
    String? sessionId,
    String? dogName,
    String? dogBreed,
  }) {
    return WalkerQrData(
      ownerId:
          ownerId ?? this.ownerId,
      ownerAuthUid:
          ownerAuthUid ??
              this.ownerAuthUid,
      ownerName:
          ownerName ?? this.ownerName,
      walkId:
          walkId ?? this.walkId,
      sessionId:
          sessionId ?? this.sessionId,
      dogName:
          dogName ?? this.dogName,
      dogBreed:
          dogBreed ?? this.dogBreed,
    );
  }
}
