// File:
// lib/services/walker_walk_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/qr_scanner_screen.dart';
import 'qr_service.dart';
import '../features/walks/screens/live_walk_screen.dart';

/// ============================================================
/// WALKER WALK SERVICE
/// ============================================================

class WalkerWalkService {
  WalkerWalkService._();

  static final WalkerWalkService instance =
      WalkerWalkService._();

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static final FirebaseAuth _auth =
      FirebaseAuth.instance;

  /// ==========================================================
  /// SCAN OWNER QR
  /// ==========================================================

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
      // --------------------------------------------------------
      // READ OWNER QR
      // --------------------------------------------------------

      final QRData qr =
          QRService.dataFromPayload(
        scannedData,
      );

      // --------------------------------------------------------
      // WALKER AUTH
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
      // RETURN EVERYTHING FROM QR
      // --------------------------------------------------------

      return WalkerWalkData(
        ownerId: qr.ownerId,
        ownerName:
            qr.ownerName.isEmpty
                ? 'Owner'
                : qr.ownerName,
        ownerPhone: qr.ownerPhone,
        walkId: qr.walkId,
        dogName:
            qr.dogName.isEmpty
                ? 'Dog'
                : qr.dogName,
        dogBreed: qr.dogBreed,
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

  /// ==========================================================
  /// CONNECT WALKER WITH OWNER
  /// ==========================================================

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

    final DocumentReference<
            Map<String, dynamic>>
        activeRef =
        _firestore
            .collection('active_walks')
            .doc(walk.walkId);

    // --------------------------------------------------------
    // CHECK EXISTING WALK
    // --------------------------------------------------------

    final DocumentSnapshot<
            Map<String, dynamic>>
        existing =
        await activeRef.get();

    if (existing.exists) {
      final Map<String, dynamic> data =
          existing.data() ??
              <String, dynamic>{};

      final String status =
          (data['status'] ?? '')
              .toString();

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

      if (status == 'active') {
        throw Exception(
          'This Walk is already active.',
        );
      }
    }

    // --------------------------------------------------------
    // WALKER INFO
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // CREATE ACTIVE WALK
    // --------------------------------------------------------

    await activeRef.set(
      {
        'walkId': walk.walkId,

        'status': 'active',
        'connectionStatus': 'connected',
        'isLive': true,

        // OWNER
        'ownerId': walk.ownerId,
        'ownerUid': walk.ownerId,
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

    // --------------------------------------------------------
    // UPDATE OWNER QR CONNECTION
    // --------------------------------------------------------

    await _firestore
        .collection('qr_connections')
        .doc(walk.ownerId)
        .set(
      {
        'type': 'dojo_owner_qr',
        'ownerId': walk.ownerId,

        'scanned': true,
        'connected': true,

        'walkerId': walkerUid,
        'walkerName': walkerName,

        'activeWalkId': walk.walkId,

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

    return walk.walkId;
  }

  /// ==========================================================
  /// SCAN + CONNECT + OPEN LIVE WALK
  /// ==========================================================

  static Future<String?> scanAndConnect(
    BuildContext context,
  ) async {
    final WalkerWalkData? walk =
        await scanOwnerQr(context);

    if (walk == null) {
      return null;
    }

    try {
      // ------------------------------------------------------
      // CONNECT
      // ------------------------------------------------------

      final String walkId =
          await connectWithOwner(walk);

      if (!context.mounted) {
        return walkId;
      }

      // ------------------------------------------------------
      // DIRECTLY OPEN LIVE WALK
      // ------------------------------------------------------

      await openLiveWalk(
        context,
        walk,
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

  /// ==========================================================
  /// OPEN LIVE WALK
  /// ==========================================================

  static Future<void> openLiveWalk(
    BuildContext context,
    WalkerWalkData walk,
  ) async {
    final User? walker =
        _auth.currentUser;

    if (walker == null) {
      return;
    }

    if (walk.ownerId.trim().isEmpty ||
        walk.walkId.trim().isEmpty) {
      return;
    }

    if (!context.mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveWalkScreen(
          ownerUid: walk.ownerId,
          ownerName: walk.ownerName,
          walkId: walk.walkId,
          dogName: walk.dogName,
          dogBreed: walk.dogBreed,
          ownerPhone: walk.ownerPhone,
        ),
      ),
    );
  }

  /// ==========================================================
  /// GET ACTIVE WALK
  /// ==========================================================

  static Future<
      DocumentSnapshot<Map<String, dynamic>>?>
      getMyActiveWalk() async {
    final User? walker =
        _auth.currentUser;

    if (walker == null) {
      return null;
    }

    final QuerySnapshot<
            Map<String, dynamic>>
        result =
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

  /// ==========================================================
  /// WATCH ACTIVE WALK
  /// ==========================================================

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

  /// ==========================================================
  /// UPDATE WALKER LOCATION
  /// ==========================================================

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

  /// ==========================================================
  /// COMPLETE WALK
  /// ==========================================================

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

    final DocumentReference<
            Map<String, dynamic>>
        activeRef =
        _firestore
            .collection('active_walks')
            .doc(walkId);

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await activeRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Active walk not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    // --------------------------------------------------------
    // SAVE HISTORY
    // --------------------------------------------------------

    await _firestore
        .collection('walk_history')
        .doc(walkId)
        .set(
      {
        ...data,

        'status': 'completed',
        'isLive': false,
        'connectionStatus': 'completed',

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

    // --------------------------------------------------------
    // COMPLETE ACTIVE WALK
    // --------------------------------------------------------

    await activeRef.update(
      {
        'status': 'completed',
        'isLive': false,
        'connectionStatus': 'completed',

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy':
            walker.uid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    // --------------------------------------------------------
    // RESET OWNER QR
    // --------------------------------------------------------

    final String ownerId =
        (data['ownerId'] ?? '')
            .toString()
            .trim();

    if (ownerId.isNotEmpty) {
      await _firestore
          .collection('qr_connections')
          .doc(ownerId)
          .set(
        {
          'scanned': false,
          'connected': false,

          'walkerId': null,
          'walkerName': null,

          'activeWalkId': null,

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
  final String ownerId;
  final String ownerName;
  final String? ownerPhone;

  final String walkId;

  final String dogName;
  final String dogBreed;

  const WalkerWalkData({
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.walkId,
    required this.dogName,
    required this.dogBreed,
  });
}
