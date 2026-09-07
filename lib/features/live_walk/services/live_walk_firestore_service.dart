import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class LiveWalkFirestoreService {
  LiveWalkFirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth =
            auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>>
      get _sessions =>
          _firestore.collection(
            'liveWalkSessions',
          );

  // ============================================================
  // REQUEST ID VALIDATION
  //
  // Canonical ID:
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

  bool _isValidRequestId(
    String requestId,
  ) {
    return RegExp(
      r'^DW\d{6}$',
    ).hasMatch(
      requestId.trim(),
    );
  }

  // ============================================================
  // GET SESSION
  //
  // One Walk = One Live Session.
  //
  // Firestore:
  //
  // liveWalkSessions/{requestId}
  //
  // Example:
  // liveWalkSessions/DW000001
  // ============================================================

  Future<Map<String, dynamic>?> getSession(
    String requestId,
  ) async {
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      return null;
    }

    if (!_isValidRequestId(
      cleanRequestId,
    )) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await _sessions
            .doc(cleanRequestId)
            .get();

    if (!snapshot.exists) {
      return null;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // VERIFY REQUEST ID
    //
    // Document ID is authoritative.
    // ==========================================================

    final String storedRequestId =
        data['requestId']
                ?.toString()
                .trim() ??
            '';

    if (storedRequestId.isNotEmpty &&
        storedRequestId != cleanRequestId) {
      return null;
    }

    return data;
  }

  // ============================================================
  // WRITE LOCATION
  //
  // Canonical ID:
  //
  // requestId
  //
  // sessionId = requestId
  //
  // No separate walkId.
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
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      return;
    }

    if (!_isValidRequestId(
      cleanRequestId,
    )) {
      return;
    }

    final Map<String, double>
        startLocation =
        route.isNotEmpty
            ? route.first
            : <String, double>{
                'lat':
                    position.latitude,
                'lng':
                    position.longitude,
              };

    final Map<String, dynamic> data =
        <String, dynamic>{
      // --------------------------------------------------------
      // WALKER
      // --------------------------------------------------------

      'walkerUid':
          user.uid,

      // --------------------------------------------------------
      // IDENTIFIERS
      //
      // One Walk = One Session.
      // requestId is the canonical ID.
      // --------------------------------------------------------

      'requestId':
          cleanRequestId,

      'sessionId':
          cleanRequestId,

      // --------------------------------------------------------
      // CURRENT LOCATION
      // --------------------------------------------------------

      'currentLocation':
          <String, dynamic>{
        'lat':
            position.latitude,
        'lng':
            position.longitude,
      },

      'currentLat':
          position.latitude,

      'currentLng':
          position.longitude,

      // --------------------------------------------------------
      // START LOCATION / ROUTE
      // --------------------------------------------------------

      'startLocation':
          startLocation,

      'routeCoordinates':
          route,

      'routePointCount':
          route.length,

      // --------------------------------------------------------
      // DISTANCE
      // --------------------------------------------------------

      'distanceKm':
          distanceKm,

      'distanceMeters':
          distanceKm * 1000.0,

      // --------------------------------------------------------
      // STATS
      // --------------------------------------------------------

      'steps':
          steps,

      'peeCount':
          peeCount,

      'poopCount':
          poopCount,

      // --------------------------------------------------------
      // TIME
      // --------------------------------------------------------

      'startedAt':
          startedAt == null
              ? FieldValue
                  .serverTimestamp()
              : Timestamp.fromDate(
                  startedAt,
                ),

      // --------------------------------------------------------
      // GPS
      // --------------------------------------------------------

      'gpsAccuracy':
          position.accuracy,

      'gpsHeading':
          position.heading,

      'gpsSpeed':
          position.speed,

      'gpsUpdatedAt':
          FieldValue
              .serverTimestamp(),

      'updatedAt':
          FieldValue
              .serverTimestamp(),

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      'status':
          'active',

      'walkStarted':
          true,

      'walkEnded':
          false,

      'trackingStarted':
          true,

      'trackingEnded':
          false,
    };

    // ==========================================================
    // WRITE TO CANONICAL DOCUMENT
    //
    // IMPORTANT:
    // Firestore document ID = requestId.
    //
    // Example:
    // liveWalkSessions/DW000001
    // ==========================================================

    await _sessions
        .doc(cleanRequestId)
        .set(
          data,
          SetOptions(
            merge: true,
          ),
        );
  }
}
