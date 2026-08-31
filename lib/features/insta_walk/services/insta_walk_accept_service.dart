// File:
// lib/features/insta_walk/services/insta_walk_accept_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../walks/services/walk_request_sound_service.dart';

/// ============================================================
/// INSTA WALK ACCEPT SERVICE
///
/// Firestore:
///
///   walk_request/{walkId}
///
/// Accept flow:
///
///   searching → accepted
///
/// Rejection:
///
///   walk_request/{walkId}/rejections/{walkerId}
///
/// Rules:
/// - A walker who rejected a request cannot accept it later.
/// - Another walker can still accept the same request.
/// - Only one walker can successfully accept a searching request.
/// - Rejection data stays inside the private subcollection.
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
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_request');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get _currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // CURRENT WALKER ID
  //
  // Firestore:
  //
  // walkers/{FirebaseAuthUID}
  //
  // Example:
  //
  // walkerId: WALKER001
  // ============================================================

  Future<String> getCurrentWalkerId() async {
    final User? user = _currentUser;

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

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection('walkers')
            .doc(walkerUid)
            .get();

    if (!snapshot.exists) {
      throw Exception(
        'Walker profile not found.',
      );
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      throw Exception(
        'Walker profile data is empty.',
      );
    }

    final String walkerId =
        data['walkerId']
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found in walkers collection.',
      );
    }

    return walkerId;
  }

  // ============================================================
  // ACCEPT WALK
  //
  // searching → accepted
  // ============================================================

  Future<void> acceptWalk(
    String walkId,
  ) async {
    // ==========================================================
    // AUTH
    // ==========================================================

    final User? user = _currentUser;

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

    // ==========================================================
    // WALKER BUSINESS ID
    //
    // IMPORTANT:
    // This is now String, NOT String?.
    // Therefore doc(walkerId) is type-safe.
    // ==========================================================

    final String walkerId =
        await getCurrentWalkerId();

    // ==========================================================
    // WALK ID
    // ==========================================================

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ==========================================================
    // MAIN WALK DOCUMENT
    // ==========================================================

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    // ==========================================================
    // REJECTION DOCUMENT
    //
    // walk_request/{walkId}/rejections/{walkerId}
    // ==========================================================

    final DocumentReference<
            Map<String, dynamic>>
        rejectionRef =
        walkRef
            .collection('rejections')
            .doc(walkerId);

    // ==========================================================
    // TRANSACTION
    //
    // Transaction guarantees that two walkers cannot
    // simultaneously accept the same searching request.
    // ==========================================================

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ======================================================
        // READ WALK REQUEST
        // ======================================================

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

        // ======================================================
        // STATUS
        // ======================================================

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

        // ======================================================
        // CHECK PREVIOUS REJECTION
        // ======================================================

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

        // ======================================================
        // ACCEPT REQUEST
        // ======================================================

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'accepted',

            // Walker business ID
            'walkerId': walkerId,

            // Firebase Auth UID
            'walkerUid': walkerUid,

            // Useful for compatibility
            'acceptedBy': walkerId,
            'acceptedByUid': walkerUid,

            'acceptedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );

    // ==========================================================
    // ACCEPT SUCCESS
    //
    // Only stop incoming ringtone after transaction succeeds.
    // ==========================================================

    try {
      await WalkRequestSoundService
          .instance
          .stopRequest(id);
    } catch (e) {
      // Sound failure must NOT make a successful accept
      // appear as a failed accept.
      //
      // The Firestore transaction has already succeeded.
      //
      // Log only.
      // ignore: avoid_print
      print(
        'Unable to stop walk request sound: $e',
      );
    }
  }
}
