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

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _firestore.collection('walkers').doc(uid).get();

    if (!snapshot.exists) {
      return uid;
    }

    final Map<String, dynamic>? data = snapshot.data();

    if (data == null) {
      return uid;
    }

    String walkerId =
        data['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      walkerId =
          data['Walker ID']?.toString().trim() ?? '';
    }

    if (walkerId.isEmpty) {
      walkerId = uid;
    }

    return walkerId;
  }

  // ============================================================
  // REJECT WALK
  //
  // walk_request/{walkId}
  //
  // rejection:
  //
  // walk_request/{walkId}/rejections/{walkerId}
  //
  // type:
  //   rejected = manual Walker rejection
  //   timeout  = automatic 3-minute expiry
  //
  // Main request remains:
  //
  // status = searching
  //
  // Current Walker claim is released.
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

    final String? walkerId =
        await getCurrentWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID not found.',
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

    final DocumentReference<Map<String, dynamic>> walkRef =
        _walkRequests.doc(id);

    final DocumentReference<Map<String, dynamic>> rejectionRef =
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

        // Another Walker owns the current offer.
        if (incomingWalkerUid.isNotEmpty &&
            incomingWalkerUid != walkerUid) {
          throw Exception(
            'This walk is assigned to another walker.',
          );
        }

        // --------------------------------------------------------
        // DUPLICATE REJECTION / TIMEOUT CHECK
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
            'type': 'rejected',
            'rejectedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // RELEASE ONLY THIS WALKER'S CLAIM
        // --------------------------------------------------------

        if (incomingWalkerUid == walkerUid) {
          transaction.update(
            walkRef,
            <String, dynamic>{
              'incomingWalkerUid': FieldValue.delete(),
              'incomingWalkerId': FieldValue.delete(),
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
