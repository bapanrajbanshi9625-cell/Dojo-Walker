// File:
// lib/features/insta_walk/services/insta_walk_request_action_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// INSTA WALK REQUEST ACTION SERVICE
///
/// जिम्मेदारी:
///
/// 1. Accept Insta Walk
/// 2. Reject Insta Walk
///
/// Reject का नियम:
///
/// walk_requests/{walkId}
///     status = "searching"
///
/// walk_requests/{walkId}/rejections/{walkerId}
///     walkerId
///     walkerUid
///     rejectedAt
///
/// IMPORTANT:
///
/// Reject करने पर main request का status
/// "rejected" नहीं होगा.
///
/// Main request:
///     status = "searching"
///
/// इससे दूसरा Walker वही request देख सकता है.
///
/// लेकिन जिस Walker ने reject किया:
///     उसे request दोबारा नहीं दिखेगी.
/// ============================================================

class InstaWalkRequestActionService {
  InstaWalkRequestActionService._();

  static final InstaWalkRequestActionService instance =
      InstaWalkRequestActionService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_requests');
  }

  // ============================================================
  // CURRENT FIREBASE AUTH UID
  // ============================================================

  String? get currentWalkerUid {
    final User? user = _auth.currentUser;

    final String uid =
        user?.uid.trim() ?? '';

    if (uid.isEmpty) {
      return null;
    }

    return uid;
  }

  // ============================================================
  // GET CURRENT WALKER ID
  //
  // walkers/{FirebaseAuthUID}
  //
  // Example:
  //
  // walkers/abc123
  //     walkerId: WALKER001
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final String? uid =
        currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
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
        data['walkerId']
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      return null;
    }

    return walkerId;
  }

  // ============================================================
  // REJECTIONS
  //
  // walk_requests/{walkId}/rejections/{walkerId}
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      _rejections(
    String walkId,
  ) {
    return _walkRequests
        .doc(walkId)
        .collection('rejections');
  }

  // ============================================================
  // ACCEPT WALK
  //
  // searching → accepted
  // ============================================================

  Future<void> acceptWalk(
    String walkId,
  ) async {
    // ----------------------------------------------------------
    // AUTH
    // ----------------------------------------------------------

    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    // ----------------------------------------------------------
    // WALKER ID
    // ----------------------------------------------------------

    final String? walkerId =
        await getCurrentWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID not found in walkers collection.',
      );
    }

    // ----------------------------------------------------------
    // WALK ID
    // ----------------------------------------------------------

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    final DocumentReference<
            Map<String, dynamic>>
        rejectionRef =
        _rejections(id).doc(walkerId);

    // ----------------------------------------------------------
    // TRANSACTION
    // ----------------------------------------------------------

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ------------------------------------------------------
        // READ WALK
        // ------------------------------------------------------

        final DocumentSnapshot<
                Map<String, dynamic>>
            walkSnapshot =
            await transaction.get(
          walkRef,
        );

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
        // STATUS
        // ------------------------------------------------------

        final String status =
            data['status']
                    ?.toString()
                    .trim() ??
                '';

        if (status != 'searching') {
          throw Exception(
            'This walk is no longer available.',
          );
        }

        // ------------------------------------------------------
        // CHECK WHETHER THIS WALKER REJECTED IT
        // ------------------------------------------------------

        final DocumentSnapshot<
                Map<String, dynamic>>
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
        // ACCEPT
        // ------------------------------------------------------

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'accepted',

            'walkerId': walkerId,

            'walkerUid': walkerUid,

            'acceptedBy': walkerId,

            'acceptedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // REJECT WALK
  //
  // IMPORTANT:
  //
  // Main request:
  //     status = searching
  //
  // Rejection:
  //     rejections/{walkerId}
  //
  // इसलिए दूसरे Walker को request मिलती रहेगी.
  // ============================================================

  Future<void> rejectWalk(
    String walkId,
  ) async {
    // ----------------------------------------------------------
    // AUTH
    // ----------------------------------------------------------

    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    // ----------------------------------------------------------
    // WALKER ID
    // ----------------------------------------------------------

    final String? walkerId =
        await getCurrentWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID not found in walkers collection.',
      );
    }

    // ----------------------------------------------------------
    // WALK ID
    // ----------------------------------------------------------

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    final DocumentReference<
            Map<String, dynamic>>
        rejectionRef =
        _rejections(id).doc(walkerId);

    // ----------------------------------------------------------
    // TRANSACTION
    // ----------------------------------------------------------

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ------------------------------------------------------
        // READ WALK
        // ------------------------------------------------------

        final DocumentSnapshot<
                Map<String, dynamic>>
            walkSnapshot =
            await transaction.get(
          walkRef,
        );

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
        // STATUS
        // ------------------------------------------------------

        final String status =
            data['status']
                    ?.toString()
                    .trim() ??
                '';

        if (status != 'searching') {
          throw Exception(
            'This walk is no longer available.',
          );
        }

        // ------------------------------------------------------
        // CHECK DUPLICATE REJECTION
        // ------------------------------------------------------

        final DocumentSnapshot<
                Map<String, dynamic>>
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
        // SAVE REJECTION
        //
        // walk_requests/{walkId}
        //     rejections/{walkerId}
        // ------------------------------------------------------

        transaction.set(
          rejectionRef,
          <String, dynamic>{
            'walkerId': walkerId,

            'walkerUid': walkerUid,

            'rejectedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        // ------------------------------------------------------
        // KEEP MAIN REQUEST SEARCHING
        // ------------------------------------------------------

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'searching',

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }
}
