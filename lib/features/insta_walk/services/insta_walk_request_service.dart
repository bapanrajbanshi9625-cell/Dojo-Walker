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
/// - Claim one incoming request for one Walker at a time
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

  CollectionReference<Map<String, dynamic>> get _walkRequests {
    return _firestore.collection('walk_request');
  }

  CollectionReference<Map<String, dynamic>> get _walkers {
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

    final DocumentSnapshot<Map<String, dynamic>>
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
  // Firebase Auth UID is the canonical fallback.
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final String? uid =
        currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>?
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

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await _walkRequests
            .doc(id)
            .collection('rejections')
            .doc(wid)
            .get();

    return snapshot.exists;
  }

  // ============================================================
  // CLAIM ONE INCOMING REQUEST
  //
  // IMPORTANT:
  //
  // A searching request can be offered to ONLY ONE Walker.
  //
  // The claim is stored on the request as:
  //
  // incomingWalkerUid
  // incomingClaimedAt
  //
  // This transaction makes the claim race-safe between
  // multiple Walker devices.
  //
  // Returns:
  //
  // true  = this Walker owns the incoming offer
  // false = another Walker owns it / request unavailable
  // ============================================================

  Future<bool> _claimIncomingRequest({
    required String walkId,
    required String walkerUid,
  }) async {
    final String id =
        walkId.trim();

    final String uid =
        walkerUid.trim();

    if (id.isEmpty ||
        uid.isEmpty) {
      return false;
    }

    final DocumentReference<Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    return _firestore.runTransaction<bool>(
      (
        Transaction transaction,
      ) async {
        final DocumentSnapshot<Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          return false;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return false;
        }

        // --------------------------------------------------------
        // ONLY SEARCHING REQUESTS CAN BE CLAIMED
        // --------------------------------------------------------

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (status != 'searching') {
          return false;
        }

        // --------------------------------------------------------
        // CURRENT CLAIM
        // --------------------------------------------------------

        final String incomingWalkerUid =
            data['incomingWalkerUid']
                    ?.toString()
                    .trim() ??
                '';

        // --------------------------------------------------------
        // ALREADY CLAIMED BY THIS WALKER
        //
        // Keep the existing claim.
        // Do NOT write again.
        // This prevents unnecessary snapshot loops.
        // --------------------------------------------------------

        if (incomingWalkerUid == uid) {
          return true;
        }

        // --------------------------------------------------------
        // CLAIMED BY ANOTHER WALKER
        // --------------------------------------------------------

        if (incomingWalkerUid.isNotEmpty &&
            incomingWalkerUid != uid) {
          return false;
        }

        // --------------------------------------------------------
        // CLAIM REQUEST
        // --------------------------------------------------------

        transaction.update(
          walkRef,
          <String, dynamic>{
            'incomingWalkerUid': uid,
            'incomingClaimedAt':
                FieldValue.serverTimestamp(),
          },
        );

        return true;
      },
    );
  }

  // ============================================================
  // PENDING / SEARCHING REQUESTS
  //
  // Auth-state aware:
  //
  // If Firebase Auth becomes available after app startup,
  // the listener starts automatically.
  //
  // Only one Walker can claim a request at a time.
  //
  // Rejected requests are hidden for that Walker.
  // ============================================================

  Stream<List<InstaWalkRequest>>
      pendingRequestsStream() {
    return _auth
        .authStateChanges()
        .asyncExpand(
      (
        User? user,
      ) {
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
                      // ------------------------------------------------
                      // PRIVATE REJECTION CHECK
                      // ------------------------------------------------

                      final bool alreadyRejected =
                          await _hasRejected(
                        doc.id,
                        walkerId,
                      );

                      if (alreadyRejected) {
                        continue;
                      }

                      // ------------------------------------------------
                      // CLAIM CHECK
                      //
                      // Only one Walker can successfully claim.
                      // ------------------------------------------------

                      final bool claimed =
                          await _claimIncomingRequest(
                        walkId: doc.id,
                        walkerUid: walkerUid,
                      );

                      if (!claimed) {
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

                      // ------------------------------------------------
                      // ONLY ONE REQUEST PER WALKER
                      // ------------------------------------------------

                      break;
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

    final DocumentSnapshot<Map<String, dynamic>>
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
