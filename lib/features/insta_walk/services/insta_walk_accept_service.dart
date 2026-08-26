// File:
// lib/features/insta_walk/services/insta_walk_accept_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// INSTA WALK ACCEPT SERVICE
///
/// Main collection:
///     walk_request
///
/// ACCEPT:
///     searching → accepted
///
/// Rejection:
///     walk_request/{walkId}/rejections/{walkerId}
///
/// IMPORTANT:
/// - जिस Walker ने reject किया है वह दोबारा accept नहीं कर सकता.
/// - दूसरा Walker उसी request को देख/accept कर सकता है.
/// - Owner को rejection information main document में नहीं दिखाई जाती.
/// - Transaction के कारण एक ही समय में दो Walker accept नहीं कर सकते.
/// ============================================================

class InstaWalkAcceptService {
  InstaWalkAcceptService._();

  static final InstaWalkAcceptService instance =
      InstaWalkAcceptService._();

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
  // walkers/{FirebaseAuthUID}
  //
  // walkerId: WALKER001
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
  // ACCEPT WALK
  //
  // searching → accepted
  //
  // IMPORTANT:
  //
  // अगर इस Walker ने पहले reject किया है:
  //
  // rejections/{walkerId}
  //
  // तो वह दोबारा accept नहीं कर सकता.
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

    // ----------------------------------------------------------
    // MAIN WALK DOCUMENT
    // ----------------------------------------------------------

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    // ----------------------------------------------------------
    // REJECTION DOCUMENT
    //
    // walk_request/{walkId}/rejections/{walkerId}
    // ----------------------------------------------------------

    final DocumentReference<
            Map<String, dynamic>>
        rejectionRef =
        walkRef
            .collection('rejections')
            .doc(walkerId);

    // ==========================================================
    // TRANSACTION
    // ==========================================================

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ------------------------------------------------------
        // READ MAIN WALK
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
        // CHECK PREVIOUS REJECTION
        //
        // अगर current Walker ने पहले reject किया था,
        // तो वह इस walk को दोबारा accept नहीं कर सकता.
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
        //
        // अब यही Walker इस request का owner होगा.
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
}
