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
  // PENDING / SEARCHING WALK REQUESTS
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
                  (doc) => WalkRequest.fromFirestore(doc),
                )
                .toList();
          },
        );
  }

  // ============================================================
  // ACCEPT WALK
  // ============================================================

  Future<void> acceptWalk(String walkId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid = user.uid;

    // ==========================================================
    // GET WALKER ID
    // phoneAccounts/{UID}
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        accountSnapshot = await _firestore
            .collection('phoneAccounts')
            .doc(walkerUid)
            .get();

    final Map<String, dynamic>? accountData =
        accountSnapshot.data();

    final String walkerId =
        accountData?['walkerId']
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    // ==========================================================
    // WALK REQUEST REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        walkRef = _firestore
            .collection('walk_requests')
            .doc(walkId);

    // ==========================================================
    // TRANSACTION
    // ==========================================================

    await _firestore.runTransaction(
      (transaction) async {
        final DocumentSnapshot<Map<String, dynamic>>
            walkSnapshot =
            await transaction.get(walkRef);

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

        final String status =
            data['status']?.toString() ?? '';

        // IMPORTANT:
        // Insta Walk requests are "searching"
        if (status != 'searching') {
          throw Exception(
            'This walk has already been accepted.',
          );
        }

        transaction.update(
          walkRef,
          {
            // Current status
            'status': 'accepted',

            // Main business Walker ID
            'walkerId': walkerId,

            // Firebase internal UID
            'walkerUid': walkerUid,

            // Acceptance time
            'acceptedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // ACCEPTED WALKS FOR CURRENT WALKER
  // ============================================================

  Stream<List<WalkRequest>> acceptedWalksStream() {
    final User? user = _auth.currentUser;

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
