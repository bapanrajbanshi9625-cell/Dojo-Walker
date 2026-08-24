// File:
// lib/services/walker_walk_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../screens/qr_scanner_screen.dart
import '../../../services/walk_request_service.dart

/// ============================================================
/// WALKER WALK SERVICE
///
/// Supports:
/// 1. Insta Walk
/// 2. Owner QR Walk
///
/// IMPORTANT:
/// QR flow uses:
///     liveWalkSessions/{sessionId}
///
/// Insta Walk existing flow remains compatible with:
///     WalkRequestService
///
/// QR flow does NOT create a duplicate active_walks document.
/// ============================================================

class WalkerWalkService {
  WalkerWalkService._();

  static final WalkerWalkService instance =
      WalkerWalkService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static final WalkRequestService _walkRequestService =
      WalkRequestService.instance;

  // ==========================================================
  // COLLECTIONS
  // ==========================================================

  static CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  static CollectionReference<Map<String, dynamic>>
      get _qrConnections =>
          _firestore.collection('qr_connections');

  // ==========================================================
  // SCAN OWNER QR
  //
  // QR SCANNER itself verifies QR and creates:
  //
  // liveWalkSessions/{sessionId}
  //
  // Scanner returns result JSON to this service.
  // ==========================================================

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
          'Invalid QR connection result.',
        );
      }

      if (decoded is! Map) {
        throw Exception(
          'Invalid QR connection result.',
        );
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(decoded);

      // ======================================================
      // WALKER LOGIN
      // ======================================================

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
          'Walker account is invalid.',
        );
      }

      // ======================================================
      // RESULT TYPE
      // ======================================================

      final String source =
          (data['source'] ?? 'qr')
              .toString()
              .trim()
              .toLowerCase();

      if (source != 'qr') {
        throw Exception(
          'Invalid QR walk connection.',
        );
      }

      // ======================================================
      // OWNER BUSINESS ID
      // ======================================================

      final String ownerId =
          (
            data['ownerId'] ??
            ''
          )
              .toString()
              .trim();

      if (ownerId.isEmpty) {
        throw Exception(
          'Owner ID is missing.',
        );
      }

      // ======================================================
      // OWNER FIREBASE UID
      // ======================================================

      final String ownerUid =
          (
            data['ownerUid'] ??
            ''
          )
              .toString()
              .trim();

      if (ownerUid.isEmpty) {
        throw Exception(
          'Owner UID is missing.',
        );
      }

      // ======================================================
      // PREVENT SELF CONNECTION
      // ======================================================

      if (ownerUid == walkerUid) {
        throw Exception(
          'You cannot connect to your own Owner QR.',
        );
      }

      // ======================================================
      // OWNER NAME
      // ======================================================

      final String ownerName =
          (
            data['ownerName'] ??
            'Owner'
          )
              .toString()
              .trim();

      // ======================================================
      // OWNER PHONE
      // ======================================================

      final String ownerPhone =
          (
            data['ownerPhone'] ??
            ''
          )
              .toString()
              .trim();

      // ======================================================
      // SESSION ID
      //
      // New QR scanner returns sessionId.
      // ======================================================

      String sessionId =
          (
            data['sessionId'] ??
            ''
          )
              .toString()
              .trim();

      // ======================================================
      // WALK ID
      // ======================================================

      String walkId =
          (
            data['walkId'] ??
            ''
          )
              .toString()
              .trim();

      // ======================================================
      // QR WALK ID
      // ======================================================

      final String qrWalkId =
          (
            data['qrWalkId'] ??
            ''
          )
              .toString()
              .trim();

      // ======================================================
      // SESSION FALLBACK
      //
      // Normally scanner already created the session.
      // ======================================================

      if (sessionId.isEmpty) {
        sessionId = walkId;
      }

      if (walkId.isEmpty) {
        walkId = sessionId;
      }

      if (sessionId.isEmpty) {
        throw Exception(
          'Live Walk session is missing.',
        );
      }

      if (walkId.isEmpty) {
        throw Exception(
          'Walk ID is missing.',
        );
      }

      // ======================================================
      // VERIFY LIVE SESSION
      // ======================================================

      final DocumentSnapshot<
          Map<String, dynamic>> sessionSnapshot =
          await _liveWalkSessions
              .doc(sessionId)
              .get();

      if (!sessionSnapshot.exists) {
        throw Exception(
          'Live Walk session not found.',
        );
      }

      final Map<String, dynamic> sessionData =
          sessionSnapshot.data() ??
              <String, dynamic>{};

      // ======================================================
      // VERIFY SESSION OWNER
      // ======================================================

      final String sessionOwnerUid =
          (
            sessionData['ownerUid'] ??
            ''
          )
              .toString()
              .trim();

      if (sessionOwnerUid.isNotEmpty &&
          sessionOwnerUid != ownerUid) {
        throw Exception(
          'Owner verification failed.',
        );
      }

      // ======================================================
      // VERIFY SESSION OWNER BUSINESS ID
      // ======================================================

      final String sessionOwnerId =
          (
            sessionData['ownerId'] ??
            ''
          )
              .toString()
              .trim();

      if (sessionOwnerId.isNotEmpty &&
          sessionOwnerId != ownerId) {
        throw Exception(
          'Owner ID verification failed.',
        );
      }

      // ======================================================
      // GET DOG DATA FROM SESSION
      // ======================================================

      final String dogName =
          (
            sessionData['dogName'] ??
            data['dogName'] ??
            'Dog'
          )
              .toString()
              .trim();

      final String dogBreed =
          (
            sessionData['dogBreed'] ??
            data['dogBreed'] ??
            ''
          )
              .toString()
              .trim();

      // ======================================================
      // UPDATE WALKER CONNECTION
      //
      // QR scanner already created session.
      // We only attach current walker here.
      // ======================================================

      await _connectQrSession(
        ownerId: ownerId,
        ownerUid: ownerUid,
        ownerName: ownerName.isEmpty
            ? 'Owner'
            : ownerName,
        ownerPhone: ownerPhone,
        walkerUid: walkerUid,
        walkId: walkId,
        sessionId: sessionId,
      );

      // ======================================================
      // RETURN WALK DATA
      // ======================================================

      return WalkerWalkData(
        ownerId: ownerId,
        ownerUid: ownerUid,
        ownerName: ownerName.isEmpty
            ? 'Owner'
            : ownerName,
        ownerPhone:
            ownerPhone.isEmpty
                ? null
                : ownerPhone,
        walkId: walkId,
        sessionId: sessionId,
        qrWalkId: qrWalkId,
        dogName: dogName.isEmpty
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
              'Could not connect Owner QR: $message',
            ),
            behavior:
                SnackBarBehavior.floating,
          ),
        );

      return null;
    }
  }

  // ==========================================================
  // CONNECT QR SESSION
  //
  // IMPORTANT:
  //
  // NO active_walks CREATE HERE.
  //
  // liveWalkSessions already exists because the scanner
  // created it.
  // ==========================================================

  static Future<void> _connectQrSession({
    required String ownerId,
    required String ownerUid,
    required String ownerName,
    required String ownerPhone,
    required String walkerUid,
    required String walkId,
    required String sessionId,
  }) async {
    if (sessionId.trim().isEmpty) {
      throw Exception(
        'Session ID is missing.',
      );
    }

    if (walkerUid.trim().isEmpty) {
      throw Exception(
        'Walker UID is missing.',
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

    final String existingWalkerUid =
        (
          data['walkerUid'] ??
          ''
        )
            .toString()
            .trim();

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid != walkerUid) {
      throw Exception(
        'This Live Walk is already connected to another walker.',
      );
    }

    final WriteBatch batch =
        _firestore.batch();

    // ========================================================
    // UPDATE LIVE SESSION
    // ========================================================

    batch.set(
      sessionRef,
      {
        'id': sessionId,
        'sessionId': sessionId,

        'walkId':
            data['walkId'] ??
            sessionId,

        'qrWalkId':
            data['qrWalkId'] ??
            walkId,

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

        'walkerUid': walkerUid,
        'walkerId':
            data['walkerId'] ??
            walkerUid,

        'connectionStatus':
            'connected',

        'walkerConnected':
            true,

        // ----------------------------------------------------
        // STATUS
        // ----------------------------------------------------

        'status':
            'ACTIVE',

        'walkStarted':
            true,

        'walkEnded':
            false,

        // ----------------------------------------------------
        // CONNECTION
        // ----------------------------------------------------

        'connectedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ========================================================
    // UPDATE QR CONNECTION
    // ========================================================

    final DocumentReference<
        Map<String, dynamic>> qrRef =
        _qrConnections.doc(ownerUid);

    batch.set(
      qrRef,
      {
        'type':
            'dojo_owner_qr',

        'ownerId':
            ownerId,

        'ownerUid':
            ownerUid,

        'walkerId':
            data['walkerId'] ??
            walkerUid,

        'walkerUid':
            walkerUid,

        'walkId':
            walkId,

        'activeWalkId':
            sessionId,

        'scanned':
            true,

        'connected':
            true,

        'connectedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await batch.commit();
  }

  // ==========================================================
  // CONNECT WALKER WITH OWNER
  //
  // Kept for compatibility with existing Insta Walk / callers.
  //
  // If a session already exists, update it.
  // Otherwise create an active_walks document for legacy
  // callers only.
  // ==========================================================

  static Future<String> connectWithOwner(
    WalkerWalkData walk,
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

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker account is invalid.',
      );
    }

    if (walk.ownerId.trim().isEmpty) {
      throw Exception(
        'Owner ID is missing.',
      );
    }

    if (walk.walkId.trim().isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ========================================================
    // NEW QR FLOW
    //
    // Existing live session means QR scanner has already
    // created the session.
    // ========================================================

    if (walk.sessionId.trim().isNotEmpty) {
      final DocumentSnapshot<
          Map<String, dynamic>> session =
          await _liveWalkSessions
              .doc(walk.sessionId)
              .get();

      if (!session.exists) {
        throw Exception(
          'Live Walk session not found.',
        );
      }

      await _connectQrSession(
        ownerId: walk.ownerId,
        ownerUid: walk.ownerUid,
        ownerName: walk.ownerName,
        ownerPhone:
            walk.ownerPhone ?? '',
        walkerUid: walkerUid,
        walkId: walk.walkId,
        sessionId: walk.sessionId,
      );

      return walk.walkId;
    }

    // ========================================================
    // LEGACY / EXISTING INSTA WALK COMPATIBILITY
    //
    // Do not remove this path.
    //
    // Existing Insta Walk implementation can continue using
    // active_walks through this compatibility path.
    // ========================================================

    final DocumentReference<
        Map<String, dynamic>> activeRef =
        _firestore
            .collection('active_walks')
            .doc(walk.walkId);

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
              .toLowerCase();

      final String existingWalker =
          (data['walkerUid'] ?? '')
              .toString();

      final String existingOwner =
          (data['ownerId'] ?? '')
              .toString();

      if (status == 'active' &&
          existingWalker == walkerUid &&
          existingOwner == walk.ownerId) {
        return walk.walkId;
      }

      if (status == 'active' &&
          existingWalker != walkerUid) {
        throw Exception(
          'This Walk is already active.',
        );
      }
    }

    // ========================================================
    // WALKER DETAILS
    // ========================================================

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

    // ========================================================
    // LEGACY ACTIVE WALK
    //
    // This is intentionally retained for existing Insta Walk
    // compatibility.
    // ========================================================

    await activeRef.set(
      {
        'walkId':
            walk.walkId,

        'status':
            'active',

        'connectionStatus':
            'connected',

        'isLive':
            true,

        // ----------------------------------------------------
        // OWNER
        // ----------------------------------------------------

        'ownerId':
            walk.ownerId,

        'ownerUid':
            walk.ownerUid,

        'ownerName':
            walk.ownerName,

        'ownerPhone':
            walk.ownerPhone ?? '',

        // ----------------------------------------------------
        // WALKER
        // ----------------------------------------------------

        'walkerUid':
            walkerUid,

        'walkerName':
            walkerName,

        'walkerPhone':
            walkerPhone,

        // ----------------------------------------------------
        // DOG
        // ----------------------------------------------------

        'dogName':
            walk.dogName,

        'dogBreed':
            walk.dogBreed,

        // ----------------------------------------------------
        // CONNECTION
        // ----------------------------------------------------

        'connectedBy':
            walkerUid,

        'connectedAt':
            FieldValue.serverTimestamp(),

        // ----------------------------------------------------
        // TIME
        // ----------------------------------------------------

        'startedAt':
            FieldValue.serverTimestamp(),

        'endedAt':
            null,

        // ----------------------------------------------------
        // LOCATION
        // ----------------------------------------------------

        'ownerLocation':
            null,

        'walkerLocation':
            null,

        'ownerLocationUpdatedAt':
            null,

        'walkerLocationUpdatedAt':
            null,

        // ----------------------------------------------------
        // SCAN
        // ----------------------------------------------------

        'ownerScanned':
            false,

        'walkerScanned':
            true,

        'scannedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    return walk.walkId;
  }

  // ==========================================================
  // SCAN + CONNECT
  // ==========================================================

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

  // ==========================================================
  // SCAN + CONNECT + OPEN LIVE WALK
  // ==========================================================

  static Future<void> scanConnectAndOpenLiveWalk(
    BuildContext context,
  ) async {
    final WalkerWalkData? walk =
        await scanOwnerQr(context);

    if (walk == null) {
      return;
    }

    try {
      // ======================================================
      // CONNECTION
      // ======================================================

      await connectWithOwner(walk);

      if (!context.mounted) {
        return;
      }

      // ======================================================
      // OPEN LIVE WALK
      // ======================================================

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

  // ==========================================================
  // OPEN LIVE WALK
  //
  // QR:
  // ownerUid = Firebase UID
  // sessionId = liveWalkSessions document
  //
  // Insta:
  // sessionId can be absent and existing walkId remains usable.
  // ==========================================================

  static Future<void> openLiveWalk(
    BuildContext context,
    WalkerWalkData walk,
  ) async {
    final User? walker =
        _auth.currentUser;

    if (walker == null) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Walker is not logged in.',
            ),
          ),
        );

      return;
    }

    if (walk.ownerUid.trim().isEmpty) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Owner UID is missing.',
            ),
          ),
        );

      return;
    }

    if (walk.walkId.trim().isEmpty) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Walk ID is missing.',
            ),
          ),
        );

      return;
    }

    if (!context.mounted) {
      return;
    }

    // ========================================================
    // LIVE WALK
    // ========================================================

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveWalkScreen(
          // IMPORTANT:
          // Firebase Owner UID, NOT business ownerId.
          ownerUid:
              walk.ownerUid,

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
              walk.sessionId.isEmpty
                  ? null
                  : walk.sessionId,
        ),
      ),
    );
  }

  // ==========================================================
  // GET ACTIVE WALK FOR CURRENT WALKER
  //
  // Existing Insta Walk compatibility.
  // ==========================================================

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
        await _firestore
            .collection('active_walks')
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

  // ==========================================================
  // WATCH ACTIVE WALK
  //
  // Existing Insta Walk compatibility.
  // ==========================================================

  static Stream<
      DocumentSnapshot<Map<String, dynamic>>>
      watchWalk(
    String walkId,
  ) {
    return _firestore
        .collection('active_walks')
        .doc(walkId)
        .snapshots();
  }

  // ==========================================================
  // WATCH LIVE SESSION
  //
  // New QR flow.
  // ==========================================================

  static Stream<
      DocumentSnapshot<Map<String, dynamic>>>
      watchLiveSession(
    String sessionId,
  ) {
    return _liveWalkSessions
        .doc(sessionId)
        .snapshots();
  }

  // ==========================================================
  // UPDATE WALKER LOCATION
  //
  // Supports:
  // QR -> liveWalkSessions
  // Legacy/Insta -> active_walks
  // ==========================================================

  static Future<void> updateWalkerLocation({
    required String walkId,
    required double latitude,
    required double longitude,
    String? sessionId,
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

    final String? cleanSessionId =
        sessionId?.trim();

    // ========================================================
    // NEW QR SESSION
    // ========================================================

    if (cleanSessionId != null &&
        cleanSessionId.isNotEmpty) {
      await _liveWalkSessions
          .doc(cleanSessionId)
          .set(
        {
          'currentLocation': {
            'lat': latitude,
            'lng': longitude,
          },

          'walkerLocation': {
            'latitude': latitude,
            'longitude': longitude,
          },

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

    // ========================================================
    // EXISTING INSTA / LEGACY FLOW
    // ========================================================

    await _firestore
        .collection('active_walks')
        .doc(walkId)
        .set(
      {
        'walkerLocation': {
          'latitude': latitude,
          'longitude': longitude,
        },

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

  // ==========================================================
  // COMPLETE WALK
  //
  // Kept as existing compatibility method.
  // ==========================================================

  static Future<void> completeWalk({
    required String walkId,
    String? sessionId,
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

    final String? cleanSessionId =
        sessionId?.trim();

    // ========================================================
    // NEW QR SESSION
    // ========================================================

    if (cleanSessionId != null &&
        cleanSessionId.isNotEmpty) {
      await _completeQrSession(
        walkId: walkId,
        sessionId: cleanSessionId,
        walkerUid: walker.uid,
      );

      return;
    }

    // ========================================================
    // EXISTING INSTA / LEGACY FLOW
    //
    // Do NOT remove.
    // ========================================================

    await _completeLegacyActiveWalk(
      walkId: walkId,
      walkerUid: walker.uid,
    );
  }

  // ==========================================================
  // COMPLETE QR SESSION
  // ==========================================================

  static Future<void> _completeQrSession({
    required String walkId,
    required String sessionId,
    required String walkerUid,
  }) async {
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

    final Map<String, dynamic> historyData =
        Map<String, dynamic>.from(data);

    historyData['status'] =
        'completed';

    historyData['walkEnded'] =
        true;

    historyData['isLive'] =
        false;

    historyData['connectionStatus'] =
        'completed';

    historyData['completedBy'] =
        walkerUid;

    historyData['completedAt'] =
        FieldValue.serverTimestamp();

    historyData['endedAt'] =
        FieldValue.serverTimestamp();

    historyData['updatedAt'] =
        FieldValue.serverTimestamp();

    // ========================================================
    // HISTORY
    // ========================================================

    await _firestore
        .collection('walk_history')
        .doc(walkId)
        .set(
      historyData,
      SetOptions(
        merge: true,
      ),
    );

    // ========================================================
    // SESSION COMPLETE
    // ========================================================

    await sessionRef.set(
      {
        'status':
            'completed',

        'walkEnded':
            true,

        'isLive':
            false,

        'connectionStatus':
            'completed',

        'completedBy':
            walkerUid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'endedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ========================================================
    // RESET QR CONNECTION
    // ========================================================

    final String ownerUid =
        (data['ownerUid'] ?? '')
            .toString()
            .trim();

    if (ownerUid.isNotEmpty) {
      await _qrConnections
          .doc(ownerUid)
          .set(
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
  }

  // ==========================================================
  // COMPLETE LEGACY / INSTA ACTIVE WALK
  // ==========================================================

  static Future<void>
      _completeLegacyActiveWalk({
    required String walkId,
    required String walkerUid,
  }) async {
    final DocumentReference<
        Map<String, dynamic>> activeRef =
        _firestore
            .collection('active_walks')
            .doc(walkId);

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

    // ========================================================
    // SAVE HISTORY
    // ========================================================

    await _firestore
        .collection('walk_history')
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

    // ========================================================
    // COMPLETE ACTIVE WALK
    // ========================================================

    await activeRef.update(
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
            walkerUid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    // ========================================================
    // RESET QR CONNECTION IF PRESENT
    // ========================================================

    final String ownerUid =
        (data['ownerUid'] ?? '')
            .toString()
            .trim();

    if (ownerUid.isNotEmpty) {
      await _qrConnections
          .doc(ownerUid)
          .set(
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
  }

  // ==========================================================
  // END LIVE WALK
  //
  // IMPORTANT:
  //
  // Existing LiveWalkScreen currently calls:
  //
  // WalkRequestService.endLiveWalk(...)
  //
  // Keep this bridge so Insta Walk is not broken.
  // ==========================================================

  static Future<void> endLiveWalk(
    String walkId, {
    String? sessionId,
  }) async {
    final String? cleanSessionId =
        sessionId?.trim();

    // ========================================================
    // NEW QR FLOW
    // ========================================================

    if (cleanSessionId != null &&
        cleanSessionId.isNotEmpty) {
      final User? walker =
          _auth.currentUser;

      if (walker == null) {
        throw Exception(
          'Walker is not logged in.',
        );
      }

      await _completeQrSession(
        walkId: walkId,
        sessionId: cleanSessionId,
        walkerUid: walker.uid,
      );

      return;
    }

    // ========================================================
    // EXISTING INSTA WALK FLOW
    //
    // This is deliberately preserved.
    // ========================================================

    await _walkRequestService.endLiveWalk(
      walkId,
    );
  }
}

/// ============================================================
/// WALKER WALK DATA
/// ============================================================

class WalkerWalkData {
  /// Business Owner ID.
  final String ownerId;

  /// Firebase Authentication UID.
  final String ownerUid;

  final String ownerName;
  final String? ownerPhone;

  /// Walk ID.
  final String walkId;

  /// liveWalkSessions document ID.
  final String sessionId;

  /// Original walkId embedded in QR.
  final String qrWalkId;

  final String dogName;
  final String dogBreed;

  const WalkerWalkData({
    required this.ownerId,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerPhone,
    required this.walkId,
    required this.sessionId,
    this.qrWalkId = '',
    required this.dogName,
    required this.dogBreed,
  });
}
