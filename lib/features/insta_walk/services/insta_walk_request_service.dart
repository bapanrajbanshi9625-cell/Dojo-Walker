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
/// - Get single walk request
/// - Watch accepted walks
///
/// NOT RESPONSIBLE FOR:
///
/// - Accept
/// - Reject
/// - Cancel
/// - Start
/// - Complete
/// - Active walk document watching
///
/// ACCEPT:
///     InstaWalkAcceptService
///
/// REJECT:
///     InstaWalkRejectService
///
/// WALK ACTIONS:
///     InstaWalkService
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
    final User? user =
        _auth.currentUser;

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
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final DocumentSnapshot<
            Map<String, dynamic>>?
        snapshot =
        await _getCurrentWalkerDocument();

    if (snapshot == null) {
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
                final List<InstaWalkRequest>
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

                  availableRequests.add(
                    InstaWalkRequest.fromFirestore(
                      doc,
                    ),
                  );
                }

                if (availableRequests.isEmpty) {
                  return <InstaWalkRequest>[];
                }

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
  //
  // Used after accepting a request.
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

  // ============================================================
  // ACCEPTED WALKS
  //
  // Current Walker:
  //
  // walkerUid == FirebaseAuth UID
  //
  // status == accepted
  // ============================================================

  Stream<List<InstaWalkRequest>>
      acceptedWalksStream() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        <InstaWalkRequest>[],
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      return Stream.value(
        <InstaWalkRequest>[],
      );
    }

    return _walkRequests
        .where(
          'walkerUid',
          isEqualTo: walkerUid,
        )
        .where(
          'status',
          isEqualTo: 'accepted',
        )
        .snapshots()
        .map(
          (
            QuerySnapshot<
                    Map<String, dynamic>>
                snapshot,
          ) {
            return snapshot.docs
                .map(
                  (
                    QueryDocumentSnapshot<
                            Map<String, dynamic>>
                        doc,
                  ) {
                    return InstaWalkRequest
                        .fromFirestore(
                      doc,
                    );
                  },
                )
                .toList();
          },
        );
  }
}
