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
  //
  // IMPORTANT:
  // Walker को एक समय में केवल ONE pending request मिलेगी.
  //
  // अगर Firestore में:
  //
  // Request A = searching
  // Request B = searching
  // Request C = searching
  //
  // तो Walker app को केवल ONE request मिलेगी.
  //
  // जब पहली request:
  //
  // searching → accepted
  //
  // या
  //
  // searching → rejected
  //
  // होगी, stream फिर update होगी और अगली
  // searching request दिखाई दे सकती है.
  //
  // RINGTONE LOGIC में कोई बदलाव नहीं किया गया है.
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

      // --------------------------------------------------------
      // ONLY ONE REQUEST
      //
      // बाकी searching requests अभी Walker app को नहीं मिलेंगी.
      // --------------------------------------------------------

      return <WalkRequest>[
        requests.first,
      ];
    });
  }

  // ============================================================
  // ACCEPT WALK
  //
  // searching
  //      ↓
  // accepted
  //
  // Saves:
  // walkerId
  // walkerUid
  // acceptedAt
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

    // ----------------------------------------------------------
    // WALK REQUEST
    // ----------------------------------------------------------

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
            data['status']?.toString() ?? '';

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
            'acceptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  // ============================================================
  // REJECT WALK
  //
  // searching
  //      ↓
  // rejected
  //
  // IMPORTANT:
  // This does NOT delete the Firestore document.
  //
  // It only changes its status, so:
  //
  // pendingRequestsStream()
  // automatically removes it from the Walker app.
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

    // ----------------------------------------------------------
    // WALK REQUEST
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> walkRef =
        _walkRequests.doc(walkId);

    // ----------------------------------------------------------
    // TRANSACTION
    //
    // Prevents rejecting a walk that was already accepted
    // by another walker.
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

        // ------------------------------------------------------
        // ONLY SEARCHING REQUEST CAN BE REJECTED
        // ------------------------------------------------------

        if (status != 'searching') {
          throw Exception(
            'This walk is no longer available.',
          );
        }

        // ------------------------------------------------------
        // REJECT
        // ------------------------------------------------------

        transaction.update(
          walkRef,
          {
            'status': 'rejected',

            // Walker Firebase UID who rejected it.
            'rejectedBy': walkerUid,

            // Walker Business ID who rejected it.
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
  // Creates:
  //
  // active_walk/{walkId}
  //
  // liveWalkSessions/{sessionId}
  //
  // And changes:
  //
  // walk_requests/{walkId}
  // status = active
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

    final String ownerUid =
        walkData['ownerUid']?.toString().trim() ?? '';

    if (ownerId.isEmpty) {
      throw Exception(
        'Owner ID not found for this walk.',
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

        'ownerId': ownerId,
        'ownerUid': ownerUid,

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

        'ownerId': ownerId,
        'ownerUid': ownerUid,

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
    // ==========================================================

    batch.update(
      walkRequestRef,
      {
        'status': 'active',

        'ownerId': ownerId,

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
  //
  // active_walk/{walkId}
  // status = completed
  //
  // liveWalkSessions/{sessionId}
  // status = COMPLETED
  //
  // walk_requests/{walkId}
  // status = completed
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
        sessionId ??
            data?['liveWalkSessionId']
                ?.toString()
                .trim() ??
            'session-$walkId';

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
  //
  // active_walk + liveWalkSessions
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
    final int hours =
        totalSeconds ~/ 3600;

    final int minutes =
        (totalSeconds % 3600) ~/ 60;

    final int seconds =
        totalSeconds % 60;

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
