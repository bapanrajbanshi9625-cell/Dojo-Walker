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
  // Call this after Walker successfully scans Owner QR.
  // =====================================================

  Future<String> connectWithOwner({
    required Map<String, dynamic> qrData,
  }) async {
    // ---------------------------------------------------
    // CURRENT WALKER
    // ---------------------------------------------------

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
        'Walker UID is missing.',
      );
    }

    // ---------------------------------------------------
    // OWNER INFORMATION FROM QR
    // ---------------------------------------------------

    final String ownerUid =
        (qrData['ownerUid'] ??
                qrData['uid'] ??
                qrData['userId'] ??
                '')
            .toString()
            .trim();

    if (ownerUid.isEmpty) {
      throw Exception(
        'Owner UID is missing from QR code.',
      );
    }

    final String ownerName =
        (qrData['ownerName'] ??
                qrData['name'] ??
                'Owner')
            .toString()
            .trim();

    final String ownerPhone =
        (qrData['ownerPhone'] ??
                qrData['phoneNumber'] ??
                '')
            .toString()
            .trim();

    final String qrWalkId =
        (qrData['walkId'] ?? '')
            .toString()
            .trim();

    // ---------------------------------------------------
    // CREATE NEW WALK ID
    // ---------------------------------------------------

    final String walkId =
        qrWalkId.isNotEmpty
            ? qrWalkId
            : 'WALK_${DateTime.now().millisecondsSinceEpoch}';

    // ---------------------------------------------------
    // WALKER INFORMATION
    // ---------------------------------------------------

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

    // ---------------------------------------------------
    // ACTIVE WALK DOCUMENT
    // ---------------------------------------------------

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _firestore
            .collection('active_walks')
            .doc(walkId);

    // ---------------------------------------------------
    // CHECK WHETHER THIS WALK ALREADY EXISTS
    // ---------------------------------------------------

    final DocumentSnapshot<
            Map<String, dynamic>>
        existing =
        await walkRef.get();

    if (existing.exists) {
      final Map<String, dynamic> existingData =
          existing.data() ??
              <String, dynamic>{};

      final String existingStatus =
          existingData['status']
                  ?.toString() ??
              '';

      // Same active walk is already connected.
      if (existingStatus == 'active') {
        return walkId;
      }
    }

    // ---------------------------------------------------
    // CREATE ACTIVE WALK
    // ---------------------------------------------------

    await walkRef.set(
      {
        // ===============================================
        // WALK
        // ===============================================

        'walkId': walkId,
        'status': 'active',
        'connectionStatus': 'connected',

        // ===============================================
        // OWNER
        // ===============================================

        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // ===============================================
        // WALKER
        // ===============================================

        'walkerUid': walkerUid,
        'walkerName': walkerName,
        'walkerPhone': walkerPhone,

        // ===============================================
        // QR INFORMATION
        // ===============================================

        'qrWalkId': qrWalkId,
        'connectedBy': walkerUid,
        'connectedAt':
            FieldValue.serverTimestamp(),

        // ===============================================
        // WALK TIME
        // ===============================================

        'startedAt':
            FieldValue.serverTimestamp(),

        'endedAt': null,

        // ===============================================
        // LOCATION
        // ===============================================
        //
        // These fields will be updated by GPS service.
        //

        'ownerLocation': null,
        'walkerLocation': null,

        // ===============================================
        // LOCATION HISTORY
        // ===============================================

        'ownerLocationUpdatedAt': null,
        'walkerLocationUpdatedAt': null,

        // ===============================================
        // SCAN INFORMATION
        // ===============================================

        'ownerScanned': false,
        'walkerScanned': true,

        'scannedAt':
            FieldValue.serverTimestamp(),

        // ===============================================
        // SAFETY / CONNECTION
        // ===============================================

        'isLive': true,
        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ---------------------------------------------------
    // ALSO UPDATE OWNER QR DOCUMENT
    // ---------------------------------------------------

    await _firestore
        .collection('qr_codes')
        .doc(ownerUid)
        .set(
      {
        'scanned': true,
        'scannedBy': walkerUid,
        'scannedByName': walkerName,
        'scannedAt':
            FieldValue.serverTimestamp(),

        'activeWalkId': walkId,

        'connectedWalkerUid':
            walkerUid,

        'connectedWalkerName':
            walkerName,

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

  Future<DocumentSnapshot<
      Map<String, dynamic>>?> getMyActiveWalk() async {
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

  // =====================================================
  // LISTEN TO ACTIVE WALK
  // =====================================================

  Stream<DocumentSnapshot<
      Map<String, dynamic>>> watchWalk(
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

  // =====================================================
  // END WALK
  // =====================================================

  Future<void> completeWalk({
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

    // ---------------------------------------------------
    // MARK ACTIVE WALK AS COMPLETED
    // ---------------------------------------------------

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

    // ---------------------------------------------------
    // UPDATE OWNER QR
    // ---------------------------------------------------

    final String ownerUid =
        data['ownerUid']
                ?.toString() ??
            '';

    if (ownerUid.isNotEmpty) {
      await _firestore
          .collection('qr_codes')
          .doc(ownerUid)
          .set(
        {
          'scanned': false,
          'activeWalkId': null,

          'connectedWalkerUid': null,
          'connectedWalkerName': null,

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
