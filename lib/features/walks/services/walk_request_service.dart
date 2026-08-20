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

  CollectionReference<Map<String, dynamic>>
      get _walkRequests =>
          _firestore.collection('walk_requests');

  CollectionReference<Map<String, dynamic>>
      get _walkers =>
          _firestore.collection('walkers');

  // ==========================================================
  // PENDING WALK REQUESTS
  // ==========================================================

  Stream<List<WalkRequest>> pendingRequestsStream() {
    return _walkRequests
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) {
            return snapshot.docs
                .map(
                  WalkRequest.fromFirestore,
                )
                .toList();
          },
        );
  }

  // ==========================================================
  // GET CURRENT WALKER ID
  // ==========================================================

  Future<String> getCurrentWalkerId() async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Walker is not signed in.');
    }

    final walkerDoc =
        await _walkers.doc(user.uid).get();

    if (!walkerDoc.exists) {
      throw Exception(
        'Walker profile was not found.',
      );
    }

    final data = walkerDoc.data();

    final walkerId =
        data?['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID is missing from walker profile.',
      );
    }

    return walkerId;
  }

  // ==========================================================
  // ACCEPT WALK
  // ==========================================================

  Future<WalkRequest> acceptWalk(
    String requestId,
  ) async {
    final walkerId =
        await getCurrentWalkerId();

    final requestRef =
        _walkRequests.doc(requestId);

    late WalkRequest acceptedRequest;

    await _firestore.runTransaction(
      (transaction) async {
        final snapshot =
            await transaction.get(requestRef);

        if (!snapshot.exists) {
          throw Exception(
            'Walk request no longer exists.',
          );
        }

        final data =
            snapshot.data() ?? {};

        final currentStatus =
            data['status']?.toString() ?? '';

        if (currentStatus != 'pending') {
          throw Exception(
            'This walk has already been accepted.',
          );
        }

        transaction.update(
          requestRef,
          {
            'status': 'accepted',
            'walkerId': walkerId,
            'acceptedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        final updatedData =
            Map<String, dynamic>.from(data);

        updatedData['status'] =
            'accepted';

        updatedData['walkerId'] =
            walkerId;

        acceptedRequest =
            WalkRequest.fromFirestore(
          _FakeDocumentSnapshot(
            requestId,
            updatedData,
          ),
        );
      },
    );

    return acceptedRequest;
  }

  // ==========================================================
  // MY ACCEPTED WALKS
  // ==========================================================

  Stream<List<WalkRequest>>
      acceptedWalksStream() async* {
    final walkerId =
        await getCurrentWalkerId();

    yield* _walkRequests
        .where(
          'walkerId',
          isEqualTo: walkerId,
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
                  WalkRequest.fromFirestore,
                )
                .toList();
          },
        );
  }

  // ==========================================================
  // SINGLE WALK
  // ==========================================================

  Stream<WalkRequest?>
      walkStream(String requestId) {
    return _walkRequests
        .doc(requestId)
        .snapshots()
        .map(
          (snapshot) {
            if (!snapshot.exists) {
              return null;
            }

            return WalkRequest
                .fromFirestore(snapshot);
          },
        );
  }
}

// ============================================================
// INTERNAL SNAPSHOT ADAPTER
// ============================================================

class _FakeDocumentSnapshot
    implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;

  final Map<String, dynamic> _data;

  _FakeDocumentSnapshot(
    this.id,
    this._data,
  );

  @override
  Map<String, dynamic>? data() {
    return _data;
  }

  @override
  SnapshotMetadata get metadata =>
      throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>>
      get reference =>
          throw UnimplementedError();

  @override
  bool get exists => true;

  @override
  dynamic operator [](Object field) {
    return _data[field];
  }

  @override
  T? get<T extends Object?>(String field) {
    return _data[field] as T?;
  }
}
