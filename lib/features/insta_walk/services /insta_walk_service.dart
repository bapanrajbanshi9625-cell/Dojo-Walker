// File:
// lib/features/insta_walk/services/insta_walk_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../walks/models/walk_request.dart';

/// ============================================================
/// INSTA WALK SERVICE
///
/// RESPONSIBILITY:
/// 1. Listen for searching Insta Walk requests
/// 2. Accept Insta Walk
/// 3. Reject Insta Walk
/// 4. Listen for accepted Insta Walks
/// 5. Get a single Insta Walk request
///
/// NOT RESPONSIBLE FOR:
/// - QR scanning
/// - QR connection
/// - QR walk
/// - Live GPS
/// - Live route
/// - Live session
///
/// Both Insta Walk and QR Walk eventually use the same:
///     live_walk_screen.dart
///
/// ============================================================

class InstaWalkService {
  InstaWalkService._();

  static final InstaWalkService instance =
      InstaWalkService._();

  // ============================================================
  // FIREBASE
  // ============================================================

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
  // PENDING / SEARCHING INSTA WALKS
  //
  // Owner side creates:
  //
  // walk_requests/{walkId}
  //
  // status = searching
  //
  // Walker listens here.
  // ============================================================

  Stream<List<WalkRequest>>
      pendingRequestsStream() {
    return _walkRequests
        .where(
          'status',
          isEqualTo: 'searching',
        )
        .snapshots()
        .map(
          (
            QuerySnapshot<
                Map<String, dynamic>>
            snapshot,
          ) {
            if (snapshot.docs.isEmpty) {
              return <WalkRequest>[];
            }

            final List<WalkRequest> requests =
                snapshot.docs
                    .map(
                      (
                        QueryDocumentSnapshot<
                            Map<String, dynamic>>
                        doc,
                      ) {
                        return WalkRequest
                            .fromFirestore(doc);
                      },
                    )
                    .toList();

            // --------------------------------------------------
            // Walker ko ek time par sirf ONE request dikhani hai.
            // --------------------------------------------------

            return <WalkRequest>[
              requests.first,
            ];
          },
        );
  }

  // ============================================================
  // ACCEPT INSTA WALK
  //
  // searching
  //     ↓
  // accepted
  //
  // Walker UID is stored in walkerUid.
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

        // ------------------------------------------------------
        // Only searching requests can be accepted.
        // ------------------------------------------------------

        if (status != 'searching') {
          throw Exception(
            'This walk has already been accepted.',
          );
        }

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'accepted',

            'walkerUid': walkerUid,

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
  // searching
  //     ↓
  // rejected
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

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'rejected',

            'rejectedBy': walkerUid,

            'rejectedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // ACCEPTED INSTA WALKS
  //
  // Used after walker accepts an Insta Walk.
  // ============================================================

  Stream<List<WalkRequest>>
      acceptedWalksStream() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return Stream.value(
        <WalkRequest>[],
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      return Stream.value(
        <WalkRequest>[],
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
                    return WalkRequest
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

  Future<WalkRequest?> getWalkRequest(
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

    return WalkRequest
        .fromFirestore(snapshot);
  }

  // ============================================================
  // WATCH SINGLE INSTA WALK
  //
  // Useful when the UI needs to react immediately to:
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
  // CANCEL SEARCH
  //
  // Optional owner/walker-side cancellation.
  //
  // Only searching requests can be cancelled.
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
}

अब "walk_request_service.dart"

इसमें Insta के ये methods नहीं रखने हैं:

pendingRequestsStream()
acceptWalk()
rejectWalk()
acceptedWalksStream()
getWalkRequest()

क्योंकि ये अब:

lib/features/insta_walk/services/insta_walk_service.dart

में हैं।

"walk_request_service.dart" को common Live Walk service की तरफ रखना है:

startLiveWalk()
endLiveWalk()
liveWalkSessionStream()
activeWalkStream()
updateLiveLocation()
addRoutePoint()
updateWalkEvents()
addWalkEvent()

इससे final flow रहेगा:

Insta Walk → "insta_walk_service.dart" → Live → "live_walk_screen.dart"

QR Walk → "walker_qr_walk_service.dart" → Live → "live_walk_screen.dart"

यानी एक ही Live page दोनों से जुड़ेगा।
