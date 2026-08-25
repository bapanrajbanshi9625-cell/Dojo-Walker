// File:
// lib/features/insta_walk/services/insta_walk_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/insta_walk_request.dart';

/// ============================================================
/// INSTA WALK SERVICE
///
/// Firestore structure:
///
/// walk_requests/{walkId}
///     status: "searching"
///     ownerId: "OWN26GS0003"
///     walkerId: null
///     walkerName: null
///     ...
///
///     rejections/{walkerId}
///         walkerId: "WALKER001"
///         walkerUid: "firebase-auth-uid"
///         rejectedAt: timestamp
///
/// IMPORTANT:
///
/// Reject करने पर:
///
///     status = "searching"
///
/// NEVER:
///
///     status = "rejected"
///
/// इससे अगला Walker उसी request को देख सकता है.
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
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_requests');
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

  // ============================================================
  // CURRENT FIREBASE AUTH UID
  // ============================================================

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
  // GET CURRENT WALKER DOCUMENT
  //
  // walkers/{FirebaseAuthUID}
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
        await _walkers.doc(uid).get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot;
  }

  // ============================================================
  // GET CURRENT WALKER ID
  //
  // Example:
  //
  // Firebase Auth UID:
  // abcXYZ123
  //
  // walkers/abcXYZ123
  //     walkerId: WALKER001
  //
  // Returns:
  //     WALKER001
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
  // GET CURRENT WALKER NAME
  // ============================================================

  Future<String> getCurrentWalkerName() async {
    final DocumentSnapshot<
            Map<String, dynamic>>?
        snapshot =
        await _getCurrentWalkerDocument();

    if (snapshot == null) {
      return '';
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      return '';
    }

    return data['walkerName']
                ?.toString()
                .trim() ??
        data['name']
                ?.toString()
                .trim() ??
        '';
  }

  // ============================================================
  // REJECTIONS COLLECTION
  //
  // walk_requests/{walkId}/rejections/{walkerId}
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
  // CHECK WHETHER CURRENT WALKER ALREADY REJECTED
  // ============================================================

  Future<bool> _hasRejected(
    String walkId,
    String walkerId,
  ) async {
    final String id =
        walkId.trim();

    final String wid =
        walkerId.trim();

    if (id.isEmpty || wid.isEmpty) {
      return false;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _rejections(id)
            .doc(wid)
            .get();

    return snapshot.exists;
  }

  // ============================================================
  // PENDING / SEARCHING REQUESTS
  //
  // Walker ko:
  //
  // status == searching
  //
  // wali request milegi.
  //
  // Lekin jis Walker ne pehle reject kiya hai,
  // usko wahi request dobara nahi milegi.
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
                if (snapshot.docs.isEmpty) {
                  return <InstaWalkRequest>[];
                }

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
                    InstaWalkRequest
                        .fromFirestore(doc),
                  );
                }

                if (availableRequests
                    .isEmpty) {
                  return <InstaWalkRequest>[];
                }

                // केवल ONE request दिखानी है.
                return <InstaWalkRequest>[
                  availableRequests.first,
                ];
              },
            );
      },
    );
  }

  // ============================================================
  // ACCEPT INSTA WALK
  //
  // searching → accepted
  //
  // walkerId:
  //     walkers/{FirebaseAuthUID}.walkerId
  // ============================================================

  Future<void> acceptWalk(
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
        // CHECK REJECTION
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

  // ============================================================
  // REJECT INSTA WALK
  //
  // IMPORTANT:
  //
  // Main request:
  //
  //     status = searching
  //
  // Rejection:
  //
  //     rejections/{walkerId}
  //
  // इसलिए अगला Walker request देख सकता है.
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
        // STATUS MUST REMAIN SEARCHING
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
        // CHECK DUPLICATE REJECTION
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
        // CREATE REJECTION
        //
        // walk_requests/{id}/rejections/{walkerId}
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
        // MAIN REQUEST STATUS REMAINS SEARCHING
        // ------------------------------------------------------

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'searching',

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
                        .fromFirestore(doc);
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
  //
  // searching → accepted → active → completed
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

        final String storedWalkerId =
            data['walkerId']
                    ?.toString()
                    .trim() ??
                '';

        if (storedWalkerId.isNotEmpty &&
            storedWalkerId !=
                walkerId) {
          throw Exception(
            'This walk belongs to another walker.',
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

            'walkerId': walkerId,

            'walkerUid': walkerUid,

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

        final String storedWalkerId =
            data['walkerId']
                    ?.toString()
                    .trim() ??
                '';

        if (storedWalkerId.isNotEmpty &&
            storedWalkerId !=
                walkerId) {
          throw Exception(
            'This walk belongs to another walker.',
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
