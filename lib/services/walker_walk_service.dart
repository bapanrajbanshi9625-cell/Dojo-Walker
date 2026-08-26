// File:
// lib/services/walker_walk_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/live_walk/screens/live_walk_screen.dart';
import '../features/qr_walk/screens/qr_scanner_screen.dart';

/// ============================================================
/// WALKER WALK SERVICE
///
/// SUPPORTED FLOWS
///
/// 1. QR WALK
///    QrScannerScreen
///         ↓
///    liveWalkSessions/{sessionId}
///         ↓
///    connect walker
///         ↓
///    LiveWalkScreen
///
/// 2. INSTA WALK
///    active_walks/{walkId}
///         ↓
///    LiveWalkScreen
///
/// IMPORTANT
/// QR flow does NOT create active_walks.
/// ============================================================

class WalkerWalkService {
  WalkerWalkService._();

  static final WalkerWalkService instance =
      WalkerWalkService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  static CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  static CollectionReference<Map<String, dynamic>>
      get _activeWalks =>
          _firestore.collection('active_walks');

  // ============================================================
  // CURRENT WALKER
  // ============================================================

  static User? get _currentWalker =>
      _auth.currentUser;

  // ============================================================
  // SCAN OWNER QR
  // ============================================================

  static Future<WalkerWalkData?> scanOwnerQr(
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

      final User? walker =
          _currentWalker;

      if (walker == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      final String walkerUid =
          walker.uid.trim();

      if (walkerUid.isEmpty) {
        throw Exception(
          'Walker account is invalid.',
        );
      }

      // ========================================================
      // SOURCE
      // ========================================================

      final String source =
          (qr['source'] ?? 'qr')
              .toString()
              .trim()
              .toLowerCase();

      // ========================================================
      // OWNER ID
      // ========================================================

      final String ownerId =
          (
            qr['ownerId'] ??
            qr['ownerUserId'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // OWNER AUTH UID
      // ========================================================

      final String ownerUid =
          (
            qr['ownerUid'] ??
            qr['uid'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // OWNER NAME
      // ========================================================

      final String ownerName =
          (
            qr['ownerName'] ??
            qr['name'] ??
            'Owner'
          )
              .toString()
              .trim();

      // ========================================================
      // OWNER PHONE
      // ========================================================

      final String ownerPhone =
          (
            qr['ownerPhone'] ??
            qr['phoneNumber'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // WALK ID
      // ========================================================

      final String qrWalkId =
          (qr['walkId'] ?? '')
              .toString()
              .trim();

      // ========================================================
      // SESSION ID
      // ========================================================

      final String qrSessionId =
          (qr['sessionId'] ?? '')
              .toString()
              .trim();

      // ========================================================
      // QR SESSION FLOW
      //
      // Scanner/owner side creates:
      //
      // liveWalkSessions/{sessionId}
      //
      // Walker only connects to existing session.
      // ========================================================

      if (source == 'qr' &&
          qrSessionId.isNotEmpty) {
        return WalkerWalkData(
          ownerId: ownerId,
          ownerUid: ownerUid,
          ownerName: ownerName.isEmpty
              ? 'Owner'
              : ownerName,
          ownerPhone: ownerPhone.isEmpty
              ? null
              : ownerPhone,
          walkId: qrSessionId,
          sessionId: qrSessionId,
          dogName:
              (qr['dogName'] ?? 'Dog')
                  .toString(),
          dogBreed:
              (qr['dogBreed'] ?? '')
                  .toString(),
          source: 'qr',
        );
      }

      // ========================================================
      // BACKWARD COMPATIBILITY
      // ========================================================

      if (ownerId.isEmpty &&
          ownerUid.isEmpty) {
        throw Exception(
          'Owner information is missing from QR.',
        );
      }

      if (qrWalkId.isEmpty) {
        throw Exception(
          'Walk ID is missing from QR.',
        );
      }

      return WalkerWalkData(
        ownerId: ownerId.isNotEmpty
            ? ownerId
            : ownerUid,
        ownerUid: ownerUid,
        ownerName: ownerName.isEmpty
            ? 'Owner'
            : ownerName,
        ownerPhone: ownerPhone.isEmpty
            ? null
            : ownerPhone,
        walkId: qrWalkId,
        sessionId: qrSessionId.isEmpty
            ? null
            : qrSessionId,
        dogName:
            (qr['dogName'] ?? 'Dog')
                .toString(),
        dogBreed:
            (qr['dogBreed'] ?? '')
                .toString(),
        source: source.isEmpty
            ? 'qr'
            : source,
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

      _showMessage(
        context,
        'Could not read Owner QR: $message',
      );

      return null;
    }
  }

  // ============================================================
  // CONNECT WITH OWNER
  // ============================================================

  static Future<String> connectWithOwner(
    WalkerWalkData walk,
  ) async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        walker.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker account is invalid.',
      );
    }

    if (walk.isQrFlow) {
      return _connectQrSession(
        walk,
        walkerUid,
      );
    }

    return _connectActiveWalk(
      walk,
      walkerUid,
    );
  }

  // ============================================================
  // CONNECT QR SESSION
  // ============================================================

  static Future<String> _connectQrSession(
    WalkerWalkData walk,
    String walkerUid,
  ) async {
    final String sessionId =
        (
          walk.sessionId ??
          walk.walkId
        ).trim();

    if (sessionId.isEmpty) {
      throw Exception(
        'Live Walk session ID is missing.',
      );
    }

    final DocumentReference<
        Map<String, dynamic>> sessionRef =
        _liveWalkSessions.doc(sessionId);

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await sessionRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Live Walk session not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // STATUS
    // ==========================================================

    final String status =
        (data['status'] ?? 'ACTIVE')
            .toString()
            .trim()
            .toUpperCase();

    if (status == 'COMPLETED' ||
        status == 'ENDED') {
      throw Exception(
        'This Live Walk has already ended.',
      );
    }

    // ==========================================================
    // OWNER VERIFICATION
    // ==========================================================

    final String sessionOwnerUid =
        (data['ownerUid'] ?? '')
            .toString()
            .trim();

    final String sessionOwnerId =
        (data['ownerId'] ?? '')
            .toString()
            .trim();

    if (walk.ownerUid.isNotEmpty &&
        sessionOwnerUid.isNotEmpty &&
        walk.ownerUid !=
            sessionOwnerUid) {
      throw Exception(
        'Owner verification failed.',
      );
    }

    if (walk.ownerId.isNotEmpty &&
        sessionOwnerId.isNotEmpty &&
        walk.ownerId !=
            sessionOwnerId) {
      throw Exception(
        'Owner ID verification failed.',
      );
    }

    // ==========================================================
    // EXISTING WALKER
    // ==========================================================

    final String existingWalkerUid =
        (data['walkerUid'] ?? '')
            .toString()
            .trim();

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid !=
            walkerUid) {
      throw Exception(
        'This Live Walk is already connected with another walker.',
      );
    }

    // ==========================================================
    // WALKER BUSINESS ID
    // ==========================================================

    final String walkerId =
        await _getWalkerBusinessId(
      walkerUid,
    );

    final String walkerName =
        _walkerName();

    final String walkerPhone =
        _walkerPhone();

    // ==========================================================
    // ATTACH WALKER TO EXISTING SESSION
    // ==========================================================

    await sessionRef.set(
      {
        'walkerId': walkerId,
        'walkerUid': walkerUid,
        'walkerName': walkerName,
        'walkerPhone': walkerPhone,

        'connectionStatus': 'connected',

        'walkerConnected': true,

        'connectedBy': walkerUid,

        'connectedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return sessionId;
  }

  // ============================================================
  // GET WALKER BUSINESS ID
  // ============================================================

  static Future<String> _getWalkerBusinessId(
    String walkerUid,
  ) async {
    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await _firestore
            .collection('phoneAccounts')
            .doc(walkerUid)
            .get();

    final Map<String, dynamic>? data =
        snapshot.data();

    final String walkerId =
        (data?['walkerId'] ?? '')
            .toString()
            .trim();

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    return walkerId;
  }

  // ============================================================
  // WALKER NAME
  // ============================================================

  static String _walkerName() {
    final User? walker =
        _currentWalker;

    final String name =
        walker?.displayName?.trim() ?? '';

    return name.isEmpty
        ? 'Walker'
        : name;
  }

  // ============================================================
  // WALKER PHONE
  // ============================================================

  static String _walkerPhone() {
    final User? walker =
        _currentWalker;

    return walker?.phoneNumber?.trim() ?? '';
  }

  // ============================================================
  // CONNECT OLD ACTIVE WALK
  // ============================================================

  static Future<String> _connectActiveWalk(
    WalkerWalkData walk,
    String walkerUid,
  ) async {
    final String ownerId =
        walk.ownerId.trim();

    final String walkId =
        walk.walkId.trim();

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
          (data['status'] ?? '')
              .toString()
              .trim()
              .toLowerCase();

      final String existingWalker =
          (data['walkerUid'] ?? '')
              .toString()
              .trim();

      final String existingOwner =
          (data['ownerId'] ?? '')
              .toString()
              .trim();

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

    final String walkerName =
        _walkerName();

    final String walkerPhone =
        _walkerPhone();

    await activeRef.set(
      {
        'walkId': walkId,

        'status': 'active',
        'connectionStatus': 'connected',
        'isLive': true,

        // OWNER
        'ownerId': ownerId,
        'ownerUid': walk.ownerUid,
        'ownerName': walk.ownerName,
        'ownerPhone':
            walk.ownerPhone ?? '',

        // WALKER
        'walkerUid': walkerUid,
        'walkerName': walkerName,
        'walkerPhone': walkerPhone,

        // DOG
        'dogName': walk.dogName,
        'dogBreed': walk.dogBreed,

        // CONNECTION
        'connectedBy': walkerUid,
        'connectedAt':
            FieldValue.serverTimestamp(),

        // TIME
        'startedAt':
            FieldValue.serverTimestamp(),
        'endedAt': null,

        // LOCATION
        'ownerLocation': null,
        'walkerLocation': null,
        'ownerLocationUpdatedAt': null,
        'walkerLocationUpdatedAt': null,

        // SCAN
        'ownerScanned': false,
        'walkerScanned': true,
        'scannedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return walkId;
  }

  // ============================================================
  // SCAN + CONNECT
  // ============================================================

  static Future<String?> scanAndConnect(
    BuildContext context,
  ) async {
    final WalkerWalkData? walk =
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

      _showMessage(
        context,
        'Owner connected successfully.',
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

      _showMessage(
        context,
        'Could not connect: $message',
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
    final WalkerWalkData? walk =
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

      _showMessage(
        context,
        'Could not start Live Walk: $message',
      );
    }
  }

  // ============================================================
  // OPEN LIVE WALK
  // ============================================================

  static Future<void> openLiveWalk(
    BuildContext context,
    WalkerWalkData walk,
  ) async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      _showMessage(
        context,
        'Walker is not logged in.',
      );
      return;
    }

    final String ownerId =
        walk.ownerId.trim();

    final String ownerUid =
        walk.ownerUid.trim();

    final String finalOwnerUid =
        ownerUid.isNotEmpty
            ? ownerUid
            : ownerId;

    if (finalOwnerUid.isEmpty) {
      _showMessage(
        context,
        'Owner ID is missing.',
      );
      return;
    }

    final String walkId =
        walk.walkId.trim();

    if (walkId.isEmpty) {
      _showMessage(
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
          ownerUid: finalOwnerUid,
          ownerName: walk.ownerName,
          walkId: walkId,
          dogName: walk.dogName,
          dogBreed: walk.dogBreed,
          ownerPhone: walk.ownerPhone,
          sessionId: walk.sessionId,
        ),
      ),
    );
  }

  // ============================================================
  // GET MY ACTIVE INSTA WALK
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>?>
      getMyActiveWalk() async {
    final User? walker =
        _currentWalker;

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
  // GET MY LIVE QR SESSION
  // ============================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>?>
      getMyLiveWalkSession() async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      return null;
    }

    final QuerySnapshot<
        Map<String, dynamic>> result =
        await _liveWalkSessions
            .where(
              'walkerUid',
              isEqualTo: walker.uid,
            )
            .where(
              'status',
              isEqualTo: 'ACTIVE',
            )
            .limit(1)
            .get();

    if (result.docs.isEmpty) {
      return null;
    }

    return result.docs.first;
  }

  // ============================================================
  // WATCH ACTIVE WALK
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
  // WATCH LIVE QR SESSION
  // ============================================================

  static Stream<
      DocumentSnapshot<Map<String, dynamic>>>
      watchLiveSession(
    String sessionId,
  ) {
    return _liveWalkSessions
        .doc(sessionId)
        .snapshots();
  }

  // ============================================================
  // UPDATE WALKER LOCATION
  // ============================================================

  static Future<void> updateWalkerLocation({
    required String walkId,
    required double latitude,
    required double longitude,
    String? sessionId,
  }) async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final Map<String, dynamic>
        locationData = {
      'latitude': latitude,
      'longitude': longitude,
    };

    // ==========================================================
    // QR SESSION
    // ==========================================================

    final String cleanSessionId =
        sessionId?.trim() ?? '';

    if (cleanSessionId.isNotEmpty) {
      await _liveWalkSessions
          .doc(cleanSessionId)
          .set(
        {
          'currentLocation': {
            'lat': latitude,
            'lng': longitude,
          },
          'walkerLocation':
              locationData,
          'walkerLocationUpdatedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      return;
    }

    // ==========================================================
    // AUTO DETECT QR SESSION
    // ==========================================================

    final DocumentSnapshot<
        Map<String, dynamic>>? qrSession =
        await getMyLiveWalkSession();

    if (qrSession != null &&
        qrSession.exists) {
      await qrSession.reference.set(
        {
          'currentLocation': {
            'lat': latitude,
            'lng': longitude,
          },
          'walkerLocation':
              locationData,
          'walkerLocationUpdatedAt':
              FieldValue.serverTimestamp(),
          'updatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      return;
    }

    // ==========================================================
    // OLD INSTA WALK
    // ==========================================================

    await _activeWalks
        .doc(cleanWalkId)
        .set(
      {
        'walkerLocation':
            locationData,
        'walkerLocationUpdatedAt':
            FieldValue.serverTimestamp(),
        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // COMPLETE WALK
  // ============================================================

  static Future<void> completeWalk({
    required String walkId,
    String? sessionId,
  }) async {
    final User? walker =
        _currentWalker;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ==========================================================
    // QR SESSION
    // ==========================================================

    final String cleanSessionId =
        sessionId?.trim() ?? '';

    if (cleanSessionId.isNotEmpty) {
      await _completeLiveSession(
        cleanSessionId,
        walker.uid,
      );
      return;
    }

    // ==========================================================
    // AUTO DETECT QR SESSION
    // ==========================================================

    final DocumentSnapshot<
        Map<String, dynamic>>? qrSession =
        await getMyLiveWalkSession();

    if (qrSession != null &&
        qrSession.exists) {
      await _completeLiveSession(
        qrSession.id,
        walker.uid,
      );
      return;
    }

    // ==========================================================
    // OLD INSTA WALK
    // ==========================================================

    await _completeActiveWalk(
      cleanWalkId,
      walker.uid,
    );
  }

  // ============================================================
  // COMPLETE QR LIVE SESSION
  // ============================================================

  static Future<void> _completeLiveSession(
    String sessionId,
    String walkerUid,
  ) async {
    final DocumentReference<
        Map<String, dynamic>> sessionRef =
        _liveWalkSessions.doc(sessionId);

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await sessionRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Live Walk session not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    final String existingWalkerUid =
        (data['walkerUid'] ?? '')
            .toString()
            .trim();

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid !=
            walkerUid) {
      throw Exception(
        'You cannot complete another walker\'s Live Walk.',
      );
    }

    // ==========================================================
    // SAVE HISTORY
    // ==========================================================

    await _firestore
        .collection('walk_history')
        .doc(sessionId)
        .set(
      {
        ...data,

        'sessionId': sessionId,

        'walkId':
            data['walkId'] ?? sessionId,

        'status': 'completed',

        'isLive': false,

        'connectionStatus':
            'completed',

        'walkEnded': true,

        'trackingEnded': true,

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy': walkerUid,

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

    await sessionRef.set(
      {
        'status': 'COMPLETED',

        'connectionStatus':
            'completed',

        'walkEnded': true,

        'trackingEnded': true,

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy': walkerUid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // OPTIONAL OLD ACTIVE WALK COMPATIBILITY
    // ==========================================================

    final DocumentReference<
        Map<String, dynamic>> activeRef =
        _activeWalks.doc(sessionId);

    final DocumentSnapshot<
        Map<String, dynamic>> activeSnapshot =
        await activeRef.get();

    if (!activeSnapshot.exists) {
      return;
    }

    final Map<String, dynamic>
        activeData =
        activeSnapshot.data() ??
            <String, dynamic>{};

    final String activeWalkerUid =
        (activeData['walkerUid'] ?? '')
            .toString()
            .trim();

    if (activeWalkerUid.isEmpty ||
        activeWalkerUid == walkerUid) {
      await activeRef.set(
        {
          'status': 'completed',
          'isLive': false,
          'connectionStatus':
              'completed',
          'endedAt':
              FieldValue.serverTimestamp(),
          'completedBy': walkerUid,
          'completedAt':
              FieldValue.serverTimestamp(),
          'lastUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );
    }
  }

  // ============================================================
  // COMPLETE OLD ACTIVE WALK
  // ============================================================

  static Future<void> _completeActiveWalk(
    String walkId,
    String walkerUid,
  ) async {
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

    final String existingWalkerUid =
        (data['walkerUid'] ?? '')
            .toString()
            .trim();

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid !=
            walkerUid) {
      throw Exception(
        'You cannot complete another walker\'s walk.',
      );
    }

    // ==========================================================
    // SAVE HISTORY
    // ==========================================================

    await _firestore
        .collection('walk_history')
        .doc(walkId)
        .set(
      {
        ...data,

        'status': 'completed',

        'isLive': false,

        'connectionStatus':
            'completed',

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walkerUid,

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
        'status': 'completed',

        'isLive': false,

        'connectionStatus':
            'completed',

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walkerUid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  static void _showMessage(
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
/// WALKER WALK DATA
/// ============================================================

class WalkerWalkData {
  final String ownerId;

  /// Firebase Auth UID of owner.
  final String ownerUid;

  final String ownerName;

  final String? ownerPhone;

  /// Walk/session identifier.
  final String walkId;

  /// Actual liveWalkSessions document ID.
  final String? sessionId;

  final String dogName;

  final String dogBreed;

  /// qr / insta / etc.
  final String source;

  const WalkerWalkData({
    required this.ownerId,
    this.ownerUid = '',
    required this.ownerName,
    required this.ownerPhone,
    required this.walkId,
    this.sessionId,
    required this.dogName,
    required this.dogBreed,
    this.source = 'qr',
  });

  // ============================================================
  // QR FLOW
  // ============================================================

  bool get isQrFlow {
    return source.trim().toLowerCase() == 'qr';
  }

  // ============================================================
  // INSTA FLOW
  // ============================================================

  bool get isInstaFlow {
    return source.trim().toLowerCase() == 'insta';
  }
}
