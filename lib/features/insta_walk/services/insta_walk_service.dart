// File:
// lib/features/insta_walk/services/insta_walk_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/insta_walk_request.dart';

/// ============================================================
/// INSTA WALK SERVICE
///
/// Firestore:
///
/// walk_requests/{walkId}
///     status: searching
///     rejectedWalkerUids: []
///
///     rejections/{walkerUid}
///         walkerUid
///         rejectedAt
///
/// Reject करने पर:
///
///     request.status
///         remains "searching"
///
///     rejections/{walkerUid}
///         is created
///
/// इससे अगला Walker वही request देख सकता है.
///
/// Status flow:
///
///     searching
///        ↓
///     accepted
///        ↓
///     active
///        ↓
///     completed
///
/// Other:
///     cancelled
///
/// IMPORTANT:
///     "rejected" अब main request status नहीं बनेगा.
/// ============================================================

class InstaWalkService {
  InstaWalkService._();

  static final InstaWalkService instance =
      InstaWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_requests');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // CURRENT WALKER UID
  // ============================================================

  String? get currentWalkerUid {
    final User? user = _auth.currentUser;

    final String uid = user?.uid.trim() ?? '';

    if (uid.isEmpty) {
      return null;
    }

    return uid;
  }

  // ============================================================
  // REJECTIONS COLLECTION
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
  // PENDING / SEARCHING REQUESTS
  //
  // Walker ko sirf searching requests milengi.
  //
  // Lekin jis Walker ne already reject kiya hai,
  // usko wahi request dobara nahi dikhayenge.
  // ============================================================

  Stream<List<InstaWalkRequest>>
      pendingRequestsStream() {
    final String? walkerUid =
        currentWalkerUid;

    if (walkerUid == null) {
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
            QuerySnapshot<Map<String, dynamic>>
                snapshot,
          ) async {
            if (snapshot.docs.isEmpty) {
              return <InstaWalkRequest>[];
            }

            final List<InstaWalkRequest>
                availableRequests =
                <InstaWalkRequest>[];

            for (final QueryDocumentSnapshot<
                Map<String, dynamic>> doc
                in snapshot.docs) {
              final Map<String, dynamic>? data =
                  doc.data();

              final List<dynamic>
                  rejectedWalkerUids =
                  data['rejectedWalkerUids']
                          as List<dynamic>? ??
                      <dynamic>[];

              final bool alreadyRejected =
                  rejectedWalkerUids.contains(
                walkerUid,
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

            // Walker ko ek time par
            // sirf ONE request dikhani hai.
            return <InstaWalkRequest>[
              availableRequests.first,
            ];
          },
        );
  }

  // ============================================================
  // ACCEPT INSTA WALK
  //
  // searching → accepted
  //
  // IMPORTANT:
  // Reject ki hui request ko bhi accept nahi kar sakte.
  // ============================================================

  Future<void> acceptWalk(
    String walkId,
  ) async {
    final User? user = _auth.currentUser;

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

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Walk request no longer exists.',
          );
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

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
        // CHECK IF THIS WALKER ALREADY REJECTED
        // ------------------------------------------------------

        final List<dynamic>
            rejectedWalkerUids =
            data['rejectedWalkerUids']
                    as List<dynamic>? ??
                <dynamic>[];

        if (rejectedWalkerUids.contains(
          walkerUid,
        )) {
          throw Exception(
            'You already rejected this walk.',
          );
        }

        // ------------------------------------------------------
        // ACCEPT
        // ------------------------------------------------------

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'accepted',

            'walkerUid': walkerUid,
            'walkerId': walkerUid,

            'acceptedBy': walkerUid,

            'acceptedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // REJECT INSTA WALK
  //
  // IMPORTANT:
  //
  // DO NOT:
  //
  //     status = rejected
  //
  // Instead:
  //
  //     walk_requests/{walkId}
  //         status = searching
  //
  //     walk_requests/{walkId}/rejections/{walkerUid}
  //
  // This allows the NEXT Walker to receive the request.
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

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
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
        _rejections(id).doc(walkerUid);

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ------------------------------------------------------
        // READ REQUEST
        // ------------------------------------------------------

        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Walk request no longer exists.',
          );
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        // ------------------------------------------------------
        // STATUS CHECK
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
        // EXISTING REJECTION LIST
        // ------------------------------------------------------

        final List<dynamic>
            rejectedWalkerUids =
            List<dynamic>.from(
          data['rejectedWalkerUids']
                  as List<dynamic>? ??
              <dynamic>[],
        );

        // ------------------------------------------------------
        // ADD CURRENT WALKER
        // ------------------------------------------------------

        if (!rejectedWalkerUids.contains(
          walkerUid,
        )) {
          rejectedWalkerUids.add(
            walkerUid,
          );
        }

        // ------------------------------------------------------
        // SAVE REJECTION SUBDOCUMENT
        //
        // rejections/{walkerUid}
        // ------------------------------------------------------

        transaction.set(
          rejectionRef,
          <String, dynamic>{
            'walkerUid': walkerUid,

            'rejectedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        // ------------------------------------------------------
        // UPDATE MAIN REQUEST
        //
        // STATUS REMAINS SEARCHING
        // ------------------------------------------------------

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'searching',

            'rejectedWalkerUids':
                rejectedWalkerUids,

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // ACCEPTED INSTA WALKS
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

  // ============================================================
  // GET SINGLE INSTA WALK
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

    return InstaWalkRequest
        .fromFirestore(
      snapshot,
    );
  }

  // ============================================================
  // WATCH SINGLE INSTA WALK
  // ============================================================

  Stream<DocumentSnapshot<
          Map<String, dynamic>>>
      watchWalk(
    String walkId,
  ) {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return const Stream<
          DocumentSnapshot<
              Map<String, dynamic>>>.empty();
    }

    return _walkRequests
        .doc(id)
        .snapshots();
  }

  // ============================================================
  // WATCH SINGLE INSTA WALK AS MODEL
  // ============================================================

  Stream<InstaWalkRequest?>
      watchWalkRequest(
    String walkId,
  ) {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return Stream.value(null);
    }

    return _walkRequests
        .doc(id)
        .snapshots()
        .map(
          (
            DocumentSnapshot<
                    Map<String, dynamic>>
                snapshot,
          ) {
            if (!snapshot.exists) {
              return null;
            }

            return InstaWalkRequest
                .fromFirestore(
              snapshot,
            );
          },
        );
  }

  // ============================================================
  // CANCEL SEARCH
  //
  // searching → cancelled
  // ============================================================

  Future<void> cancelSearch(
    String walkId,
  ) async {
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

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Walk request not found.',
          );
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim() ??
                '';

        if (status != 'searching') {
          throw Exception(
            'This walk is no longer searching.',
          );
        }

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'cancelled',

            'cancelledAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // START WALK
  //
  // accepted → active
  // ============================================================

  Future<void> startWalk(
    String walkId, {
    String? liveWalkSessionId,
  }) async {
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

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Walk request not found.',
          );
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim() ??
                '';

        if (status != 'accepted') {
          throw Exception(
            'This walk is not ready to start.',
          );
        }

        final String storedWalkerUid =
            data['walkerUid']
                    ?.toString()
                    .trim() ??
                '';

        if (storedWalkerUid.isNotEmpty &&
            storedWalkerUid !=
                walkerUid) {
          throw Exception(
            'This walk belongs to another walker.',
          );
        }

        final String sessionId =
            liveWalkSessionId
                        ?.trim()
                        .isNotEmpty ==
                    true
                ? liveWalkSessionId!.trim()
                : 'session-$id';

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'active',

            'walkerUid': walkerUid,
            'walkerId': walkerUid,

            'activeWalkId': id,

            'liveWalkSessionId':
                sessionId,

            'startedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // COMPLETE WALK
  //
  // active → completed
  // ============================================================

  Future<void> completeWalk(
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

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        final DocumentSnapshot<
                Map<String, dynamic>>
            snapshot =
            await transaction.get(
          walkRef,
        );

        if (!snapshot.exists) {
          throw Exception(
            'Walk request not found.',
          );
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim() ??
                '';

        if (status != 'active') {
          throw Exception(
            'This walk is not active.',
          );
        }

        final String storedWalkerUid =
            data['walkerUid']
                    ?.toString()
                    .trim() ??
                '';

        if (storedWalkerUid.isNotEmpty &&
            storedWalkerUid !=
                walkerUid) {
          throw Exception(
            'This walk belongs to another walker.',
          );
        }

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'completed',

            'endedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }
}
