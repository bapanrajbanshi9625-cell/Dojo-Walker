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
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => WalkRequest.fromFirestore(doc),
          )
          .toList();
    });
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

    if (!accountSnapshot.exists) {
      throw Exception(
        'Walker account not found.',
      );
    }

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
    // ACCEPT USING TRANSACTION
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

        // Only searching requests can be accepted.
        if (status != 'searching') {
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
        .map((snapshot) {
      return snapshot.docs
          .map(
            (doc) =>
                WalkRequest.fromFirestore(doc),
          )
          .toList();
    });
  }

  // ============================================================
  // START WALK
  //
  // Creates/updates:
  //
  // active_walk/{walkId}
  //
  // liveWalkSessions/session-{walkId}
  // ============================================================

  Future<String> startWalk({
    required WalkRequest request,
  }) async {
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
            request.walkerId;

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    // ==========================================================
    // IDs
    // ==========================================================

    final String walkId = request.walkId;

    if (walkId.trim().isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final String sessionId =
        'session-$walkId';

    // ==========================================================
    // REFERENCES
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        activeWalkRef = _firestore
            .collection('active_walk')
            .doc(walkId);

    final DocumentReference<Map<String, dynamic>>
        sessionRef = _firestore
            .collection('liveWalkSessions')
            .doc(sessionId);

    // ==========================================================
    // CREATE ACTIVE WALK + LIVE SESSION
    // ==========================================================

    await _firestore.runTransaction(
      (transaction) async {
        final DocumentSnapshot<Map<String, dynamic>>
            existingActiveWalk =
            await transaction.get(activeWalkRef);

        if (existingActiveWalk.exists) {
          final Map<String, dynamic>? existingData =
              existingActiveWalk.data();

          final String existingStatus =
              existingData?['status']
                      ?.toString()
                      .toLowerCase() ??
                  '';

          if (existingStatus == 'active') {
            throw Exception(
              'This walk is already active.',
            );
          }
        }

        transaction.set(
          activeWalkRef,
          {
            'ownerId': request.ownerId,
            'walkerId': walkerId,
            'currentLat': 0.0,
            'currentLng': 0.0,
            'distance': '0.0 km',
            'duration': '00:00:00',
            'peeCount': 0,
            'poopCount': 0,
            'status': 'active',
            'startedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        transaction.set(
          sessionRef,
          {
            'id': sessionId,
            'ownerId': request.ownerId,
            'walkerId': walkerId,
            'dogName': request.dogName,
            'currentLocation': {
              'lat': 0.0,
              'lng': 0.0,
            },
            'distanceKm': 0.0,
            'elapsedSeconds': 0,
            'peeCount': 0,
            'poopCount': 0,
            'events': <Map<String, dynamic>>[],
            'routeCoordinates':
                <Map<String, dynamic>>[],
            'status': 'ACTIVE',
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      },
    );

    return sessionId;
  }

  // ============================================================
  // END WALK
  // ============================================================

  Future<void> endWalk({
    required String walkId,
    required String sessionId,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        activeWalkRef = _firestore
            .collection('active_walk')
            .doc(walkId);

    final DocumentReference<Map<String, dynamic>>
        sessionRef = _firestore
            .collection('liveWalkSessions')
            .doc(sessionId);

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      activeWalkRef,
      {
        'status': 'completed',
        'updatedAt':
            FieldValue.serverTimestamp(),
        'endedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    batch.set(
      sessionRef,
      {
        'status': 'COMPLETED',
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    await batch.commit();
  }

  // ============================================================
  // LIVE WALK SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      liveWalkSessionStream(
    String sessionId,
  ) {
    return _firestore
        .collection('liveWalkSessions')
        .doc(sessionId)
        .snapshots();
  }

  // ============================================================
  // ACTIVE WALK STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      activeWalkStream(
    String walkId,
  ) {
    return _firestore
        .collection('active_walk')
        .doc(walkId)
        .snapshots();
  }
}
