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
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _walkRequests =>
      _firestore.collection('walk_requests');

  CollectionReference<Map<String, dynamic>> get _activeWalks =>
      _firestore.collection('active_walk');

  CollectionReference<Map<String, dynamic>> get _liveWalkSessions =>
      _firestore.collection('liveWalkSessions');

  CollectionReference<Map<String, dynamic>> get _phoneAccounts =>
      _firestore.collection('phoneAccounts');

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser => _auth.currentUser;

  // ============================================================
  // PENDING / SEARCHING WALK REQUESTS
  // ============================================================

  Stream<List<WalkRequest>> pendingRequestsStream() {
    return _walkRequests
        .where(
          'status',
          isEqualTo: 'searching',
        )
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return <WalkRequest>[];
      }

      final List<WalkRequest> requests = snapshot.docs
          .map(
            (doc) => WalkRequest.fromFirestore(doc),
          )
          .toList();

      // Walker को एक समय में केवल ONE request दिखेगी.
      return <WalkRequest>[
        requests.first,
      ];
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

    // ----------------------------------------------------------
    // GET WALKER ID
    // phoneAccounts/{Firebase UID}
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>> accountSnapshot =
        await _phoneAccounts.doc(walkerUid).get();

    final Map<String, dynamic>? accountData =
        accountSnapshot.data();

    final String walkerId =
        accountData?['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    final DocumentReference<Map<String, dynamic>> walkRef =
        _walkRequests.doc(walkId);

    // ----------------------------------------------------------
    // TRANSACTION
    // ----------------------------------------------------------

    await _firestore.runTransaction(
      (transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> walkSnapshot =
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
            data['status']?.toString().trim() ?? '';

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
  // REJECT WALK
  // ============================================================

  Future<void> rejectWalk(String walkId) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid = user.uid;

    // ----------------------------------------------------------
    // GET WALKER ID
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>> accountSnapshot =
        await _phoneAccounts.doc(walkerUid).get();

    final Map<String, dynamic>? accountData =
        accountSnapshot.data();

    final String walkerId =
        accountData?['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    final DocumentReference<Map<String, dynamic>> walkRef =
        _walkRequests.doc(walkId);

    // ----------------------------------------------------------
    // TRANSACTION
    // ----------------------------------------------------------

    await _firestore.runTransaction(
      (transaction) async {
        final DocumentSnapshot<Map<String, dynamic>> walkSnapshot =
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
            data['status']?.toString().trim() ?? '';

        if (status != 'searching') {
          throw Exception(
            'This walk is no longer available.',
          );
        }

        transaction.update(
          walkRef,
          {
            'status': 'rejected',
            'rejectedBy': walkerUid,
            'rejectedWalkerId': walkerId,
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
  // ACCEPTED WALKS FOR CURRENT WALKER
  // ============================================================

  Stream<List<WalkRequest>> acceptedWalksStream() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        <WalkRequest>[],
      );
    }

    return _walkRequests
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
            (doc) => WalkRequest.fromFirestore(doc),
          )
          .toList();
    });
  }

  // ============================================================
  // GET SINGLE WALK REQUEST
  // ============================================================

  Future<WalkRequest?> getWalkRequest(
    String walkId,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _walkRequests.doc(walkId).get();

    if (!snapshot.exists) {
      return null;
    }

    return WalkRequest.fromFirestore(snapshot);
  }

  // ============================================================
  // START LIVE WALK
  //
  // IMPORTANT OWNER UID FIX:
  //
  // New Insta Walk request:
  //     ownerAuthUid = Firebase Auth UID
  //
  // Older requests:
  //     ownerUid = Firebase Auth UID
  //
  // इसलिए:
  //
  // ownerAuthUid → primary
  // ownerUid     → fallback
  //
  // Active/live documents में दोनों fields save किए जाते हैं
  // ताकि existing code भी न टूटे.
  // ============================================================

  Future<String> startLiveWalk(
    String walkId,
  ) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid = user.uid;

    // ----------------------------------------------------------
    // GET WALKER ID
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>> accountSnapshot =
        await _phoneAccounts.doc(walkerUid).get();

    final Map<String, dynamic>? accountData =
        accountSnapshot.data();

    final String walkerId =
        accountData?['walkerId']?.toString().trim() ?? '';

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    // ----------------------------------------------------------
    // GET WALK REQUEST
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> walkRequestRef =
        _walkRequests.doc(walkId);

    final DocumentSnapshot<Map<String, dynamic>> walkSnapshot =
        await walkRequestRef.get();

    if (!walkSnapshot.exists) {
      throw Exception(
        'Walk request not found.',
      );
    }

    final Map<String, dynamic>? walkData =
        walkSnapshot.data();

    if (walkData == null) {
      throw Exception(
        'Walk request data is empty.',
      );
    }

    // ----------------------------------------------------------
    // VERIFY WALKER
    // ----------------------------------------------------------

    final String savedWalkerUid =
        walkData['walkerUid']?.toString().trim() ?? '';

    if (savedWalkerUid.isNotEmpty &&
        savedWalkerUid != walkerUid) {
      throw Exception(
        'This walk belongs to another walker.',
      );
    }

    // ----------------------------------------------------------
    // OWNER ID
    // ----------------------------------------------------------

    final String ownerId =
        walkData['ownerId']?.toString().trim() ?? '';

    if (ownerId.isEmpty) {
      throw Exception(
        'Owner ID not found for this walk.',
      );
    }

    // ----------------------------------------------------------
    // OWNER AUTH UID
    //
    // NEW STRUCTURE:
    // ownerAuthUid
    //
    // OLD STRUCTURE:
    // ownerUid
    //
    // Primary = ownerAuthUid
    // Fallback = ownerUid
    // ----------------------------------------------------------

    String ownerAuthUid =
        walkData['ownerAuthUid']
                ?.toString()
                .trim() ??
            '';

    if (ownerAuthUid.isEmpty) {
      ownerAuthUid =
          walkData['ownerUid']
                  ?.toString()
                  .trim() ??
              '';
    }

    // ----------------------------------------------------------
    // FINAL SAFETY CHECK
    // ----------------------------------------------------------

    if (ownerAuthUid.isEmpty) {
      throw Exception(
        'Owner Auth UID not found for this walk.',
      );
    }

    // ----------------------------------------------------------
    // DOG
    // ----------------------------------------------------------

    final String dogName =
        walkData['dogName']?.toString().trim() ?? '';

    // ----------------------------------------------------------
    // SESSION ID
    // ----------------------------------------------------------

    final String sessionId =
        'session-$walkId';

    // ----------------------------------------------------------
    // ACTIVE WALK REFERENCE
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> activeWalkRef =
        _activeWalks.doc(walkId);

    // ----------------------------------------------------------
    // LIVE SESSION REFERENCE
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> sessionRef =
        _liveWalkSessions.doc(sessionId);

    // ----------------------------------------------------------
    // BATCH
    // ----------------------------------------------------------

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // active_walk/{walkId}
    // ==========================================================

    batch.set(
      activeWalkRef,
      {
        'currentLat': 0.0,
        'currentLng': 0.0,

        'distance': '0.0 km',
        'duration': '00:00:00',

        // Owner business ID
        'ownerId': ownerId,

        // NEW canonical Auth UID
        'ownerAuthUid': ownerAuthUid,

        // Backward compatibility
        'ownerUid': ownerAuthUid,

        // Walker
        'walkerId': walkerId,
        'walkerUid': walkerUid,

        'peeCount': 0,
        'poopCount': 0,

        'status': 'active',

        'walkId': walkId,

        'startedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // liveWalkSessions/{sessionId}
    // ==========================================================

    batch.set(
      sessionRef,
      {
        'id': sessionId,

        'walkId': walkId,

        // Owner
        'ownerId': ownerId,
        'ownerAuthUid': ownerAuthUid,

        // Backward compatibility
        'ownerUid': ownerAuthUid,

        // Walker
        'walkerId': walkerId,
        'walkerUid': walkerUid,

        'dogName': dogName,

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

        'startedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // WALK REQUEST → ACTIVE
    //
    // Keep ownerAuthUid as the canonical field.
    // Also keep ownerUid for old code compatibility.
    // ==========================================================

    batch.update(
      walkRequestRef,
      {
        'status': 'active',

        'ownerId': ownerId,

        'ownerAuthUid': ownerAuthUid,

        'ownerUid': ownerAuthUid,

        'walkerId': walkerId,
        'walkerUid': walkerUid,

        'activeWalkId': walkId,

        'liveWalkSessionId': sessionId,

        'startedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();

    return sessionId;
  }

  // ============================================================
  // END LIVE WALK
  // ============================================================

  Future<void> endLiveWalk(
    String walkId, {
    String? sessionId,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final DocumentReference<Map<String, dynamic>> walkRequestRef =
        _walkRequests.doc(walkId);

    final DocumentSnapshot<Map<String, dynamic>> walkSnapshot =
        await walkRequestRef.get();

    if (!walkSnapshot.exists) {
      throw Exception(
        'Walk request not found.',
      );
    }

    final Map<String, dynamic>? data =
        walkSnapshot.data();

    final String resolvedSessionId =
        sessionId?.trim().isNotEmpty == true
            ? sessionId!.trim()
            : data?['liveWalkSessionId']
                    ?.toString()
                    .trim()
                    .isNotEmpty ==
                true
                ? data!['liveWalkSessionId']
                    .toString()
                    .trim()
                : 'session-$walkId';

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // active_walk
    // ==========================================================

    batch.set(
      _activeWalks.doc(walkId),
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

    // ==========================================================
    // liveWalkSessions
    // ==========================================================

    batch.set(
      _liveWalkSessions.doc(
        resolvedSessionId,
      ),
      {
        'status': 'COMPLETED',
        'updatedAt':
            FieldValue.serverTimestamp(),
        'endedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // walk_requests
    // ==========================================================

    batch.update(
      walkRequestRef,
      {
        'status': 'completed',
        'updatedAt':
            FieldValue.serverTimestamp(),
        'endedAt':
            FieldValue.serverTimestamp(),
      },
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
    return _liveWalkSessions
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
    return _activeWalks
        .doc(walkId)
        .snapshots();
  }

  // ============================================================
  // UPDATE CURRENT LOCATION
  // ============================================================

  Future<void> updateLiveLocation({
    required String walkId,
    required String sessionId,
    required double latitude,
    required double longitude,
    double? distanceKm,
    int? elapsedSeconds,
  }) async {
    final Map<String, dynamic> activeData = {
      'currentLat': latitude,
      'currentLng': longitude,
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (distanceKm != null) {
      activeData['distance'] =
          '${distanceKm.toStringAsFixed(1)} km';
    }

    if (elapsedSeconds != null) {
      activeData['duration'] =
          _formatDuration(
        elapsedSeconds,
      );
    }

    final Map<String, dynamic> sessionData = {
      'currentLocation': {
        'lat': latitude,
        'lng': longitude,
      },
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (distanceKm != null) {
      sessionData['distanceKm'] =
          distanceKm;
    }

    if (elapsedSeconds != null) {
      sessionData['elapsedSeconds'] =
          elapsedSeconds;
    }

    await Future.wait([
      _activeWalks
          .doc(walkId)
          .set(
            activeData,
            SetOptions(
              merge: true,
            ),
          ),
      _liveWalkSessions
          .doc(sessionId)
          .set(
            sessionData,
            SetOptions(
              merge: true,
            ),
          ),
    ]);
  }

  // ============================================================
  // ADD ROUTE LOCATION
  // ============================================================

  Future<void> addRoutePoint({
    required String sessionId,
    required double latitude,
    required double longitude,
  }) async {
    final DocumentReference<Map<String, dynamic>> sessionRef =
        _liveWalkSessions.doc(sessionId);

    await sessionRef.update({
      'routeCoordinates':
          FieldValue.arrayUnion([
        {
          'lat': latitude,
          'lng': longitude,
          'timestamp':
              DateTime.now()
                  .millisecondsSinceEpoch,
        },
      ]),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // UPDATE PEE / POOP
  // ============================================================

  Future<void> updateWalkEvents({
    required String walkId,
    required String sessionId,
    required int peeCount,
    required int poopCount,
  }) async {
    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      _activeWalks.doc(walkId),
      {
        'peeCount': peeCount,
        'poopCount': poopCount,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    batch.set(
      _liveWalkSessions.doc(sessionId),
      {
        'peeCount': peeCount,
        'poopCount': poopCount,
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
  // ADD WALK EVENT
  // ============================================================

  Future<void> addWalkEvent({
    required String sessionId,
    required String type,
    String note = '',
  }) async {
    final Map<String, dynamic> event = {
      'id': DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      'type': type,
      'note': note,
      'timestamp':
          DateTime.now().toIso8601String(),
    };

    await _liveWalkSessions
        .doc(sessionId)
        .update({
      'events':
          FieldValue.arrayUnion([
        event,
      ]),
      'updatedAt':
          FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // DURATION FORMATTER
  // ============================================================

  String _formatDuration(
    int totalSeconds,
  ) {
    final int safeSeconds =
        totalSeconds < 0
            ? 0
            : totalSeconds;

    final int hours =
        safeSeconds ~/ 3600;

    final int minutes =
        (safeSeconds % 3600) ~/ 60;

    final int seconds =
        safeSeconds % 60;

    final String hh =
        hours.toString().padLeft(
              2,
              '0',
            );

    final String mm =
        minutes.toString().padLeft(
              2,
              '0',
            );

    final String ss =
        seconds.toString().padLeft(
              2,
              '0',
            );

    return '$hh:$mm:$ss';
  }
}
