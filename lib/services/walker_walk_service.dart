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
      /// ------------------------------------------------------
      /// PARSE OWNER QR
      /// ------------------------------------------------------

      final String rawQr = scannedData.trim();

      if (rawQr.isEmpty) {
        throw Exception(
          'QR code is empty.',
        );
      }

      final dynamic decoded;

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

      /// ------------------------------------------------------
      /// VALIDATE WALKER LOGIN
      /// ------------------------------------------------------

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

      /// ------------------------------------------------------
      /// READ QR FIELDS
      /// ------------------------------------------------------

      final String ownerId =
          (qr['ownerId'] ?? '').toString().trim();

      final String ownerName =
          (qr['ownerName'] ?? '').toString().trim();

      final String walkId =
          (qr['walkId'] ?? '').toString().trim();

      /// ------------------------------------------------------
      /// VALIDATE QR DATA
      /// ------------------------------------------------------

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

      /// ------------------------------------------------------
      /// RETURN WALK DATA
      ///
      /// Dog information is NOT required from QR.
      /// It can be loaded from Firestore later.
      /// ------------------------------------------------------

      return WalkerWalkData(
        ownerId: ownerId,
        ownerName: ownerName.isEmpty
            ? 'Owner'
            : ownerName,
        ownerPhone: null,
        walkId: walkId,
        dogName: 'Dog',
        dogBreed: '',
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

    /// --------------------------------------------------------
    /// ACTIVE WALK DOCUMENT
    /// --------------------------------------------------------

    final DocumentReference<
            Map<String, dynamic>>
        activeRef =
        _firestore
            .collection('active_walks')
            .doc(walk.walkId);

    /// --------------------------------------------------------
    /// CHECK EXISTING WALK
    /// --------------------------------------------------------

    final DocumentSnapshot<
            Map<String, dynamic>>
        existing =
        await activeRef.get();

    if (existing.exists) {
      final Map<String, dynamic> data =
          existing.data() ??
              <String, dynamic>{};

      final String status =
          (data['status'] ?? '').toString();

      final String existingWalker =
          (data['walkerUid'] ?? '').toString();

      final String existingOwner =
          (data['ownerId'] ?? '').toString();

      /// Same walker already connected.
      if (status == 'active' &&
          existingWalker == walkerUid &&
          existingOwner == walk.ownerId) {
        return walk.walkId;
      }

      /// Another walker is already using this walk.
      if (status == 'active') {
        throw Exception(
          'This Walk is already active.',
        );
      }
    }

    /// --------------------------------------------------------
    /// WALKER DETAILS
    /// --------------------------------------------------------

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

    /// --------------------------------------------------------
    /// CREATE ACTIVE WALK
    /// --------------------------------------------------------

    await activeRef.set(
      {
        'walkId': walk.walkId,

        'status': 'active',
        'connectionStatus': 'connected',
        'isLive': true,

        /// OWNER
        'ownerId': walk.ownerId,
        'ownerName': walk.ownerName,
        'ownerPhone': walk.ownerPhone ?? '',

        /// WALKER
        'walkerUid': walkerUid,
        'walkerName': walkerName,
        'walkerPhone': walkerPhone,

        /// DOG
        'dogName': walk.dogName,
        'dogBreed': walk.dogBreed,

        /// CONNECTION
        'connectedBy': walkerUid,
        'connectedAt':
            FieldValue.serverTimestamp(),

        /// TIME
        'startedAt':
            FieldValue.serverTimestamp(),
        'endedAt': null,

        /// LOCATION
        'ownerLocation': null,
        'walkerLocation': null,

        'ownerLocationUpdatedAt': null,
        'walkerLocationUpdatedAt': null,

        /// SCAN
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

    /// --------------------------------------------------------
    /// UPDATE OWNER QR CONNECTION
    ///
    /// Current QRService stores:
    /// qr_connections/{Firebase UID}
    ///
    /// इसलिए ownerId से document खोजते हैं.
    /// --------------------------------------------------------

    final QuerySnapshot<
            Map<String, dynamic>>
        qrResult =
        await _firestore
            .collection('qr_connections')
            .where(
              'ownerId',
              isEqualTo: walk.ownerId,
            )
            .limit(1)
            .get();

    if (qrResult.docs.isNotEmpty) {
      await qrResult.docs.first.reference.set(
        {
          'ownerId': walk.ownerId,

          'walkerId': walkerUid,
          'walkerName': walkerName,

          'walkId': walk.walkId,
          'activeWalkId': walk.walkId,

          'scanned': true,
          'connected': true,

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

    return walk.walkId;
  }

  /// ==========================================================
  /// SCAN + CONNECT
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

  /// ==========================================================
  /// SCAN + CONNECT + OPEN LIVE WALK
  /// ==========================================================

  static Future<void> scanConnectAndOpenLiveWalk(
    BuildContext context,
  ) async {
    final WalkerWalkData? walk =
        await scanOwnerQr(context);

    if (walk == null) {
      return;
    }

    try {
      /// ------------------------------------------------------
      /// CONNECT
      /// ------------------------------------------------------

      await connectWithOwner(walk);

      if (!context.mounted) {
        return;
      }

      /// ------------------------------------------------------
      /// OPEN LIVE WALK DIRECTLY
      /// ------------------------------------------------------

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

    if (walk.ownerId.trim().isEmpty) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Owner ID is missing.',
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

    /// --------------------------------------------------------
    /// LIVE WALK
    /// --------------------------------------------------------

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
  /// GET ACTIVE WALK FOR CURRENT WALKER
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

    if (walkId.trim().isEmpty) {
      throw Exception(
        'Walk ID is missing.',
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

    if (walkId.trim().isEmpty) {
      throw Exception(
        'Walk ID is missing.',
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

    /// --------------------------------------------------------
    /// SAVE TO WALK HISTORY
    /// --------------------------------------------------------

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

    /// --------------------------------------------------------
    /// MARK ACTIVE WALK COMPLETED
    /// --------------------------------------------------------

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

    /// --------------------------------------------------------
    /// RESET OWNER QR
    /// --------------------------------------------------------

    final String ownerId =
        (data['ownerId'] ?? '')
            .toString()
            .trim();

    if (ownerId.isNotEmpty) {
      final QuerySnapshot<
              Map<String, dynamic>>
          qrResult =
          await _firestore
              .collection('qr_connections')
              .where(
                'ownerId',
                isEqualTo: ownerId,
              )
              .limit(1)
              .get();

      if (qrResult.docs.isNotEmpty) {
        await qrResult.docs.first.reference.set(
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
}

/// ============================================================
/// WALKER WALK DATA
/// ============================================================

class WalkerWalkData {
  final String ownerId;
  final String ownerName;
  final String? ownerPhone;
  final String walkId;

  /// QR से अभी dog details नहीं आतीं.
  /// बाद में Firestore से भर सकते हैं.
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
