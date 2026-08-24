// File:
// lib/services/walk_request_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// COMMON LIVE WALK SERVICE
///
/// RESPONSIBILITY:
/// 1. Start Live Walk
/// 2. End Live Walk
/// 3. Watch Live Walk Session
/// 4. Watch Active Walk
/// 5. Update Live GPS/location
/// 6. Add route points
/// 7. Update pee / poop events
/// 8. Add Live Walk events
///
/// NOT RESPONSIBLE FOR:
/// - Insta Walk searching
/// - Insta Walk accept/reject
/// - QR scanning
/// - QR connection
///
/// Insta Walk:
/// insta_walk_service.dart
///       ↓
/// startLiveWalk()
///       ↓
/// live_walk_screen.dart
///
/// QR Walk:
/// walker_qr_walk_service.dart
///       ↓
/// live_walk_screen.dart
///
/// Both flows use the same Live Walk data structure.
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

  /// IMPORTANT:
  /// Both Insta Walk and QR Walk use the same collection.
  CollectionReference<Map<String, dynamic>>
      get _activeWalks {
    return _firestore.collection('active_walks');
  }

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions {
    return _firestore.collection('liveWalkSessions');
  }

  /// walk_requests is still required because Insta Walk
  /// changes:
  ///
  /// searching → accepted → active → completed
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
  // Used by Insta Walk after the request is accepted.
  //
  // Creates / updates:
  //
  // active_walks/{walkId}
  // liveWalkSessions/session-{walkId}
  //
  // Then:
  // walk_requests/{walkId}
  // status = active
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

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId': ownerId,
        'ownerAuthUid': ownerAuthUid,
        'ownerUid': ownerAuthUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerUid': walkerUid,

        // Keep walkerId for compatibility.
        'walkerId': walkerUid,

        // ------------------------------------------------------
        // DOG
        // ------------------------------------------------------

        'dogName': dogName,
        'dogBreed': dogBreed,

        // ------------------------------------------------------
        // LOCATION
        // ------------------------------------------------------

        'currentLat': 0.0,
        'currentLng': 0.0,

        'walkerLocation': null,
        'ownerLocation': null,

        'walkerLocationUpdatedAt': null,
        'ownerLocationUpdatedAt': null,

        // ------------------------------------------------------
        // DISTANCE / TIME
        // ------------------------------------------------------

        'distance': '0.0 km',
        'distanceKm': 0.0,

        'duration': '00:00:00',
        'elapsedSeconds': 0,

        'steps': 0,

        // ------------------------------------------------------
        // EVENTS
        // ------------------------------------------------------

        'peeCount': 0,
        'poopCount': 0,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status': 'active',
        'isLive': true,
        'connectionStatus': 'connected',

        // ------------------------------------------------------
        // SESSION
        // ------------------------------------------------------

        'activeWalkId': id,
        'liveWalkSessionId': sessionId,

        // ------------------------------------------------------
        // TIME
        // ------------------------------------------------------

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
        'walkId': id,

        // ------------------------------------------------------
        // OWNER
        // ------------------------------------------------------

        'ownerId': ownerId,
        'ownerAuthUid': ownerAuthUid,
        'ownerUid': ownerAuthUid,
        'ownerName': ownerName,
        'ownerPhone': ownerPhone,

        // ------------------------------------------------------
        // WALKER
        // ------------------------------------------------------

        'walkerUid': walkerUid,
        'walkerId': walkerUid,

        // ------------------------------------------------------
        // DOG
        // ------------------------------------------------------

        'dogName': dogName,
        'dogBreed': dogBreed,

        // ------------------------------------------------------
        // LOCATION
        // ------------------------------------------------------

        'currentLocation': <String, dynamic>{
          'lat': 0.0,
          'lng': 0.0,
        },

        // ------------------------------------------------------
        // DISTANCE / TIME
        // ------------------------------------------------------

        'distanceKm': 0.0,
        'elapsedSeconds': 0,
        'steps': 0,

        // ------------------------------------------------------
        // EVENTS
        // ------------------------------------------------------

        'peeCount': 0,
        'poopCount': 0,

        'events':
            <Map<String, dynamic>>[],

        // ------------------------------------------------------
        // ROUTE
        // ------------------------------------------------------

        'routeCoordinates':
            <Map<String, dynamic>>[],

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status': 'ACTIVE',
        'isLive': true,

        // ------------------------------------------------------
        // TIME
        // ------------------------------------------------------

        'startedAt':
            FieldValue.serverTimestamp(),

        'endedAt': null,

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
  // Marks:
  //
  // active_walks       → completed
  // liveWalkSessions    → COMPLETED
  // walk_requests       → completed
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
    // ACTIVE WALK
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

        'lastUpdatedAt':
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
    // WALK REQUEST
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

        'lastUpdatedAt':
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
