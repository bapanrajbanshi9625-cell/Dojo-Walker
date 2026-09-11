import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/insta_walk_request.dart';

/// ============================================================
/// INSTA WALK REQUEST SERVICE
///
/// RESPONSIBILITIES:
///
/// - Find searching Insta Walk requests
/// - Hide requests rejected by current Walker
/// - Return available requests
/// - Get a single walk request
///
/// NOT RESPONSIBLE FOR:
///
/// - Sound
/// - Accept
/// - Reject
/// - Cancel
/// - Reach
/// - Start
/// - Complete
/// - Accepted walk watching
/// - Active walk document watching
///
/// INSTA WALK:
///     Creates / searches for requests only.
///
/// INCOMING WALK:
///     Receives and handles incoming requests.
///
/// ACCEPT WALK:
///     Handles accepted walk flow.
/// ============================================================

class InstaWalkRequestService {
  InstaWalkRequestService._();

  static final InstaWalkRequestService instance =
      InstaWalkRequestService._();

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

  CollectionReference<Map<String, dynamic>>
      get _walkers {
    return _firestore.collection('walkers');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

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
  // CURRENT WALKER DOCUMENT
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _getCurrentWalkerDocument() async {
    final String? uid =
        currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _walkers
            .doc(uid)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot;
  }

  // ============================================================
  // CURRENT WALKER ID
  //
  // IMPORTANT:
  //
  // Firebase Auth UID is the canonical Walker ID.
  //
  // If walkers/{uid}.walkerId exists, it is still supported
  // for compatibility.
  //
  // Otherwise the Firebase Auth UID itself is returned.
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final String? uid =
        currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>?
        snapshot =
        await _getCurrentWalkerDocument();

    if (snapshot != null) {
      final Map<String, dynamic>? data =
          snapshot.data();

      if (data != null) {
        final String walkerId =
            data['walkerId']
                    ?.toString()
                    .trim() ??
                '';

        if (walkerId.isNotEmpty) {
          return walkerId;
        }
      }
    }

    // ----------------------------------------------------------
    // Canonical Walker identity:
    // Firebase Auth UID
    // ----------------------------------------------------------

    return uid;
  }

  // ============================================================
  // CHECK REJECTION
  //
  // walk_request/{walkId}/rejections/{walkerId}
  // ============================================================

  Future<bool> _hasRejected(
    String walkId,
    String walkerId,
  ) async {
    final String id =
        walkId.trim();

    final String wid =
        walkerId.trim();

    if (id.isEmpty ||
        wid.isEmpty) {
      return false;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _walkRequests
            .doc(id)
            .collection('rejections')
            .doc(wid)
            .get();

    return snapshot.exists;
  }

  // ============================================================
  // PENDING / SEARCHING REQUESTS
  //
  // Only:
  //
  //     status == searching
  //
  // A request rejected by current Walker is hidden.
  //
  // Only ONE available request is returned.
  //
  // IMPORTANT:
  //
  // No sound is handled here.
  // ============================================================

  Stream<List<InstaWalkRequest>>
      pendingRequestsStream() {
    return Stream.fromFuture(
      getCurrentWalkerId(),
    ).asyncExpand(
      (
        String? walkerId,
      ) {
        if (walkerId == null ||
            walkerId.trim().isEmpty) {
          return Stream.value(
            <InstaWalkRequest>[],
          );
        }

        return _walkRequests
            .where(
              'status',
              isEqualTo: 'searching',
            )
            .snapshots()
            .asyncMap(
              (
                QuerySnapshot<
                        Map<String, dynamic>>
                    snapshot,
              ) async {
                final List<
                        InstaWalkRequest>
                    availableRequests =
                    <InstaWalkRequest>[];

                for (final QueryDocumentSnapshot<
                        Map<String, dynamic>>
                    doc in snapshot.docs) {
                  final bool alreadyRejected =
                      await _hasRejected(
                    doc.id,
                    walkerId,
                  );

                  if (alreadyRejected) {
                    continue;
                  }

                  final InstaWalkRequest
                      request =
                      InstaWalkRequest
                          .fromFirestore(
                    doc,
                  );

                  availableRequests.add(
                    request,
                  );
                }

                if (availableRequests
                    .isEmpty) {
                  return <InstaWalkRequest>[];
                }

                // ------------------------------------------------
                // Existing behavior preserved:
                // only ONE available request.
                // ------------------------------------------------

                return <InstaWalkRequest>[
                  availableRequests.first,
                ];
              },
            );
      },
    );
  }

  // ============================================================
  // GET SINGLE WALK REQUEST
  // ============================================================

  Future<InstaWalkRequest?>
      getWalkRequest(
    String walkId,
  ) async {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return null;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _walkRequests
            .doc(id)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    return InstaWalkRequest.fromFirestore(
      snapshot,
    );
  }
}
