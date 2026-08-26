import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// INSTA WALK REJECT SERVICE
///
/// Collection:
///     walk_request
///
/// IMPORTANT:
///
/// Main request NEVER becomes "rejected".
///
/// Only this Walker gets a rejection record:
///
/// walk_request/{walkId}/rejections/{walkerId}
///
/// Example:
///
/// walk_request
///   └── ABC123
///       ├── status: searching
///       │
///       └── rejections
///           └── WALKER001
///               ├── walkerId
///               ├── walkerUid
///               ├── rejectedAt
///               └── updatedAt
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
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_request');
  }

  // ============================================================
  // CURRENT WALKER ID
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return null;
    }

    final String uid =
        user.uid.trim();

    if (uid.isEmpty) {
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
  // REJECT WALK
  //
  // Main request remains:
  //
  // status = searching
  //
  // Only current Walker gets:
  //
  // rejections/{walkerId}
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
        _rejections(id)
            .doc(walkerId);

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ------------------------------------------------------
        // READ MAIN REQUEST
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
        // CHECK EXISTING REJECTION
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
        // SAVE PRIVATE WALKER REJECTION
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
        // IMPORTANT:
        //
        // MAIN REQUEST REMAINS SEARCHING.
        //
        // इसलिए दूसरा Walker इसे देख सकता है.
        // ------------------------------------------------------

        transaction.update(
          walkRef,
          <String, dynamic>{
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }
}
