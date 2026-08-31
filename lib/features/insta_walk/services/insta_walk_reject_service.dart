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
  // WALK REQUEST COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests =>
          _firestore.collection('walk_request');

  // ============================================================
  // CURRENT WALKER ID
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String uid =
        user.uid.trim();

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
  // REJECT WALK
  //
  // Main document remains:
  //
  // walk_request/{walkId}
  //
  // Rejection:
  //
  // walk_request/{walkId}/rejections/{walkerId}
  // ============================================================

  Future<void> rejectWalk(
    String walkId,
  ) async {
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

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    final DocumentReference<Map<String, dynamic>>
        rejectionRef =
        walkRef
            .collection('rejections')
            .doc(cleanWalkerId);

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // --------------------------------------------------------
        // READ MAIN REQUEST
        // --------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>>
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

        // --------------------------------------------------------
        // STATUS
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // CHECK DUPLICATE REJECTION
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // SAVE WALKER REJECTION
        // --------------------------------------------------------

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

        // --------------------------------------------------------
        // IMPORTANT:
        //
        // Main walk_request document is NOT modified.
        //
        // status remains:
        //
        // searching
        //
        // Therefore another Walker can still receive it.
        // --------------------------------------------------------
      },
    );

    // ----------------------------------------------------------
    // STOP SOUND ONLY AFTER FIRESTORE SUCCESS
    // ----------------------------------------------------------

    await WalkRequestSoundService.instance
        .stopRequest(id);
  }
}
