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
  // Canonical fallback:
  // Firebase Auth UID is the Walker ID.
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
  // Main document:
  //
  // walk_request/{walkId}
  //
  // Private rejection:
  //
  // walk_request/{walkId}/rejections/{walkerId}
  //
  // Main status remains "searching".
  //
  // After rejection, the current incoming Walker claim is released
  // so another eligible Walker can receive the request.
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

    if (walkerId == null || walkerId.trim().isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    final String cleanWalkerId = walkerId.trim();

    final String id = walkId.trim();

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
        // INCOMING WALK CLAIM
        // --------------------------------------------------------

        final String incomingWalkerUid =
            data['incomingWalkerUid']
                    ?.toString()
                    .trim() ??
                '';

        // If another Walker currently owns the incoming offer,
        // this Walker must not be allowed to reject it.
        if (incomingWalkerUid.isNotEmpty &&
            incomingWalkerUid != walkerUid) {
          throw Exception(
            'This walk is assigned to another walker.',
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
        // SAVE PRIVATE WALKER REJECTION
        // --------------------------------------------------------

        transaction.set(
          rejectionRef,
          <String, dynamic>{
            'walkerId': cleanWalkerId,
            'walkerUid': walkerUid,
            'rejectedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // --------------------------------------------------------
        // RELEASE CURRENT INCOMING WALKER CLAIM
        //
        // IMPORTANT:
        //
        // Main request remains:
        //
        // status = searching
        //
        // Owner is NOT told that this specific Walker rejected.
        //
        // The claim is simply released so another eligible Walker
        // can receive the request.
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
    // STOP SOUND ONLY AFTER FIRESTORE SUCCESS
    // ----------------------------------------------------------

    await IncomingWalkSoundService.instance.stopRequest(id);
  }
}
