// File:
// lib/services/walk_request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/walk_request.dart';

/// ============================================================
/// WALK REQUEST SERVICE
///
/// RESPONSIBILITY:
/// 1. Insta Walk / walk_requests flow
/// 2. Accept / reject walk
/// 3. Start Live Walk
/// 4. active_walk + liveWalkSessions
/// 5. Live GPS/location
/// 6. Route points
/// 7. Pee / poop events
/// 8. End Live Walk
///
/// NOTE:
/// QR scanning / QR connection is NOT handled here.
/// QR is handled separately by WalkerWalkService.
/// ============================================================

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

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_requests');
  }

  CollectionReference<Map<String, dynamic>>
      get _activeWalks {
    return _firestore.collection('active_walk');
  }

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions {
    return _firestore.collection('liveWalkSessions');
  }

  CollectionReference<Map<String, dynamic>>
      get _phoneAccounts {
    return _firestore.collection('phoneAccounts');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // PENDING / SEARCHING REQUESTS
  //
  // INSTA WALK FLOW
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

            // Walker ko ek time par
            // sirf ONE request dikhani hai.
            return <WalkRequest>[
              requests.first,
            ];
          },
        );
  }

  // ============================================================
  // GET WALKER ACCOUNT
  // ============================================================

  Future<String> _getWalkerId(
    String walkerUid,
  ) async {
    final String uid =
        walkerUid.trim();

    if (uid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _phoneAccounts
            .doc(uid)
            .get();

    final Map<String, dynamic>? data =
        snapshot.data();

    final String walkerId =
        data?['walkerId']
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found.',
      );
    }

    return walkerId;
  }

  // ============================================================
  // ACCEPT WALK
  //
  // INSTA WALK
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

    final String walkerId =
        await _getWalkerId(
      walkerUid,
    );

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
            'This walk has already been accepted.',
          );
        }

        transaction.update(
          walkRef,
          <String, dynamic>{
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
  //
  // INSTA WALK
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

    final String walkerId =
        await _getWalkerId(
      walkerUid,
    );

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
  // ACCEPTED WALKS
  //
  // INSTA WALK
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
  // GET SINGLE WALK
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
  // START LIVE WALK
  //
  // INSTA WALK
  //
  // Creates:
  //
  // active_walk/{walkId}
  // liveWalkSessions/session-{walkId}
  //
  // Then marks:
  // walk_requests/{walkId}
  // ============================================================

  Future<String> startLiveWalk(
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

    final String walkerId =
        await _getWalkerId(
      walkerUid,
    );

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ----------------------------------------------------------
    // WALK REQUEST
    // ----------------------------------------------------------

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    final DocumentSnapshot<
            Map<String, dynamic>>
        walkSnapshot =
        await walkRef.get();

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
        walkData['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (savedWalkerUid.isNotEmpty &&
        savedWalkerUid != walkerUid) {
      throw Exception(
        'This walk belongs to another walker.',
      );
    }

    // ----------------------------------------------------------
    // OWNER BUSINESS ID
    // ----------------------------------------------------------

    final String ownerId =
        walkData['ownerId']
                ?.toString()
                .trim() ??
            '';

    if (ownerId.isEmpty) {
      throw Exception(
        'Owner ID not found for this walk.',
      );
    }

    // ----------------------------------------------------------
    // OWNER AUTH UID
    //
    // NEW:
    // ownerAuthUid
    //
    // OLD:
    // ownerUid
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

    if (ownerAuthUid.isEmpty) {
      throw Exception(
        'Owner Auth UID not found for this walk.',
      );
    }

    // ----------------------------------------------------------
    // OWNER NAME
    // ----------------------------------------------------------

    final String ownerName =
        walkData['ownerName']
                ?.toString()
                .trim() ??
            '';

    // ----------------------------------------------------------
    // OWNER PHONE
    // ----------------------------------------------------------

    final String ownerPhone =
        walkData['ownerPhone']
                ?.toString()
                .trim() ??
            '';

    // ----------------------------------------------------------
    // DOG
    // ----------------------------------------------------------

    final String dogName =
        walkData['dogName']
                ?.toString()
                .trim() ??
            '';

    final String dogBreed =
        walkData['dogBreed']
                ?.toString()
                .trim() ??
            '';

    // ----------------------------------------------------------
    // SESSION
    // ----------------------------------------------------------

    final String sessionId =
        'session-$id';

    final DocumentReference<
            Map<String, dynamic>>
        activeRef =
        _activeWalks.doc(id);

    final DocumentReference<
            Map<String, dynamic>>
        sessionRef =
        _liveWalkSessions.doc(
      sessionId,
    );

    // ----------------------------------------------------------
    // BATCH
    // ----------------------------------------------------------

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // active_walk/{walkId}
    // ==========================================================

    batch.set(
      activeRef,
      <String, dynamic>{
        'walkId': id,

        // OWNER
        'ownerId': ownerId,
        'ownerAuthUid': ownerAuthUid,
        'ownerUid': ownerAuthUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // WALKER
        'walkerId': walkerId,
        'walkerUid': walkerUid,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // LOCATION
        'currentLat': 0.0,
        'currentLng': 0.0,

        // DISTANCE / TIME
        'distance': '0.0 km',
        'duration': '00:00:00',
        'distanceKm': 0.0,
        'elapsedSeconds': 0,

        // EVENTS
        'steps': 0,
        'peeCount': 0,
        'poopCount': 0,

        // STATUS
        'status': 'active',
        'isLive': true,
        'connectionStatus': 'connected',

        // SESSION
        'liveWalkSessionId': sessionId,

        // TIME
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
      <String, dynamic>{
        'id': sessionId,
        'walkId': id,

        // OWNER
        'ownerId': ownerId,
        'ownerAuthUid': ownerAuthUid,
        'ownerUid': ownerAuthUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // WALKER
        'walkerId': walkerId,
        'walkerUid': walkerUid,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // LOCATION
        'currentLocation': {
          'lat': 0.0,
          'lng': 0.0,
        },

        // DISTANCE / TIME
        'distanceKm': 0.0,
        'elapsedSeconds': 0,
        'steps': 0,

        // EVENTS
        'peeCount': 0,
        'poopCount': 0,
        'events':
            <Map<String, dynamic>>[],
        'routeCoordinates':
            <Map<String, dynamic>>[],

        // STATUS
        'status': 'ACTIVE',
        'isLive': true,

        // TIME
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
    // WALK REQUEST
    // ==========================================================

    batch.update(
      walkRef,
      <String, dynamic>{
        'status': 'active',

        'ownerId': ownerId,
        'ownerAuthUid': ownerAuthUid,
        'ownerUid': ownerAuthUid,

        'walkerId': walkerId,
        'walkerUid': walkerUid,

        'activeWalkId': id,
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
  // INSTA WALK
  // ============================================================

  Future<void> endLiveWalk(
    String walkId, {
    String? sessionId,
  }) async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
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

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await walkRef.get();

    if (!snapshot.exists) {
      throw Exception(
        'Walk request not found.',
      );
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    String resolvedSessionId =
        sessionId?.trim() ?? '';

    if (resolvedSessionId.isEmpty) {
      resolvedSessionId =
          data?['liveWalkSessionId']
                  ?.toString()
                  .trim() ??
              '';
    }

    if (resolvedSessionId.isEmpty) {
      resolvedSessionId =
          'session-$id';
    }

    final WriteBatch batch =
        _firestore.batch();

    // ----------------------------------------------------------
    // active_walk
    // ----------------------------------------------------------

    batch.set(
      _activeWalks.doc(id),
      <String, dynamic>{
        'status': 'completed',
        'isLive': false,
        'connectionStatus': 'completed',
        'endedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // liveWalkSessions
    // ----------------------------------------------------------

    batch.set(
      _liveWalkSessions.doc(
        resolvedSessionId,
      ),
      <String, dynamic>{
        'status': 'COMPLETED',
        'isLive': false,
        'endedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // walk_requests
    // ----------------------------------------------------------

    batch.update(
      walkRef,
      <String, dynamic>{
        'status': 'completed',
        'endedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );

    await batch.commit();
  }

  // ============================================================
  // LIVE SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<
          Map<String, dynamic>>>
      liveWalkSessionStream(
    String sessionId,
  ) {
    final String id =
        sessionId.trim();

    return _liveWalkSessions
        .doc(id)
        .snapshots();
  }

  // ============================================================
  // ACTIVE WALK STREAM
  // ============================================================

  Stream<DocumentSnapshot<
          Map<String, dynamic>>>
      activeWalkStream(
    String walkId,
  ) {
    final String id =
        walkId.trim();

    return _activeWalks
        .doc(id)
        .snapshots();
  }

  // ============================================================
  // UPDATE LIVE LOCATION
  // ============================================================

  Future<void> updateLiveLocation({
    required String walkId,
    required String sessionId,
    required double latitude,
    required double longitude,
    double? distanceKm,
    int? elapsedSeconds,
    int? steps,
  }) async {
    if (!_validCoordinate(
      latitude,
      longitude,
    )) {
      return;
    }

    final String walk =
        walkId.trim();

    final String session =
        sessionId.trim();

    if (walk.isEmpty ||
        session.isEmpty) {
      throw Exception(
        'Walk session information is missing.',
      );
    }

    final Map<String, dynamic>
        activeData =
        <String, dynamic>{
      'currentLat': latitude,
      'currentLng': longitude,
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (distanceKm != null &&
        distanceKm >= 0) {
      activeData['distanceKm'] =
          distanceKm;

      activeData['distance'] =
          '${distanceKm.toStringAsFixed(1)} km';
    }

    if (elapsedSeconds != null &&
        elapsedSeconds >= 0) {
      activeData['elapsedSeconds'] =
          elapsedSeconds;

      activeData['duration'] =
          _formatDuration(
        elapsedSeconds,
      );
    }

    if (steps != null &&
        steps >= 0) {
      activeData['steps'] =
          steps;
    }

    final Map<String, dynamic>
        sessionData =
        <String, dynamic>{
      'currentLocation': {
        'lat': latitude,
        'lng': longitude,
      },
      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    if (distanceKm != null &&
        distanceKm >= 0) {
      sessionData['distanceKm'] =
          distanceKm;
    }

    if (elapsedSeconds != null &&
        elapsedSeconds >= 0) {
      sessionData['elapsedSeconds'] =
          elapsedSeconds;
    }

    if (steps != null &&
        steps >= 0) {
      sessionData['steps'] =
          steps;
    }

    await Future.wait(
      <Future<void>>[
        _activeWalks
            .doc(walk)
            .set(
              activeData,
              SetOptions(
                merge: true,
              ),
            ),
        _liveWalkSessions
            .doc(session)
            .set(
              sessionData,
              SetOptions(
                merge: true,
              ),
            ),
      ],
    );
  }

  // ============================================================
  // ADD ROUTE POINT
  // ============================================================

  Future<void> addRoutePoint({
    required String sessionId,
    required double latitude,
    required double longitude,
  }) async {
    if (!_validCoordinate(
      latitude,
      longitude,
    )) {
      return;
    }

    final String session =
        sessionId.trim();

    if (session.isEmpty) {
      return;
    }

    final Map<String, dynamic> point =
        <String, dynamic>{
      'lat': latitude,
      'lng': longitude,
      'timestamp':
          DateTime.now()
              .millisecondsSinceEpoch,
    };

    await _liveWalkSessions
        .doc(session)
        .set(
      <String, dynamic>{
        'routeCoordinates':
            FieldValue.arrayUnion(
          <Map<String, dynamic>>[
            point,
          ],
        ),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
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
    final String walk =
        walkId.trim();

    final String session =
        sessionId.trim();

    if (walk.isEmpty ||
        session.isEmpty) {
      throw Exception(
        'Walk session information is missing.',
      );
    }

    final int safePee =
        peeCount < 0 ? 0 : peeCount;

    final int safePoop =
        poopCount < 0
            ? 0
            : poopCount;

    final WriteBatch batch =
        _firestore.batch();

    // ----------------------------------------------------------
    // ACTIVE WALK
    // ----------------------------------------------------------

    batch.set(
      _activeWalks.doc(walk),
      <String, dynamic>{
        'peeCount': safePee,
        'poopCount': safePoop,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // LIVE SESSION
    // ----------------------------------------------------------

    batch.set(
      _liveWalkSessions.doc(session),
      <String, dynamic>{
        'peeCount': safePee,
        'poopCount': safePoop,
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
  // ADD EVENT
  // ============================================================

  Future<void> addWalkEvent({
    required String sessionId,
    required String type,
    String note = '',
  }) async {
    final String session =
        sessionId.trim();

    if (session.isEmpty) {
      throw Exception(
        'Session ID is missing.',
      );
    }

    final String eventType =
        type.trim();

    if (eventType.isEmpty) {
      throw Exception(
        'Event type is missing.',
      );
    }

    final Map<String, dynamic> event =
        <String, dynamic>{
      'id': DateTime.now()
          .millisecondsSinceEpoch
          .toString(),
      'type': eventType,
      'note': note.trim(),
      'timestamp':
          DateTime.now()
              .toIso8601String(),
    };

    await _liveWalkSessions
        .doc(session)
        .set(
      <String, dynamic>{
        'events':
            FieldValue.arrayUnion(
          <Map<String, dynamic>>[
            event,
          ],
        ),
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // FORMAT DURATION
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
        hours
            .toString()
            .padLeft(2, '0');

    final String mm =
        minutes
            .toString()
            .padLeft(2, '0');

    final String ss =
        seconds
            .toString()
            .padLeft(2, '0');

    return '$hh:$mm:$ss';
  }

  // ============================================================
  // VALID COORDINATE
  // ============================================================

  bool _validCoordinate(
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 &&
            longitude == 0);
  }
}
