import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'incoming_walk_sound_service.dart';

class IncomingWalkRejectService {
  IncomingWalkRejectService._();

  static final IncomingWalkRejectService instance =
      IncomingWalkRejectService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // WALK REQUEST COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _walkRequests =>
      _firestore.collection('walk_request');

  // ============================================================
  // CURRENT WALKER ID
  //
  // Walker ID = Firebase Auth UID.
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

    // Canonical Walker ID is the Firebase Auth UID.
    return uid;
  }

  // ============================================================
  // REJECT WALK
  //
  // walk_request/{walkId}
  //
  // rejection:
  //
  // walk_request/{walkId}/rejections/{walkerUid}
  //
  // type:
  //   rejected = manual Walker rejection
  //
  // IMPORTANT:
  // Main request remains:
  //
  // status = searching
  //
  // Only the current Walker's claim is released.
  //
  // Therefore the same request can go to another Walker.
  // ============================================================

  Future<void> rejectWalk(
    String walkId,
  ) async {
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

    // Walker ID = Firebase Auth UID.
    final String cleanWalkerId = walkerUid;

    final String id = walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<Map<String, dynamic>> walkRef =
        _walkRequests.doc(id);

    // Rejection document ID is the Walker Auth UID.
    final DocumentReference<Map<String, dynamic>> rejectionRef =
        walkRef
            .collection('rejections')
            .doc(walkerUid);

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // --------------------------------------------------------
        // READ MAIN REQUEST
        // --------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>> walkSnapshot =
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
        //
        // Reject must only happen while the request is searching.
        // We do NOT change status to cancelled.
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
        // CURRENT INCOMING CLAIM
        // --------------------------------------------------------

        final String incomingWalkerUid =
            data['incomingWalkerUid']
                    ?.toString()
                    .trim() ??
                '';

        // Another Walker currently owns this offer.
        if (incomingWalkerUid.isNotEmpty &&
            incomingWalkerUid != walkerUid) {
          throw Exception(
            'This walk is assigned to another walker.',
          );
        }

        // --------------------------------------------------------
        // DUPLICATE REJECTION CHECK
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
        // SAVE REJECTION
        //
        // Walker ID = Auth UID.
        // --------------------------------------------------------

        transaction.set(
          rejectionRef,
          <String, dynamic>{
            'walkerId': cleanWalkerId,
            'walkerUid': walkerUid,
            'type': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // RELEASE ONLY THIS WALKER'S CLAIM
        //
        // IMPORTANT:
        // Do NOT delete incomingWalkerId.
        //
        // Current Firestore Rules only allow:
        //   incomingWalkerUid
        //   incomingClaimedAt
        //   updatedAt
        //
        // status remains SEARCHING.
        // --------------------------------------------------------

        if (incomingWalkerUid == walkerUid) {
          transaction.update(
            walkRef,
            <String, dynamic>{
              'incomingWalkerUid': FieldValue.delete(),
              'incomingClaimedAt': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      },
    );

    // ----------------------------------------------------------
    // STOP INCOMING RING/SOUND
    // ONLY AFTER FIRESTORE SUCCESS
    // ----------------------------------------------------------

    await IncomingWalkSoundService.instance.stopRequest(id);
  }
}
