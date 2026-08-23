// File location:
// lib/features/walker_connection/walker_connection_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WalkerConnectionService {
  WalkerConnectionService._();

  static final WalkerConnectionService instance =
      WalkerConnectionService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // =====================================================
  // CONNECT WALKER WITH OWNER
  // =====================================================

  Future<String> connectWithOwner({
    required Map<String, dynamic> qrData,
  }) async {
    // ---------------------------------------------------
    // CURRENT WALKER
    // ---------------------------------------------------

    final User? walker = _auth.currentUser;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid = walker.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    // ---------------------------------------------------
    // OWNER UID FROM QR
    //
    // Accept both formats so old/new QR payloads
    // do not break the scanner.
    // ---------------------------------------------------

    final String ownerUid =
        (
          qrData['ownerUid'] ??
          qrData['ownerId'] ??
          qrData['uid'] ??
          qrData['userId'] ??
          ''
        )
            .toString()
            .trim();

    if (ownerUid.isEmpty) {
      throw Exception(
        'Owner information is missing from QR code.',
      );
    }

    // ---------------------------------------------------
    // QR TYPE VALIDATION
    // ---------------------------------------------------

    final String qrType =
        (qrData['type'] ?? '')
            .toString()
            .trim();

    if (qrType.isNotEmpty &&
        qrType != 'dojo_owner_qr') {
      throw Exception(
        'This is not a valid Owner QR Code.',
      );
    }

    // ---------------------------------------------------
    // OWNER NAME
    // ---------------------------------------------------

    final String ownerName =
        (
          qrData['ownerName'] ??
          qrData['name'] ??
          'Owner'
        )
            .toString()
            .trim();

    // ---------------------------------------------------
    // OPTIONAL OWNER PHONE
    // ---------------------------------------------------

    final String ownerPhone =
        (
          qrData['ownerPhone'] ??
          qrData['phoneNumber'] ??
          ''
        )
            .toString()
            .trim();

    // ---------------------------------------------------
    // WALK ID FROM QR
    // ---------------------------------------------------

    final String qrWalkId =
        (qrData['walkId'] ?? '')
            .toString()
            .trim();

    // ---------------------------------------------------
    // WALK ID
    // ---------------------------------------------------

    final String walkId =
        qrWalkId.isNotEmpty
            ? qrWalkId
            : 'WALK_${DateTime.now().millisecondsSinceEpoch}';

    // ---------------------------------------------------
    // WALKER INFORMATION
    // ---------------------------------------------------

    final String walkerName =
        walker.displayName?.trim().isNotEmpty == true
            ? walker.displayName!.trim()
            : 'Walker';

    final String walkerPhone =
        walker.phoneNumber?.trim().isNotEmpty == true
            ? walker.phoneNumber!.trim()
            : '';

    // ===================================================
    // ACTIVE WALK
    // ===================================================

    final DocumentReference<Map<String, dynamic>> walkRef =
        _firestore
            .collection('active_walks')
            .doc(walkId);

    // ---------------------------------------------------
    // CHECK EXISTING WALK
    // ---------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>> existing =
        await walkRef.get();

    if (existing.exists) {
      final Map<String, dynamic> existingData =
          existing.data() ?? <String, dynamic>{};

      final String existingStatus =
          existingData['status']?.toString() ?? '';

      final String existingWalkerUid =
          existingData['walkerUid']?.toString() ?? '';

      final String existingOwnerUid =
          existingData['ownerUid']?.toString() ?? '';

      if (existingStatus == 'active' &&
          existingWalkerUid == walkerUid &&
          existingOwnerUid == ownerUid) {
        return walkId;
      }

      if (existingStatus == 'active' &&
          existingOwnerUid != ownerUid) {
        throw Exception(
          'This Walk ID is already active.',
        );
      }
    }

    // ===================================================
    // CREATE ACTIVE WALK
    // ===================================================

    await walkRef.set(
      {
        // -----------------------------------------------
        // WALK
        // -----------------------------------------------

        'walkId': walkId,
        'status': 'active',
        'connectionStatus': 'connected',

        // -----------------------------------------------
        // OWNER
        // -----------------------------------------------

        'ownerUid': ownerUid,
        'ownerId': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // -----------------------------------------------
        // WALKER
        // -----------------------------------------------

        'walkerUid': walkerUid,
        'walkerName': walkerName,
        'walkerPhone': walkerPhone,

        // -----------------------------------------------
        // QR
        // -----------------------------------------------

        'qrWalkId': qrWalkId,
        'connectedBy': walkerUid,

        'connectedAt':
            FieldValue.serverTimestamp(),

        // -----------------------------------------------
        // WALK TIME
        // -----------------------------------------------

        'startedAt':
            FieldValue.serverTimestamp(),

        'endedAt': null,

        // -----------------------------------------------
        // LOCATION
        // -----------------------------------------------

        'ownerLocation': null,
        'walkerLocation': null,

        'ownerLocationUpdatedAt': null,
        'walkerLocationUpdatedAt': null,

        // -----------------------------------------------
        // SCAN
        // -----------------------------------------------

        'ownerScanned': false,
        'walkerScanned': true,

        'scannedAt':
            FieldValue.serverTimestamp(),

        // -----------------------------------------------
        // LIVE
        // -----------------------------------------------

        'isLive': true,

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ===================================================
    // UPDATE OWNER QR CONNECTION
    //
    // IMPORTANT:
    // Same collection used by QRService:
    //
    // qr_connections/{ownerUid}
    // ===================================================

    await _firestore
        .collection('qr_connections')
        .doc(ownerUid)
        .set(
      {
        'type': 'dojo_owner_qr',
        'version': 1,

        'ownerId': ownerUid,
        'ownerUid': ownerUid,

        'ownerName': ownerName,

        'walkId': walkId,

        'scanned': true,
        'connected': true,

        'walkerId': walkerUid,
        'walkerName': walkerName,

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

    return walkId;
  }

  // =====================================================
  // GET ACTIVE WALK FOR CURRENT WALKER
  // =====================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      getMyActiveWalk() async {
    final User? walker = _auth.currentUser;

    if (walker == null) {
      return null;
    }

    final QuerySnapshot<Map<String, dynamic>> result =
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

  // =====================================================
  // LISTEN TO ACTIVE WALK
  // =====================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchWalk(
    String walkId,
  ) {
    return _firestore
        .collection('active_walks')
        .doc(walkId)
        .snapshots();
  }

  // =====================================================
  // UPDATE WALKER GPS LOCATION
  // =====================================================

  Future<void> updateWalkerLocation({
    required String walkId,
    required double latitude,
    required double longitude,
  }) async {
    final User? walker = _auth.currentUser;

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

  // =====================================================
  // END WALK
  // =====================================================

  Future<void> completeWalk({
    required String walkId,
  }) async {
    final User? walker = _auth.currentUser;

    if (walker == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final DocumentReference<Map<String, dynamic>> activeRef =
        _firestore
            .collection('active_walks')
            .doc(walkId);

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await activeRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Active walk not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    // ---------------------------------------------------
    // SAVE COMPLETE WALK
    // ---------------------------------------------------

    await _firestore
        .collection('past_walks')
        .doc(walkId)
        .set(
      {
        ...data,

        'status': 'completed',
        'isLive': false,
        'connectionStatus': 'completed',

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy': walker.uid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ---------------------------------------------------
    // MARK ACTIVE WALK COMPLETED
    // ---------------------------------------------------

    await activeRef.update(
      {
        'status': 'completed',
        'isLive': false,
        'connectionStatus': 'completed',

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedBy': walker.uid,

        'completedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    // ---------------------------------------------------
    // OWNER UID
    // ---------------------------------------------------

    final String ownerUid =
        (data['ownerUid'] ??
                data['ownerId'] ??
                '')
            .toString()
            .trim();

    // ---------------------------------------------------
    // RESET QR CONNECTION
    // ---------------------------------------------------

    if (ownerUid.isNotEmpty) {
      await _firestore
          .collection('qr_connections')
          .doc(ownerUid)
          .set(
        {
          'scanned': false,
          'connected': false,

          'walkerId': null,
          'walkerName': null,

          'activeWalkId': null,

          'lastCompletedWalkId': walkId,

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
