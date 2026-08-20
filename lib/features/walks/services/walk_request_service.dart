import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/walk_request.dart';

class WalkRequestService {
  WalkRequestService({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _walkRequests =>
      _firestore.collection('walk_requests');

  // ============================================================
  // ACCEPTED WALKS FOR CURRENT WALKER
  // ============================================================

  Stream<List<WalkRequest>> watchAcceptedWalks({
    required String walkerId,
  }) {
    return _walkRequests
        .where('walkerId', isEqualTo: walkerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(WalkRequest.fromFirestore)
              .toList(),
        );
  }

  // ============================================================
  // SINGLE WALK
  // ============================================================

  Future<WalkRequest?> getWalk(String walkId) async {
    final snapshot = await _walkRequests.doc(walkId).get();

    if (!snapshot.exists) {
      return null;
    }

    return WalkRequest.fromFirestore(snapshot);
  }

  // ============================================================
  // ACCEPT WALK
  // ============================================================

  Future<void> acceptWalk({
    required String walkId,
    required String walkerId,
  }) async {
    await _walkRequests.doc(walkId).update({
      'walkerId': walkerId,
      'status': 'accepted',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // REJECT / CANCEL
  // ============================================================

  Future<void> cancelWalk({
    required String walkId,
  }) async {
    await _walkRequests.doc(walkId).update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
