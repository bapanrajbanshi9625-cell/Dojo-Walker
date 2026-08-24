// File:
// lib/services/walker_walk_service.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/qr_scanner_screen.dart';
import '../features/walks/screens/live_walk_screen.dart';

/// ============================================================
/// WALKER WALK SERVICE
///
/// NEW FLOW
///
/// Walker
///   ↓
/// Owner QR Scanner
///   ↓
/// qr_connections/{ownerUid}
///   ↓
/// liveWalkSessions/{sessionId}
///   ↓
/// LiveWalkScreen
///
/// IMPORTANT:
/// No active_walks is created here.
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
      get _qrConnections =>
          _firestore.collection('qr_connections');

  static CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  static CollectionReference<Map<String, dynamic>>
      get _walkHistory =>
          _firestore.collection('walk_history');

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

      // ========================================================
      // WALKER LOGIN
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
          'Walker account is invalid.',
        );
      }

      // ========================================================
      // QR TYPE
      // ========================================================

      final String type =
          (qr['type'] ?? '')
              .toString()
              .trim();

      if (type != 'dojo_owner_qr') {
        throw Exception(
          'This is not a valid Dojo Owner QR.',
        );
      }

      // ========================================================
      // OWNER UID
      // ========================================================

      final String ownerUid =
          (qr['ownerId'] ?? '')
              .toString()
              .trim();

      if (ownerUid.isEmpty) {
        throw Exception(
          'Owner ID is missing from QR.',
        );
      }

      // ========================================================
      // WALK ID
      // ========================================================

      final String walkId =
          (qr['walkId'] ?? '')
              .toString()
              .trim();

      if (walkId.isEmpty) {
        throw Exception(
          'Walk ID is missing from QR.',
        );
      }

      // ========================================================
      // PREVENT SELF SCAN
      // ========================================================

      if (ownerUid == walkerUid) {
        throw Exception(
          'You cannot scan your own Owner QR.',
        );
      }

      // ========================================================
      // OWNER CONNECTION
      //
      // qr_connections/{ownerUid}
      // ========================================================

      final DocumentSnapshot<
          Map<String, dynamic>> connection =
          await _qrConnections
              .doc(ownerUid)
              .get();

      if (!connection.exists) {
        throw Exception(
          'Owner QR connection not found.',
        );
      }

      final Map<String, dynamic> data =
          connection.data() ??
              <String, dynamic>{};

      // ========================================================
      // VERIFY OWNER
      // ========================================================

      final String firebaseOwnerId =
          (data['ownerId'] ?? ownerUid)
              .toString()
              .trim();

      if (firebaseOwnerId.isEmpty) {
        throw Exception(
          'Owner information is missing.',
        );
      }

      // ========================================================
      // OWNER NAME
      // ========================================================

      final String ownerName =
          (
            data['ownerName'] ??
            qr['ownerName'] ??
            'Owner'
          )
              .toString()
              .trim();

      // ========================================================
      // OWNER PHONE
      // ========================================================

      final String ownerPhone =
          (
            data['ownerPhone'] ??
            qr['ownerPhone'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // DOG
      // ========================================================

      final String dogName =
          (
            data['dogName'] ??
            qr['dogName'] ??
            'Dog'
          )
              .toString()
              .trim();

      final String dogBreed =
          (
            data['dogBreed'] ??
            qr['dogBreed'] ??
            ''
          )
              .toString()
              .trim();

      // ========================================================
      // RETURN WALK DATA
      // ========================================================

      return WalkerWalkData(
        ownerId: firebaseOwnerId,
        ownerUid: ownerUid,
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
        walkerUid: walkerUid,
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
  // CONNECT WALKER WITH OWNER
  //
  // IMPORTANT:
  // Does NOT create active_walks.
  // Does NOT create another live session.
  //
  // Scanner already created:
  // liveWalkSessions/{sessionId}
  // ============================================================

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

    if (walk.ownerUid.trim().isEmpty) {
      throw Exception(
        'Owner UID is missing.',
      );
    }

    if (walk.walkId.trim().isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ==========================================================
    // WALKER DETAILS
    // ==========================================================

    final String walkerName =
        walker.displayName?.trim().isNotEmpty ==
                true
            ? walker.displayName!.trim()
            : 'Walker';

    final String walkerPhone =
        walker.phoneNumber?.trim().isNotEmpty ==
                true
            ? walker.phoneNumber!.trim()
            : '';

    // ==========================================================
    // OWNER QR CONNECTION
    //
    // qr_connections/{ownerUid}
    // ==========================================================

    final DocumentReference<
        Map<String, dynamic>> connectionRef =
        _qrConnections.doc(
      walk.ownerUid,
    );

    final DocumentSnapshot<
        Map<String, dynamic>> connection =
        await connectionRef.get();

    if (!connection.exists) {
      throw Exception(
        'Owner QR connection not found.',
      );
    }

    final Map<String, dynamic> connectionData =
        connection.data() ??
            <String, dynamic>{};

    // ==========================================================
    // CHECK OTHER WALKER
    // ==========================================================

    final String existingWalker =
        (connectionData['walkerId'] ?? '')
            .toString()
            .trim();

    final bool connected =
        connectionData['connected'] == true;

    if (connected &&
        existingWalker.isNotEmpty &&
        existingWalker != walkerUid) {
      throw Exception(
        'This Owner is already connected with another walker.',
      );
    }

    // ==========================================================
    // UPDATE QR CONNECTION
    // ==========================================================

    await connectionRef.set(
      {
        'type': 'dojo_owner_qr',
        'version': 1,

        'ownerId':
            walk.ownerId,

        'ownerUid':
            walk.ownerUid,

        'walkerId':
            walkerUid,

        'walkerUid':
            walkerUid,

        'walkerName':
            walkerName,

        'walkerPhone':
            walkerPhone,

        'walkId':
            walk.walkId,

        'activeWalkId':
            walk.walkId,

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

    // ==========================================================
    // VERIFY LIVE WALK SESSION
    // ==========================================================

    final DocumentSnapshot<
        Map<String, dynamic>> session =
        await _liveWalkSessions
            .doc(walk.walkId)
            .get();

    if (session.exists) {
      await _liveWalkSessions
          .doc(walk.walkId)
          .set(
        {
          'walkerId':
              walkerUid,

          'walkerUid':
              walkerUid,

          'walkerName':
              walkerName,

          'walkerPhone':
              walkerPhone,

          'ownerId':
              walk.ownerId,

          'ownerUid':
              walk.ownerUid,

          'ownerName':
              walk.ownerName,

          'ownerPhone':
              walk.ownerPhone ?? '',

          'status':
              'ACTIVE',

          'connectionStatus':
              'connected',

          'connected':
              true,

          'walkerConnected':
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
    }

    return walk.walkId;
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

  static Future<void> scanConnectAndOpenLiveWalk(
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
      throw Exception(
        'Owner UID is missing.',
      );
    }

    if (walk.walkId.trim().isEmpty) {
      throw Exception(
        'Live Walk ID is missing.',
      );
    }

    if (!context.mounted) {
      return;
    }

    // ==========================================================
    // OPEN LIVE WALK
    // ==========================================================

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveWalkScreen(
          // IMPORTANT:
          // LiveWalkScreen ownerUid gets Firebase UID.
          ownerUid: walk.ownerUid,

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
        ),
      ),
    );
  }

  // ============================================================
  // GET MY ACTIVE LIVE WALK
  //
  // NEW:
  // liveWalkSessions
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
  // WATCH LIVE WALK
  //
  // NEW:
  // liveWalkSessions/{walkId}
  // ============================================================

  static Stream<
      DocumentSnapshot<Map<String, dynamic>>>
      watchWalk(
    String walkId,
  ) {
    return _liveWalkSessions
        .doc(walkId)
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

    await _liveWalkSessions
        .doc(walkId)
        .set(
      {
        'walkerLocation': {
          'latitude':
              latitude,
          'longitude':
              longitude,
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
  }

  // ============================================================
  // UPDATE PEE / POOP
  //
  // New flow:
  // liveWalkSessions/{walkId}
  // ============================================================

  static Future<void> updateWalkStats({
    required String walkId,
    required int peeCount,
    required int poopCount,
  }) async {
    if (walkId.trim().isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    await _liveWalkSessions
        .doc(walkId)
        .set(
      {
        'peeCount':
            peeCount,

        'poopCount':
            poopCount,

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // COMPLETE WALK
  //
  // liveWalkSessions
  //       ↓
  // walk_history
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
        Map<String, dynamic>> sessionRef =
        _liveWalkSessions.doc(
      walkId,
    );

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
    // SAVE WALK HISTORY
    // ==========================================================

    await _walkHistory
        .doc(walkId)
        .set(
      {
        ...data,

        'walkId':
            walkId,

        'status':
            'COMPLETED',

        'connectionStatus':
            'completed',

        'walkEnded':
            true,

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walker.uid,

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
    // COMPLETE LIVE SESSION
    // ==========================================================

    await sessionRef.set(
      {
        'status':
            'COMPLETED',

        'connectionStatus':
            'completed',

        'walkEnded':
            true,

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walker.uid,

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
    // RESET QR CONNECTION
    //
    // qr_connections/{ownerUid}
    // ==========================================================

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

          'walkerPhone':
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
}

/// ============================================================
/// WALKER WALK DATA
/// ============================================================

class WalkerWalkData {
  /// Owner business ID.
  final String ownerId;

  /// Firebase Auth UID of owner.
  final String ownerUid;

  final String ownerName;
  final String? ownerPhone;

  /// liveWalkSessions document ID.
  final String walkId;

  final String dogName;
  final String dogBreed;

  /// Firebase Auth UID of walker.
  final String walkerUid;

  const WalkerWalkData({
    required this.ownerId,
    required this.ownerUid,
    required this.ownerName,
    required this.ownerPhone,
    required this.walkId,
    required this.dogName,
    required this.dogBreed,
    required this.walkerUid,
  });
}
