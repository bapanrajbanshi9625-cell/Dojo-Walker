// File:
// lib/features/insta_walk/services/insta_walk_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/insta_walk_request.dart';

/// ============================================================
/// INSTA WALK SERVICE
///
/// जिम्मेदारी:
///
/// - Current Walker information
/// - Pending / searching requests
/// - Accepted walks
/// - Get / watch walk
/// - Cancel search
/// - Start walk
/// - Complete walk
///
/// ACCEPT / REJECT ACTIONS:
///
/// अलग service में हैं:
///
/// insta_walk_request_action_service.dart
///
/// इसलिए इस file में:
///
/// acceptWalk()
/// rejectWalk()
///
/// नहीं हैं.
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

    final String walkerName =
        data['walkerName']
                ?.toString()
                .trim() ??
            '';

    if (walkerName.isNotEmpty) {
      return walkerName;
    }

    return data['name']
                ?.toString()
                .trim() ??
        '';
  }

  // ============================================================
  // CHECK WHETHER CURRENT WALKER ALREADY REJECTED
  //
  // यह केवल READ / FILTER के लिए है.
  //
  // Reject create करने का logic यहां नहीं है.
  //
  // Path:
  //
  // walk_requests/{walkId}/rejections/{walkerId}
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
  // Walker ko:
  //
  // status == searching
  //
  // wali request milegi.
  //
  // Agar current Walker ne pehle reject kiya hai,
  // to us request ko filter kar diya jayega.
  //
  // केवल ONE request दिखानी है.
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
                    return InstaWalkRequest.fromFirestore(
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

    return InstaWalkRequest.fromFirestore(
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

            return InstaWalkRequest.fromFirestore(
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
            storedWalkerId != walkerId) {
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
            storedWalkerUid != walkerUid) {
          throw Exception(
            'This walk belongs to another walker.',
          );
        }

        final String sessionId =
            liveWalkSessionId?.trim().isNotEmpty ==
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
            'liveWalkSessionId': sessionId,
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
            storedWalkerId != walkerId) {
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
            storedWalkerUid != walkerUid) {
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
