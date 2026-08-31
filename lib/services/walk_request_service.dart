// File:
// lib/services/walk_request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// COMMON LIVE WALK SERVICE
///
/// FLOW:
///
/// walk_requests/{walkId}
///        ↓ accepted
/// liveWalkSessions/{sessionId}
///        ↓
/// active walking
///        ↓
/// completed
///
/// IMPORTANT:
/// - walkId always comes from walk_requests document ID.
/// - live session has its own document ID.
/// - live session also stores the same walkId.
/// - Completing a walk does NOT update walk_requests.
/// - Walking/live updates belong to liveWalkSessions.
/// - active_walks is only operational live data.
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
      get _activeWalks {
    return _firestore.collection('active_walks');
  }

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions {
    return _firestore.collection('liveWalkSessions');
  }

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_requests');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // START LIVE WALK
  //
  // walk_requests/{walkId}
  //        ↓
  // liveWalkSessions/{sessionId}
  // active_walks/{walkId}
  //
  // The walk request is marked active only at START.
  // After that, live walking data is handled by the
  // live session.
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

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

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
    // OWNER ID
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
    // OWNER
    // ----------------------------------------------------------

    final String ownerName =
        walkData['ownerName']
                ?.toString()
                .trim() ??
            '';

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
    // SESSION ID
    //
    // IMPORTANT:
    // This is a separate Live Session document.
    //
    // walkId:
    // 2GN4eWEi6XISWOqURYrF
    //
    // sessionId:
    // session-2GN4eWEi6XISWOqURYrF
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
        _liveWalkSessions.doc(sessionId);

    // ----------------------------------------------------------
    // BATCH
    // ----------------------------------------------------------

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // active_walks/{walkId}
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
        'walkerUid': walkerUid,
        'walkerId': walkerUid,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // LOCATION
        'currentLat': 0.0,
        'currentLng': 0.0,
        'walkerLocation': null,
        'ownerLocation': null,
        'walkerLocationUpdatedAt': null,
        'ownerLocationUpdatedAt': null,

        // STATS
        'distance': '0.0 km',
        'distanceKm': 0.0,
        'duration': '00:00:00',
        'elapsedSeconds': 0,
        'steps': 0,

        // EVENTS
        'peeCount': 0,
        'poopCount': 0,

        // STATUS
        'status': 'active',
        'isLive': true,
        'connectionStatus': 'connected',

        // SESSION
        'activeWalkId': id,
        'liveWalkSessionId': sessionId,

        // TIME
        'startedAt':
            FieldValue.serverTimestamp(),
        'endedAt': null,
        'updatedAt':
            FieldValue.serverTimestamp(),
        'lastUpdatedAt':
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
        'sessionId': sessionId,

        // IMPORTANT:
        // This is the original walk request ID.
        'walkId': id,

        // OWNER
        'ownerId': ownerId,
        'ownerAuthUid': ownerAuthUid,
        'ownerUid': ownerAuthUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // WALKER
        'walkerUid': walkerUid,
        'walkerId': walkerUid,

        // DOG
        'dogName': dogName,
        'dogBreed': dogBreed,

        // LOCATION
        'currentLocation': <String, dynamic>{
          'lat': 0.0,
          'lng': 0.0,
        },

        // STATS
        'distanceKm': 0.0,
        'elapsedSeconds': 0,
        'steps': 0,

        // EVENTS
        'peeCount': 0,
        'poopCount': 0,
        'events': <Map<String, dynamic>>[],

        // ROUTE
        'routeCoordinates':
            <Map<String, dynamic>>[],

        // STATUS
        'status': 'ACTIVE',
        'isLive': true,
        'walkStarted': true,
        'walkEnded': false,
        'trackingEnded': false,

        // TIME
        'startedAt':
            FieldValue.serverTimestamp(),
        'endedAt': null,
        'completedAt': null,
        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // WALK REQUEST
    //
    // ONLY START STATUS UPDATE.
    // ==========================================================

    batch.update(
      walkRef,
      <String, dynamic>{
        'status': 'active',
        'ownerId': ownerId,
        'ownerAuthUid': ownerAuthUid,
        'ownerUid': ownerAuthUid,
        'walkerUid': walkerUid,
        'walkerId': walkerUid,
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
  // IMPORTANT FINAL FLOW:
  //
  // liveWalkSessions/{sessionId}
  //        → COMPLETED
  //
  // active_walks/{walkId}
  //        → completed
  //
  // walk_requests/{walkId}
  //        → NOT TOUCHED
  //
  // This prevents Walker completion from requiring
  // walk_requests update permission.
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

    final String resolvedSessionId =
        sessionId?.trim().isNotEmpty == true
            ? sessionId!.trim()
            : 'session-$id';

    // ==========================================================
    // IMPORTANT:
    // DO NOT READ walk_requests HERE.
    //
    // The completion operation only needs:
    // - walkId
    // - sessionId
    //
    // This avoids permission-denied on walk_requests.
    // ==========================================================

    final DocumentReference<
            Map<String, dynamic>>
        activeRef =
        _activeWalks.doc(id);

    final DocumentReference<
            Map<String, dynamic>>
        sessionRef =
        _liveWalkSessions.doc(
      resolvedSessionId,
    );

    // ==========================================================
    // VERIFY LIVE SESSION
    // ==========================================================

    final DocumentSnapshot<
            Map<String, dynamic>>
        sessionSnapshot =
        await sessionRef.get();

    if (!sessionSnapshot.exists) {
      throw Exception(
        'Live walk session was not found.',
      );
    }

    final Map<String, dynamic> sessionData =
        sessionSnapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // VERIFY WALK ID
    // ==========================================================

    final String sessionWalkId =
        sessionData['walkId']
                ?.toString()
                .trim() ??
            '';

    if (sessionWalkId.isNotEmpty &&
        sessionWalkId != id) {
      throw Exception(
        'Walk ID does not match the live session.',
      );
    }

    // ==========================================================
    // VERIFY WALKER
    // ==========================================================

    final String sessionWalkerUid =
        sessionData['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (sessionWalkerUid.isNotEmpty &&
        sessionWalkerUid != user.uid.trim()) {
      throw Exception(
        'You are not authorized to complete this walk.',
      );
    }

    // ==========================================================
    // BATCH
    // ==========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // 1. COMPLETE LIVE SESSION
    // ==========================================================

    batch.set(
      sessionRef,
      <String, dynamic>{
        // Keep the relationship permanently.
        'sessionId': resolvedSessionId,
        'walkId': id,

        'status': 'COMPLETED',
        'isLive': false,

        'walkStarted': false,
        'walkEnded': true,
        'trackingEnded': true,

        'completedAt':
            FieldValue.serverTimestamp(),

        'endedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // 2. COMPLETE ACTIVE WALK
    // ==========================================================

    batch.set(
      activeRef,
      <String, dynamic>{
        'walkId': id,

        'status': 'completed',
        'isLive': false,
        'connectionStatus': 'completed',

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),

        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // IMPORTANT:
    //
    // NO walk_requests/{walkId} WRITE HERE.
    //
    // ==========================================================

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

    if (id.isEmpty) {
      return const Stream<
          DocumentSnapshot<
              Map<String, dynamic>>>.empty();
    }

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

    if (id.isEmpty) {
      return const Stream<
          DocumentSnapshot<
              Map<String, dynamic>>>.empty();
    }

    return _activeWalks
        .doc(id)
        .snapshots();
  }

  // ============================================================
  // UPDATE LIVE LOCATION
  //
  // Live walking data goes to:
  // - active_walks
  // - liveWalkSessions
  //
  // NOT walk_requests.
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
      'walkId': walk,

      'currentLat': latitude,
      'currentLng': longitude,

      'walkerLocation': <
          String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
      },

      'walkerLocationUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      'lastUpdatedAt':
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
      'walkId': walk,

      'currentLocation': <
          String, dynamic>{
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
  //
  // Live session is the source of truth.
  // active_walks is operational mirror.
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
        peeCount < 0
            ? 0
            : peeCount;

    final int safePoop =
        poopCount < 0
            ? 0
            : poopCount;

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      _activeWalks.doc(walk),
      <String, dynamic>{
        'peeCount': safePee,
        'poopCount': safePoop,
        'updatedAt':
            FieldValue.serverTimestamp(),
        'lastUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(
        merge: true,
      ),
    );

    batch.set(
      _liveWalkSessions.doc(session),
      <String, dynamic>{
        'walkId': walk,
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
