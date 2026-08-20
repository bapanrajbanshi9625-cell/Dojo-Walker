import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/walk_request.dart';

class WalkRequestService {
  WalkRequestService._();

  static final WalkRequestService instance =
      WalkRequestService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // PENDING WALK REQUESTS
  // ============================================================

  Stream<List<WalkRequest>> pendingRequestsStream() {
  return _firestore
      .collection('walk_requests')
      .where(
        'status',
        isEqualTo: 'searching',
      )
      .snapshots()
      .map(
        (snapshot) {
          return snapshot.docs
              .map(
                (doc) => WalkRequest.fromFirestore(
                  doc.id,
                  doc.data(),
                ),
              )
              .toList();
        },
      );
  }

  // ============================================================
  // ACCEPT WALK
  // ============================================================

  Future<void> acceptWalk(String walkId) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final walkerUid = user.uid;

    // ----------------------------------------------------------
    // IMPORTANT:
    // यहां Walker UID से walkers collection में Walker ID निकलेगी.
    // ----------------------------------------------------------

    final walkerSnapshot = await _firestore
        .collection('walkers')
        .doc(walkerUid)
        .get();

    if (!walkerSnapshot.exists) {
      throw Exception(
        'Walker profile not found.',
      );
    }

    final walkerData =
        walkerSnapshot.data() ?? {};

    final walkerId =
        walkerData['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    // ----------------------------------------------------------
    // TRANSACTION
    // ----------------------------------------------------------

    final walkRef = _firestore
        .collection('walk_requests')
        .doc(walkId);

    await _firestore.runTransaction(
      (transaction) async {
        final walkSnapshot =
            await transaction.get(walkRef);

        if (!walkSnapshot.exists) {
          throw Exception(
            'Walk request no longer exists.',
          );
        }

        final data =
            walkSnapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        final status =
            data['status']?.toString() ?? '';

        if (status != 'pending') {
          throw Exception(
            'This walk has already been accepted.',
          );
        }

        transaction.update(
          walkRef,
          {
            'status': 'accepted',
            'walkerId': walkerId,
            'walkerUid': walkerUid,
            'acceptedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // ACCEPTED WALK FOR CURRENT WALKER
  // ============================================================

  Stream<List<WalkRequest>> acceptedWalksStream() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        <WalkRequest>[],
      );
    }

    return _firestore
        .collection('walk_requests')
        .where(
          'walkerUid',
          isEqualTo: user.uid,
        )
        .where(
          'status',
          isEqualTo: 'accepted',
        )
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  (doc) =>
                      WalkRequest.fromFirestore(doc),
                )
                .toList();
          },
        );
  }
}
