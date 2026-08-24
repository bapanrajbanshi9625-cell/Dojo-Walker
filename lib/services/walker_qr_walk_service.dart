// File:
// lib/services/walker_qr_walk_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/walks/screens/live_walk_screen.dart';
import '../screens/qr_scanner_screen.dart';

/// ============================================================
/// WALKER QR WALK SERVICE
///
/// QR WALK ONLY.
///
/// IMPORTANT:
/// This service is separate from:
/// - walker_walk_service.dart
/// - walk_request_service.dart
///
/// Insta Walk / Normal Walk Request flow is NOT changed here.
/// ============================================================

class WalkerQrWalkService {
  WalkerQrWalkService._();

  static final WalkerQrWalkService instance =
      WalkerQrWalkService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // FIRESTORE COLLECTIONS
  // ============================================================

  static CollectionReference<Map<String, dynamic>>
      get _activeWalks {
    return _firestore.collection('active_walks');
  }

  static CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions {
    return _firestore.collection('liveWalkSessions');
  }

  static CollectionReference<Map<String, dynamic>>
      get _qrConnections {
    return _firestore.collection('qr_connections');
  }

  static CollectionReference<Map<String, dynamic>>
      get _walkHistory {
    return _firestore.collection('walk_history');
  }

  // ============================================================
  // SCAN OWNER QR
  // ============================================================

  static Future<WalkerQrWalkData?> scanOwnerQr(
    BuildContext context,
  ) async {
    final String? scannedData =
        await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(),
      ),
    );

    if (!context.mounted ||
        scannedData == null ||
        scannedData.trim().isEmpty) {
      return null;
    }

    try {
      final String rawQr =
          scannedData.trim();

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
          Map<String, dynamic>.from(decoded);

      // --------------------------------------------------------
      // WALKER LOGIN
      // --------------------------------------------------------

      final User? walker =
          _auth.currentUser;

      if (walker == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      if (walker.uid.trim().isEmpty) {
        throw Exception(
          'Walker account is invalid.',
        );
      }

      // --------------------------------------------------------
      // READ QR DATA
      // --------------------------------------------------------

      final String ownerId =
          _readString(
        qr,
        const [
          'ownerId',
          'ownerID',
        ],
      );

      final String ownerAuthUid =
          _readString(
        qr,
        const [
          'ownerAuthUid',
          'ownerUid',
          'ownerUID',
        ],
      );

      final String ownerName =
          _readString(
        qr,
        const [
          'ownerName',
          'name',
        ],
      );

      final String ownerPhone =
          _readString(
        qr,
        const [
          'ownerPhone',
          'phone',
          'mobile',
        ],
      );

      final String walkId =
          _readString(
        qr,
        const [
          'walkId',
          'walkID',
          'id',
        ],
      );

      final String dogName =
          _readString(
        qr,
        const [
          'dogName',
          'dog',
        ],
      );

      final String dogBreed =
          _readString(
        qr,
        const [
          'dogBreed',
          'breed',
        ],
      );

      // --------------------------------------------------------
      // VALIDATE
      // --------------------------------------------------------

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

      return WalkerQrWalkData(
        ownerId: ownerId,
        ownerAuthUid: ownerAuthUid,
        ownerName:
            ownerName.isEmpty
                ? 'Owner'
                : ownerName,
        ownerPhone:
            ownerPhone.isEmpty
                ? null
                : ownerPhone,
        walkId: walkId,
        dogName:
            dogName.isEmpty
                ? 'Dog'
                : dogName,
        dogBreed: dogBreed,
      );
    } catch (e) {
      if (!context.mounted) {
        return null;
      }

      final String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not read Owner QR: $message',
            ),
          ),
        );

      return null;
    }
  }

  // ============================================================
  // CONNECT QR WALK
  // ============================================================

  static Future<String> connectWithOwner(
    WalkerQrWalkData walk,
  ) async {
    final User? walker =
        _auth.currentUser;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        walker.uid.trim();

    final String ownerId =
        walk.ownerId.trim();

    final String walkId =
        walk.walkId.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker account is invalid.',
      );
    }

    if (ownerId.isEmpty) {
      throw Exception(
        'Owner ID is missing.',
      );
    }

    if (walkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ==========================================================
    // ACTIVE WALK
    // ==========================================================

    final DocumentReference<
        Map<String, dynamic>> activeRef =
        _activeWalks.doc(walkId);

    final DocumentSnapshot<
        Map<String, dynamic>> existing =
        await activeRef.get();

    if (existing.exists) {
      final Map<String, dynamic> data =
          existing.data() ??
              <String, dynamic>{};

      final String status =
          _stringValue(data['status']);

      final String existingWalker =
          _stringValue(
        data['walkerUid'],
      );

      final String existingOwner =
          _stringValue(
        data['ownerId'],
      );

      if (status == 'active' &&
          existingWalker == walkerUid &&
          existingOwner == ownerId) {
        return walkId;
      }

      if (status == 'active') {
        throw Exception(
          'This Walk is already active.',
        );
      }
    }

    // ==========================================================
    // WALKER DETAILS
    // ==========================================================

    final String walkerName =
        walker.displayName
                    ?.trim()
                    .isNotEmpty ==
                true
            ? walker.displayName!.trim()
            : 'Walker';

    final String walkerPhone =
        walker.phoneNumber
                    ?.trim()
                    .isNotEmpty ==
                true
            ? walker.phoneNumber!.trim()
            : '';

    // ==========================================================
    // SESSION
    // ==========================================================

    final String sessionId =
        'session-$walkId';

    final DocumentReference<
        Map<String, dynamic>> sessionRef =
        _liveWalkSessions.doc(sessionId);

    // ==========================================================
    // BATCH
    // ==========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // active_walks/{walkId}
    // ==========================================================

    batch.set(
      activeRef,
      {
        'walkId': walkId,

        // OWNER
        'ownerId': ownerId,
        'ownerAuthUid':
            walk.ownerAuthUid,
        'ownerUid':
            walk.ownerAuthUid,

        'ownerName':
            walk.ownerName,
        'ownerPhone':
            walk.ownerPhone ?? '',

        // WALKER
        'walkerUid':
            walkerUid,
        'walkerId':
            walkerUid,
        'walkerName':
            walkerName,
        'walkerPhone':
            walkerPhone,

        // DOG
        'dogName':
            walk.dogName,
        'dogBreed':
            walk.dogBreed,

        // QR
        'connectionType':
            'qr',
        'connectedBy':
            walkerUid,

        'ownerScanned':
            false,
        'walkerScanned':
            true,

        'scannedAt':
            FieldValue.serverTimestamp(),

        'connectedAt':
            FieldValue.serverTimestamp(),

        // STATUS
        'status':
            'active',
        'connectionStatus':
            'connected',
        'isLive':
            true,

        // SESSION
        'activeWalkId':
            walkId,
        'liveWalkSessionId':
            sessionId,

        // TIME
        'startedAt':
            FieldValue.serverTimestamp(),
        'endedAt':
            null,

        // LOCATION
        'currentLat':
            0.0,
        'currentLng':
            0.0,

        'walkerLocation':
            null,
        'ownerLocation':
            null,

        'walkerLocationUpdatedAt':
            null,
        'ownerLocationUpdatedAt':
            null,

        // STATS
        'distanceKm':
            0.0,
        'elapsedSeconds':
            0,
        'steps':
            0,

        'peeCount':
            0,
        'poopCount':
            0,

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // liveWalkSessions/{sessionId}
    // ==========================================================

    batch.set(
      sessionRef,
      {
        'id':
            sessionId,
        'sessionId':
            sessionId,
        'walkId':
            walkId,

        // OWNER
        'ownerId':
            ownerId,
        'ownerAuthUid':
            walk.ownerAuthUid,
        'ownerUid':
            walk.ownerAuthUid,

        'ownerName':
            walk.ownerName,
        'ownerPhone':
            walk.ownerPhone ?? '',

        // WALKER
        'walkerUid':
            walkerUid,
        'walkerId':
            walkerUid,
        'walkerName':
            walkerName,
        'walkerPhone':
            walkerPhone,

        // DOG
        'dogName':
            walk.dogName,
        'dogBreed':
            walk.dogBreed,

        // TYPE
        'connectionType':
            'qr',

        // LOCATION
        'currentLocation': {
          'lat': 0.0,
          'lng': 0.0,
        },

        // STATS
        'distanceKm':
            0.0,
        'elapsedSeconds':
            0,
        'steps':
            0,

        'peeCount':
            0,
        'poopCount':
            0,

        // EVENTS
        'events':
            <Map<String, dynamic>>[],

        // ROUTE
        'routeCoordinates':
            <Map<String, dynamic>>[],

        // STATUS
        'status':
            'ACTIVE',

        'startedAt':
            FieldValue.serverTimestamp(),
        'endedAt':
            null,

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

    final QuerySnapshot<
        Map<String, dynamic>> qrResult =
        await _qrConnections
            .where(
              'ownerId',
              isEqualTo: ownerId,
            )
            .limit(1)
            .get();

    if (qrResult.docs.isNotEmpty) {
      batch.set(
        qrResult.docs.first.reference,
        {
          'ownerId':
              ownerId,

          'walkerId':
              walkerUid,
          'walkerUid':
              walkerUid,
          'walkerName':
              walkerName,

          'walkId':
              walkId,
          'activeWalkId':
              walkId,
          'liveWalkSessionId':
              sessionId,

          'scanned':
              true,
          'connected':
              true,

          'connectionType':
              'qr',

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
    }

    await batch.commit();

    return walkId;
  }

  // ============================================================
  // SCAN + CONNECT
  // ============================================================

  static Future<String?> scanAndConnect(
    BuildContext context,
  ) async {
    final WalkerQrWalkData? walk =
        await scanOwnerQr(context);

    if (walk == null) {
      return null;
    }

    try {
      final String walkId =
          await connectWithOwner(walk);

      if (!context.mounted) {
        return walkId;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Owner connected successfully.',
            ),
          ),
        );

      return walkId;
    } catch (e) {
      if (!context.mounted) {
        return null;
      }

      final String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not connect: $message',
            ),
          ),
        );

      return null;
    }
  }

  // ============================================================
  // SCAN + CONNECT + OPEN LIVE WALK
  // ============================================================

  static Future<void>
      scanConnectAndOpenLiveWalk(
    BuildContext context,
  ) async {
    final WalkerQrWalkData? walk =
        await scanOwnerQr(context);

    if (walk == null) {
      return;
    }

    try {
      await connectWithOwner(walk);

      if (!context.mounted) {
        return;
      }

      await openLiveWalk(
        context,
        walk,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      final String message =
          e.toString().replaceFirst(
                'Exception: ',
                '',
              );

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not start Live Walk: $message',
            ),
          ),
        );
    }
  }

  // ============================================================
  // OPEN LIVE WALK
  // ============================================================

  static Future<void> openLiveWalk(
    BuildContext context,
    WalkerQrWalkData walk,
  ) async {
    final User? walker =
        _auth.currentUser;

    if (walker == null) {
      _showError(
        context,
        'Walker is not logged in.',
      );
      return;
    }

    if (walk.ownerId.trim().isEmpty) {
      _showError(
        context,
        'Owner ID is missing.',
      );
      return;
    }

    if (walk.walkId.trim().isEmpty) {
      _showError(
        context,
        'Walk ID is missing.',
      );
      return;
    }

    if (!context.mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveWalkScreen(
          ownerUid:
              walk.ownerAuthUid.isNotEmpty
                  ? walk.ownerAuthUid
                  : walk.ownerId,
          ownerName:
              walk.ownerName,
          walkId:
              walk.walkId,
          dogName:
              walk.dogName,
          dogBreed:
              walk.dogBreed,
          ownerPhone:
              walk.ownerPhone,
          sessionId:
              'session-${walk.walkId}',
        ),
      ),
    );
  }

  // ============================================================
  // GET MY ACTIVE QR WALK
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>?>
      getMyActiveWalk() async {
    final User? walker =
        _auth.currentUser;

    if (walker == null) {
      return null;
    }

    final QuerySnapshot<
        Map<String, dynamic>> result =
        await _activeWalks
            .where(
              'walkerUid',
              isEqualTo: walker.uid,
            )
            .where(
              'status',
              isEqualTo: 'active',
            )
            .limit(1)
            .get();

    if (result.docs.isEmpty) {
      return null;
    }

    return result.docs.first;
  }

  // ============================================================
  // WATCH ACTIVE QR WALK
  // ============================================================

  static Stream<
      DocumentSnapshot<Map<String, dynamic>>>
      watchWalk(
    String walkId,
  ) {
    return _activeWalks
        .doc(walkId)
        .snapshots();
  }

  // ============================================================
  // WATCH LIVE SESSION
  // ============================================================

  static Stream<
      DocumentSnapshot<Map<String, dynamic>>>
      watchLiveSession(
    String walkId,
  ) {
    return _liveWalkSessions
        .doc('session-$walkId')
        .snapshots();
  }

  // ============================================================
  // UPDATE WALKER LOCATION
  // ============================================================

  static Future<void> updateWalkerLocation({
    required String walkId,
    required double latitude,
    required double longitude,
  }) async {
    final User? walker =
        _auth.currentUser;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    if (walkId.trim().isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    if (!_validCoordinate(
      latitude,
      longitude,
    )) {
      return;
    }

    final String sessionId =
        'session-$walkId';

    await Future.wait([
      _activeWalks
          .doc(walkId)
          .set(
        {
          'currentLat':
              latitude,
          'currentLng':
              longitude,

          'walkerLocation': {
            'latitude':
                latitude,
            'longitude':
                longitude,
          },

          'walkerLocationUpdatedAt':
              FieldValue.serverTimestamp(),

          'lastUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      ),
      _liveWalkSessions
          .doc(sessionId)
          .set(
        {
          'currentLocation': {
            'lat':
                latitude,
            'lng':
                longitude,
          },

          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      ),
    ]);
  }

  // ============================================================
  // COMPLETE QR WALK
  // ============================================================

  static Future<void> completeWalk({
    required String walkId,
  }) async {
    final User? walker =
        _auth.currentUser;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    if (walkId.trim().isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<
        Map<String, dynamic>> activeRef =
        _activeWalks.doc(walkId);

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await activeRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Active walk not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    final String sessionId =
        _stringValue(
      data['liveWalkSessionId'],
    ).isNotEmpty
            ? _stringValue(
                data['liveWalkSessionId'],
              )
            : 'session-$walkId';

    // ==========================================================
    // SAVE HISTORY
    // ==========================================================

    await _walkHistory
        .doc(walkId)
        .set(
      {
        ...data,

        'status':
            'completed',
        'isLive':
            false,
        'connectionStatus':
            'completed',

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walker.uid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // COMPLETE ACTIVE WALK
    // ==========================================================

    await activeRef.set(
      {
        'status':
            'completed',
        'isLive':
            false,
        'connectionStatus':
            'completed',

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walker.uid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // COMPLETE SESSION
    // ==========================================================

    await _liveWalkSessions
        .doc(sessionId)
        .set(
      {
        'status':
            'COMPLETED',

        'endedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // RESET QR CONNECTION
    // ==========================================================

    final String ownerId =
        _stringValue(
      data['ownerId'],
    );

    if (ownerId.isEmpty) {
      return;
    }

    final QuerySnapshot<
        Map<String, dynamic>> qrResult =
        await _qrConnections
            .where(
              'ownerId',
              isEqualTo: ownerId,
            )
            .limit(1)
            .get();

    if (qrResult.docs.isEmpty) {
      return;
    }

    await qrResult.docs.first.reference.set(
      {
        'scanned':
            false,
        'connected':
            false,

        'walkerId':
            null,
        'walkerUid':
            null,
        'walkerName':
            null,

        'activeWalkId':
            null,
        'liveWalkSessionId':
            null,

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
  // HELPERS
  // ============================================================

  static String _readString(
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

  static String _stringValue(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static bool _validCoordinate(
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 &&
            longitude == 0);
  }

  static void _showError(
    BuildContext context,
    String message,
  ) {
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }
}

/// ============================================================
/// QR WALK DATA
/// ============================================================

class WalkerQrWalkData {
  final String ownerId;
  final String ownerAuthUid;
  final String ownerName;
  final String? ownerPhone;
  final String walkId;
  final String dogName;
  final String dogBreed;

  const WalkerQrWalkData({
    required this.ownerId,
    required this.ownerAuthUid,
    required this.ownerName,
    required this.ownerPhone,
    required this.walkId,
    required this.dogName,
    required this.dogBreed,
  });
}
