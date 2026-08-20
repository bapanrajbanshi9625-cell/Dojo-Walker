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
  //
  // searching
  //     ↓
  // accepted
  //
  // IMPORTANT:
  // यहां Live Walk START नहीं होगी.
  // Start Walk button दबाने पर startWalk() चलेगा.
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
    // WALK REQUEST
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

        // ======================================================
        // ONLY SEARCHING REQUEST CAN BE ACCEPTED
        // ======================================================

        if (status != 'searching') {
          throw Exception(
            'This walk has already been accepted.',
          );
        }

        transaction.update(
          walkRef,
          {
            'status': 'accepted',

            // Main Walker ID
            'walkerId': walkerId,

            // Firebase Auth UID
            'walkerUid': walkerUid,

            // Acceptance time
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

  // ============================================================
  // START WALK
  //
  // accepted
  //     ↓
  // in_progress
  //
  // और active_walks/{walkId} document create होगा.
  // ============================================================

  Future<void> startWalk(
    WalkRequest request,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid = user.uid;

    // ==========================================================
    // GET WALKER ID
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
    // REFERENCES
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        walkRef = _firestore
            .collection('walk_requests')
            .doc(request.id);

    final DocumentReference<Map<String, dynamic>>
        activeWalkRef = _firestore
            .collection('active_walks')
            .doc(request.id);

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

        // ======================================================
        // ONLY ACCEPTED WALK CAN START
        // ======================================================

        if (status != 'accepted') {
          throw Exception(
            'Only an accepted walk can be started.',
          );
        }

        // ======================================================
        // CREATE ACTIVE WALK
        // ======================================================

        transaction.set(
          activeWalkRef,
          {
            // Main IDs
            'walkId': request.id,
            'walkerId': walkerId,
            'walkerUid': walkerUid,

            // Owner
            'ownerUid':
                data['ownerUid']?.toString() ?? '',
            'ownerName':
                data['ownerName']?.toString() ?? '',
            'ownerPhone':
                data['ownerPhone']?.toString() ?? '',

            // Dog
            'dogName':
                data['dogName']?.toString() ?? '',
            'dogBreed':
                data['dogBreed']?.toString() ?? '',
            'dogAge':
                data['dogAge']?.toString() ?? '',

            // Pickup
            'pickupAddress':
                data['pickupAddress']?.toString() ?? '',

            // Walk information
            'distanceKm':
                data['distanceKm'] ?? 0,
            'estimatedTime':
                data['estimatedTime']?.toString() ?? '',
            'walkType':
                data['walkType']?.toString() ?? '',

            // Live walk status
            'status': 'active',

            // Time
            'startedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        // ======================================================
        // UPDATE ORIGINAL REQUEST
        // ======================================================

        transaction.update(
          walkRef,
          {
            'status': 'in_progress',
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
  // END WALK
  //
  // active
  //   ↓
  // completed
  // ============================================================

  Future<void> endWalk(
    String walkId,
  ) async {
    final DocumentReference<Map<String, dynamic>>
        activeWalkRef = _firestore
            .collection('active_walks')
            .doc(walkId);

    final DocumentReference<Map<String, dynamic>>
        walkRef = _firestore
            .collection('walk_requests')
            .doc(walkId);

    await _firestore.runTransaction(
      (transaction) async {
        final DocumentSnapshot<Map<String, dynamic>>
            activeSnapshot =
            await transaction.get(activeWalkRef);

        if (!activeSnapshot.exists) {
          throw Exception(
            'Active walk not found.',
          );
        }

        transaction.update(
          activeWalkRef,
          {
            'status': 'completed',
            'endedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          walkRef,
          {
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

  // ============================================================
  // ACTIVE WALKS FOR CURRENT WALKER
  // ============================================================

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>>
      activeWalksStream() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        <DocumentSnapshot<Map<String, dynamic>>>[],
      );
    }

    return _firestore
        .collection('active_walks')
        .where(
          'walkerUid',
          isEqualTo: user.uid,
        )
        .where(
          'status',
          isEqualTo: 'active',
        )
        .snapshots()
        .map(
          (snapshot) => snapshot.docs,
        );
  }

  // ============================================================
  // GET ONE ACTIVE WALK
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getActiveWalk(
    String walkId,
  ) async {
    return _firestore
        .collection('active_walks')
        .doc(walkId)
        .get();
  }
}
