// File:
// lib/features/insta_walk/services/insta_walk_reject_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../walks/services/walk_request_sound_service.dart';

class InstaWalkRejectService {
  InstaWalkRejectService._();

  static final InstaWalkRejectService instance =
      InstaWalkRejectService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // WALK REQUEST
  //
  // IMPORTANT:
  // Owner/Admin uses:
  //
  //     walk_request
  //
  // NOT:
  //
  //     walk_requests
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_request');
  }

  // ============================================================
  // CURRENT WALKER ID
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
        data['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      return null;
    }

    return walkerId;
  }

  // ============================================================
  // REJECTIONS
  //
  // Structure:
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
  //
  // Main request remains:
  //
  //     status = searching
  //
  // Only this Walker's rejection is saved.
  // ============================================================

  Future<void> rejectWalk(String walkId) async {
    // ----------------------------------------------------------
    // CURRENT AUTH USER
    // ----------------------------------------------------------

    final User? user = _auth.currentUser;

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
    // CURRENT WALKER ID
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // MAIN WALK DOCUMENT
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    // ----------------------------------------------------------
    // THIS WALKER'S PRIVATE REJECTION DOCUMENT
    //
    // walk_request/{walkId}/rejections/{walkerId}
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>>
        rejectionRef =
        _rejections(id).doc(cleanWalkerId);

    // ----------------------------------------------------------
    // TRANSACTION
    // ----------------------------------------------------------

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ======================================================
        // READ MAIN WALK REQUEST
        // ======================================================

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

        // ======================================================
        // CHECK STATUS
        // ======================================================

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

        // ======================================================
        // CHECK THIS WALKER ALREADY REJECTED
        // ======================================================

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

        // ======================================================
        // SAVE ONLY THIS WALKER'S REJECTION
        // ======================================================

        transaction.set(
          rejectionRef,
          <String, dynamic>{
            'walkerId': cleanWalkerId,
            'walkerUid': walkerUid,
            'rejectedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        // ======================================================
        // IMPORTANT
        //
        // DO NOT UPDATE walkRef.
        //
        // status remains:
        //
        //     searching
        //
        // Another Walker can still receive this request.
        // ======================================================
      },
    );

    // ==========================================================
    // REJECT SUCCESS → STOP REQUEST SOUND
    //
    // This is intentionally OUTSIDE the transaction.
    // Firestore rejection must succeed first.
    // ==========================================================

    await WalkRequestSoundService.instance
        .stopRequest(id);
  }
}
