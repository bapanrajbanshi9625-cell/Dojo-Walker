// File:
// lib/features/insta_walk/services/insta_walk_accept_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../walks/services/walk_request_sound_service.dart';
import '../../walker_accept/services/walker_location_service.dart';

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
/// After successful accept:
///
///   WalkerLocationService.startTracking()
///
/// This means the walker GPS starts immediately after the
/// walker successfully accepts the walk.
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
  // WALKER LOCATION SERVICE
  // ============================================================

  final WalkerLocationService _locationService =
      WalkerLocationService();

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
  //
  // IMPORTANT:
  // GPS tracking starts ONLY after the Firestore transaction
  // succeeds.
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

            // Compatibility fields
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
    // FIRESTORE ACCEPT SUCCESS
    // ==========================================================
    //
    // At this point:
    //
    // status     = accepted
    // walkerId   = current walker business ID
    // walkerUid  = Firebase Auth UID
    //
    // Only NOW start GPS tracking.
    // ==========================================================

    try {
      await _locationService.startTracking(
        requestId: id,
      );
    } catch (e) {
      // --------------------------------------------------------
      // IMPORTANT:
      //
      // Accept already succeeded in Firestore.
      // Therefore GPS failure must NOT turn the accepted
      // request into a failed accept.
      // --------------------------------------------------------

      // ignore: avoid_print
      print(
        'Unable to start walker location tracking: $e',
      );
    }

    // ==========================================================
    // STOP INCOMING REQUEST SOUND
    //
    // Sound failure must never undo a successful accept.
    // ==========================================================

    try {
      await WalkRequestSoundService
          .instance
          .stopRequest(id);
    } catch (e) {
      // ignore: avoid_print
      print(
        'Unable to stop walk request sound: $e',
      );
    }
  }

  // ============================================================
  // STOP WALKER LOCATION TRACKING
  //
  // Call this when the accepted/on-the-way GPS lifecycle
  // is finished, for example after the walk reaches its
  // appropriate end state.
  // ============================================================

  Future<void> stopLocationTracking() async {
    try {
      await _locationService.stopTracking();
    } catch (e) {
      // ignore: avoid_print
      print(
        'Unable to stop walker location tracking: $e',
      );
    }
  }

  // ============================================================
  // DISPOSE
  //
  // Can be called when the overall Insta Walk feature is
  // permanently being disposed.
  // ============================================================

  Future<void> dispose() async {
    await stopLocationTracking();
  }
}
