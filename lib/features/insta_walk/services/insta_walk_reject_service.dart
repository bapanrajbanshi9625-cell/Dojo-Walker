// File:
// lib/features/insta_walk/services/insta_walk_reject_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../walks/services/walk_request_sound_service.dart';

/// ============================================================
/// INSTA WALK REJECT SERVICE
///
/// Firestore:
///
/// walk_request/{walkId}
///
/// Private rejection:
///
/// walk_request/{walkId}/rejections/{walkerId}
///
/// FLOW:
///
/// searching
///    │
///    ├── Walker A rejects
///    │      ↓
///    │   rejection saved for Walker A
///    │      ↓
///    │   main request remains searching
///    │
///    └── Walker B can still accept
///
/// IMPORTANT:
/// - Reject करने पर main walk request delete/update नहीं होती.
/// - status "searching" ही रहता है.
/// - केवल current Walker की rejection save होती है.
/// - जिसने reject किया है वह उसी request को दोबारा accept नहीं कर सकता.
/// - दूसरा Walker उसी request को accept कर सकता है.
/// - Request sound केवल successful rejection के बाद बंद होता है.
/// ============================================================

class InstaWalkRejectService {
  InstaWalkRejectService._();

  static final InstaWalkRejectService instance =
      InstaWalkRejectService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // MAIN COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_request');
  }

  // ============================================================
  // CURRENT WALKER ID
  //
  // Firebase Auth:
  //     users/auth UID
  //
  // Firestore:
  //     walkers/{authUid}
  //
  // Example:
  //
  // walkers/abc123
  // {
  //   walkerId: "WALKER001"
  // }
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String uid = user.uid.trim();

    if (uid.isEmpty) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot = await _firestore
            .collection('walkers')
            .doc(uid)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      return null;
    }

    final String walkerId =
        data['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      return null;
    }

    return walkerId;
  }

  // ============================================================
  // REJECTIONS COLLECTION
  //
  // walk_request/{walkId}/rejections/{walkerId}
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      _rejections(String walkId) {
    return _walkRequests
        .doc(walkId)
        .collection('rejections');
  }

  // ============================================================
  // REJECT WALK
  // ============================================================

  Future<void> rejectWalk(String walkId) async {
    // ==========================================================
    // AUTHENTICATED WALKER
    // ==========================================================

    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid = user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    // ==========================================================
    // WALKER ID
    // ==========================================================

    final String? walkerId =
        await getCurrentWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID not found in walkers collection.',
      );
    }

    final String cleanWalkerId =
        walkerId.trim();

    // ==========================================================
    // WALK ID
    // ==========================================================

    final String id = walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ==========================================================
    // MAIN WALK REQUEST
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    // ==========================================================
    // THIS WALKER'S REJECTION DOCUMENT
    //
    // Example:
    //
    // walk_request/
    //   WALK123/
    //     rejections/
    //       WALKER001
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        rejectionRef =
        walkRef
            .collection('rejections')
            .doc(cleanWalkerId);

    // ==========================================================
    // TRANSACTION
    //
    // Transaction ensures:
    //
    // 1. Request still exists.
    // 2. Request is still searching.
    // 3. This Walker has not already rejected it.
    // 4. Rejection is saved atomically.
    //
    // IMPORTANT:
    // walkRef is NEVER updated.
    // ==========================================================

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ------------------------------------------------------
        // READ MAIN REQUEST FIRST
        // ------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>>
            walkSnapshot =
            await transaction.get(walkRef);

        if (!walkSnapshot.exists) {
          throw Exception(
            'Walk request no longer exists.',
          );
        }

        final Map<String, dynamic>? data =
            walkSnapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        // ------------------------------------------------------
        // CHECK STATUS
        // ------------------------------------------------------

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (status != 'searching') {
          throw Exception(
            'This walk is no longer available.',
          );
        }

        // ------------------------------------------------------
        // CHECK PREVIOUS REJECTION
        // ------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>>
            rejectionSnapshot =
            await transaction.get(
          rejectionRef,
        );

        if (rejectionSnapshot.exists) {
          throw Exception(
            'You already rejected this walk.',
          );
        }

        // ------------------------------------------------------
        // SAVE PRIVATE REJECTION
        //
        // Main walk document remains unchanged.
        // ------------------------------------------------------

        transaction.set(
          rejectionRef,
          <String, dynamic>{
            'walkerId': cleanWalkerId,
            'walkerUid': walkerUid,
            'walkId': id,
            'rejectedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );

    // ==========================================================
    // SUCCESS
    //
    // Firestore transaction सफल होने के बाद ही
    // incoming request sound बंद करें.
    // ==========================================================

    try {
      await WalkRequestSoundService.instance
          .stopRequest(id);
    } catch (e) {
      // Sound stop failure should not make
      // a successful Firestore rejection fail.
      //
      // Rejection has already been saved.
      //
      // ignore: avoid_print
      print(
        'Unable to stop walk request sound: $e',
      );
    }
  }
}
