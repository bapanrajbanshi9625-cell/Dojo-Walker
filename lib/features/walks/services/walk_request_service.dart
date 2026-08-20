import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/walk_request.dart';

class WalkRequestService {
  WalkRequestService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // CURRENT WALKER UID
  // ============================================================

  String? get currentUid {
    return _auth.currentUser?.uid;
  }

  // ============================================================
  // AVAILABLE WALK REQUESTS
  // ============================================================

  Stream<List<WalkRequest>> watchAvailableWalks() {
    return _firestore
        .collection('walk_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(WalkRequest.fromFirestore)
          .toList();
    });
  }

  // ============================================================
  // SINGLE WALK
  // ============================================================

  Future<WalkRequest?> getWalkRequest(String requestId) async {
    final snapshot = await _firestore
        .collection('walk_requests')
        .doc(requestId)
        .get();

    if (!snapshot.exists) {
      return null;
    }

    return WalkRequest.fromFirestore(snapshot);
  }

  // ============================================================
  // ACCEPT WALK
  // ============================================================

  Future<void> acceptWalk({
    required String requestId,
    required String walkerId,
  }) async {
    final requestRef = _firestore
        .collection('walk_requests')
        .doc(requestId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(requestRef);

      if (!snapshot.exists) {
        throw Exception('Walk request no longer exists.');
      }

      final data = snapshot.data();

      if (data == null) {
        throw Exception('Walk request data is unavailable.');
      }

      final currentStatus =
          data['status']?.toString().trim() ?? '';

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
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    });
  }

  // ============================================================
  // CANCEL WALK
  // ============================================================

  Future<void> cancelWalk({
    required String requestId,
  }) async {
    await _firestore
        .collection('walk_requests')
        .doc(requestId)
        .update({
      'status': 'cancelled',
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // WATCH ACCEPTED WALK FOR CURRENT WALKER
  // ============================================================

  Stream<List<WalkRequest>> watchAcceptedWalks({
    required String walkerId,
  }) {
    return _firestore
        .collection('walk_requests')
        .where('walkerId', isEqualTo: walkerId)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(WalkRequest.fromFirestore)
          .toList();
    });
  }
}
