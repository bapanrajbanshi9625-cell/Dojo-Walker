// File:
// lib/features/live_walk/services/live_walk_firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LiveWalkFirestoreService {
  LiveWalkFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('liveWalkSessions');

  CollectionReference<Map<String, dynamic>> get _walkRequests =>
      _firestore.collection('walk_request');

  // ============================================================
  // REQUEST ID VALIDATION
  //
  // Canonical Walk ID:
  //
  // DW000001
  // DW000002
  // DW000003
  //
  // Same ID is used for:
  //
  // walk_request/{requestId}
  // liveWalkSessions/{requestId}
  // walk_history/{requestId}
  // ============================================================

  bool _isValidRequestId(String requestId) {
    return RegExp(r'^DW\d{6}$').hasMatch(requestId.trim());
  }

  // ============================================================
  // GET LIVE SESSION
  //
  // liveWalkSessions/{requestId}
  // ============================================================

  Future<Map<String, dynamic>?> getSession(
    String requestId,
  ) async {
    final String cleanRequestId = requestId.trim();

    if (cleanRequestId.isEmpty ||
        !_isValidRequestId(cleanRequestId)) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _sessions.doc(cleanRequestId).get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    // ==========================================================
    // VERIFY STORED REQUEST ID
    // ==========================================================

    final String storedRequestId =
        data['requestId']?.toString().trim() ?? '';

    if (storedRequestId.isNotEmpty &&
        storedRequestId != cleanRequestId) {
      return null;
    }

    return data;
  }

  // ============================================================
  // WRITE LIVE LOCATION
  //
  // IMPORTANT:
  //
  // This method ONLY writes live-walk data.
  //
  // It NEVER:
  // - starts GPS
  // - stops GPS
  // - requests permission
  // - changes Walker availability
  //
  // GPS lifecycle is owned by WalkerLocationService /
  // WalkerAvailabilityService.
  //
  // Canonical document:
  //
  // liveWalkSessions/{requestId}
  // ============================================================

  Future<void> writeLocation({
    required String requestId,
    required String sessionId,
    required Position position,
    required List<Map<String, double>> route,
    required double distanceKm,
    required int steps,
    required int peeCount,
    required int poopCount,
    required DateTime? startedAt,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    final String cleanRequestId = requestId.trim();
    final String cleanSessionId = sessionId.trim();

    // ==========================================================
    // VALIDATION
    // ==========================================================

    if (cleanRequestId.isEmpty ||
        !_isValidRequestId(cleanRequestId)) {
      return;
    }

    // Canonical architecture:
    //
    // sessionId == requestId
    //
    if (cleanSessionId.isNotEmpty &&
        cleanSessionId != cleanRequestId) {
      return;
    }

    // ==========================================================
    // VALID COORDINATES
    // ==========================================================

    if (!_validCoordinate(
      position.latitude,
      position.longitude,
    )) {
      return;
    }

    // ==========================================================
    // START LOCATION
    // ==========================================================

    final Map<String, double> startLocation =
        route.isNotEmpty
            ? <String, double>{
                'lat': route.first['lat'] ?? position.latitude,
                'lng': route.first['lng'] ?? position.longitude,
              }
            : <String, double>{
                'lat': position.latitude,
                'lng': position.longitude,
              };

    // ==========================================================
    // SAFE VALUES
    // ==========================================================

    final double safeDistanceKm =
        distanceKm.isFinite && distanceKm >= 0
            ? distanceKm
            : 0.0;

    final int safeSteps = steps < 0 ? 0 : steps;

    final int safePeeCount =
        peeCount < 0 ? 0 : peeCount;

    final int safePoopCount =
        poopCount < 0 ? 0 : poopCount;

    // ==========================================================
    // LOCATION DATA
    //
    // IMPORTANT:
    //
    // Do NOT overwrite status/start flags here.
    //
    // startWalk() controls:
    // status
    // walkStarted
    // trackingStarted
    //
    // completeWalk() controls:
    // completed/ended state
    // ==========================================================

    final Map<String, dynamic> data =
        <String, dynamic>{
      // --------------------------------------------------------
      // WALKER
      // --------------------------------------------------------

      'walkerUid': user.uid,

      // --------------------------------------------------------
      // CANONICAL IDENTIFIERS
      // --------------------------------------------------------

      'requestId': cleanRequestId,
      'sessionId': cleanRequestId,

      // --------------------------------------------------------
      // CURRENT LOCATION
      //
      // These fields are intentionally kept together so that
      // Owner/Admin/Live Map screens can use the same location.
      // --------------------------------------------------------

      'currentLocation': <String, dynamic>{
        'lat': position.latitude,
        'lng': position.longitude,
      },

      'currentLat': position.latitude,
      'currentLng': position.longitude,

      // Explicit walker location compatibility fields.
      //
      // These are important for screens that listen specifically
      // for walkerLatitude / walkerLongitude.
      'walkerLatitude': position.latitude,
      'walkerLongitude': position.longitude,

      // --------------------------------------------------------
      // GPS DETAILS
      // --------------------------------------------------------

      'gpsAccuracy': position.accuracy,
      'gpsHeading': position.heading,
      'gpsSpeed': position.speed,

      'gpsUpdatedAt': FieldValue.serverTimestamp(),

      // --------------------------------------------------------
      // START LOCATION
      // --------------------------------------------------------

      'startLocation': startLocation,

      // --------------------------------------------------------
      // ROUTE
      // --------------------------------------------------------

      'routeCoordinates': route,
      'routePointCount': route.length,

      // --------------------------------------------------------
      // DISTANCE
      // --------------------------------------------------------

      'distanceKm': safeDistanceKm,
      'distanceMeters': safeDistanceKm * 1000.0,

      // --------------------------------------------------------
      // WALK METRICS
      // --------------------------------------------------------

      'steps': safeSteps,
      'peeCount': safePeeCount,
      'poopCount': safePoopCount,

      // --------------------------------------------------------
      // START TIME
      //
      // Do not replace an existing startedAt with null.
      // If supplied, preserve the original walk start time.
      // --------------------------------------------------------

      if (startedAt != null)
        'startedAt': Timestamp.fromDate(startedAt),

      // --------------------------------------------------------
      // UPDATED TIME
      // --------------------------------------------------------

      'updatedAt': FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // WRITE
    //
    // merge:true is essential.
    //
    // It preserves:
    // - owner data
    // - walker name
    // - walker phone
    // - dog data
    // - acceptedAt
    // - reachedAt
    // - other live-session metadata
    // - status controlled by LiveWalkSessionService
    // ==========================================================

    await _sessions.doc(cleanRequestId).set(
      data,
      SetOptions(merge: true),
    );
  }

  // ============================================================
  // COMPLETE WALK
  //
  // Canonical flow:
  //
  // liveWalkSessions/{requestId}
  //          +
  // walk_request/{requestId}
  //
  // Both are committed atomically.
  // ============================================================

  Future<void> completeWalk({
    required String requestId,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw StateError(
        'Walker is not authenticated.',
      );
    }

    final String cleanRequestId = requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw ArgumentError(
        'requestId cannot be empty.',
      );
    }

    if (!_isValidRequestId(cleanRequestId)) {
      throw ArgumentError(
        'Invalid requestId: $cleanRequestId',
      );
    }

    // ==========================================================
    // VERIFY LIVE SESSION
    // ==========================================================

    final DocumentReference<Map<String, dynamic>> sessionRef =
        _sessions.doc(cleanRequestId);

    final DocumentSnapshot<Map<String, dynamic>> sessionSnapshot =
        await sessionRef.get();

    if (!sessionSnapshot.exists) {
      throw StateError(
        'Live walk session not found: $cleanRequestId',
      );
    }

    final Map<String, dynamic> sessionData =
        sessionSnapshot.data() ?? <String, dynamic>{};

    // ==========================================================
    // VERIFY WALKER OWNERSHIP
    // ==========================================================

    final String sessionWalkerUid =
        sessionData['walkerUid']?.toString().trim() ?? '';

    if (sessionWalkerUid.isNotEmpty &&
        sessionWalkerUid != user.uid) {
      throw StateError(
        'This live walk belongs to another walker.',
      );
    }

    // ==========================================================
    // VERIFY REQUEST ID
    // ==========================================================

    final String storedRequestId =
        sessionData['requestId']?.toString().trim() ?? '';

    if (storedRequestId.isNotEmpty &&
        storedRequestId != cleanRequestId) {
      throw StateError(
        'Live session requestId does not match.',
      );
    }

    // ==========================================================
    // WALK REQUEST REFERENCE
    // ==========================================================

    final DocumentReference<Map<String, dynamic>> requestRef =
        _walkRequests.doc(cleanRequestId);

    final DocumentSnapshot<Map<String, dynamic>> requestSnapshot =
        await requestRef.get();

    if (!requestSnapshot.exists) {
      throw StateError(
        'Walk request not found: $cleanRequestId',
      );
    }

    final Map<String, dynamic> requestData =
        requestSnapshot.data() ?? <String, dynamic>{};

    final String requestWalkerUid =
        requestData['walkerUid']?.toString().trim() ?? '';

    if (requestWalkerUid.isNotEmpty &&
        requestWalkerUid != user.uid) {
      throw StateError(
        'This walk request belongs to another walker.',
      );
    }

    // ==========================================================
    // ATOMIC BATCH
    // ==========================================================

    final WriteBatch batch = _firestore.batch();

    // ==========================================================
    // LIVE SESSION
    // ==========================================================

    batch.set(
      sessionRef,
      <String, dynamic>{
        'requestId': cleanRequestId,
        'sessionId': cleanRequestId,

        'walkerUid': user.uid,

        'status': 'completed',

        'walkEnded': true,
        'trackingEnded': true,

        'completedAt': FieldValue.serverTimestamp(),
        'endedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    // ==========================================================
    // WALK REQUEST
    // ==========================================================

    batch.update(
      requestRef,
      <String, dynamic>{
        'status': 'completed',

        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );

    // ==========================================================
    // COMMIT
    // ==========================================================

    await batch.commit();
  }

  // ============================================================
  // COORDINATE VALIDATION
  // ============================================================

  bool _validCoordinate(
    double lat,
    double lng,
  ) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }
}
