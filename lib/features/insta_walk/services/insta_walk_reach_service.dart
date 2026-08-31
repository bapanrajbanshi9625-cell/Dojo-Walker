import 'package:cloud_firestore/cloud_firestore.dart';

class InstaWalkReachService {
  InstaWalkReachService._();

  static final InstaWalkReachService instance =
      InstaWalkReachService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Marks the Walker as reached and creates a NEW
  /// liveWalkSessions document.
  ///
  /// IMPORTANT:
  /// - walk_request remains the request/arrival source.
  /// - liveWalkSessions is the source of truth for Live Walk.
  /// - Every new walk gets a new liveWalkSessions document.
  Future<String> createLiveWalkSession({
    required String walkRequestId,
    required String walkerUid,
    required String walkerId,
    String? walkerName,
    String? walkerPhone,
  }) async {
    final String requestId = walkRequestId.trim();
    final String uid = walkerUid.trim();
    final String id = walkerId.trim();

    if (requestId.isEmpty) {
      throw Exception('Walk request ID is missing.');
    }

    if (uid.isEmpty) {
      throw Exception('Walker UID is missing.');
    }

    if (id.isEmpty) {
      throw Exception('Walker ID is missing.');
    }

    // ------------------------------------------------------------
    // WALK REQUEST
    // ------------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> requestRef =
        _firestore.collection('walk_request').doc(requestId);

    final DocumentSnapshot<Map<String, dynamic>> requestSnapshot =
        await requestRef.get();

    if (!requestSnapshot.exists) {
      throw Exception('Walk request not found.');
    }

    final Map<String, dynamic>? requestData =
        requestSnapshot.data();

    if (requestData == null) {
      throw Exception('Walk request data is unavailable.');
    }

    // ------------------------------------------------------------
    // REQUEST STATUS
    // ------------------------------------------------------------

    final String status =
        requestData['status']?.toString().trim().toLowerCase() ?? '';

    if (status != 'accepted') {
      throw Exception(
        'This walk is not in accepted status.',
      );
    }

    // ------------------------------------------------------------
    // VERIFY ASSIGNED WALKER
    // ------------------------------------------------------------

    final String existingWalkerUid =
        requestData['walkerUid']?.toString().trim() ?? '';

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid != uid) {
      throw Exception(
        'This walk is assigned to another Walker.',
      );
    }

    // ------------------------------------------------------------
    // ACTUAL WALK ID
    // ------------------------------------------------------------
    //
    // IMPORTANT:
    // Do NOT use walkRequestId as walkId.
    //
    // Example:
    //
    // walk_request document ID:
    // abc123
    //
    // walkId:
    // walk_1788043358246
    //
    // These can be different.
    // ------------------------------------------------------------

    final String walkId =
        requestData['walkId']?.toString().trim() ?? '';

    if (walkId.isEmpty) {
      throw Exception(
        'Walk ID is missing from the accepted walk request.',
      );
    }

    // ------------------------------------------------------------
    // OWNER DATA
    // ------------------------------------------------------------

    final String ownerId =
        requestData['ownerId']?.toString().trim() ?? '';

    final String ownerName =
        requestData['ownerName']?.toString().trim() ?? '';

    // EXACT FIELD: ownerPhone
    final String ownerPhone =
        requestData['ownerPhone']?.toString().trim() ?? '';

    final String ownerUid =
        requestData['ownerAuthUid']?.toString().trim().isNotEmpty == true
            ? requestData['ownerAuthUid'].toString().trim()
            : requestData['ownerUid']?.toString().trim() ?? '';

    final String ownerAuthUid =
        requestData['ownerAuthUid']?.toString().trim() ?? '';

    // ------------------------------------------------------------
    // WALKER DATA
    // ------------------------------------------------------------

    final String finalWalkerName =
        walkerName?.trim().isNotEmpty == true
            ? walkerName!.trim()
            : requestData['walkerName']?.toString().trim() ?? '';

    final String finalWalkerPhone =
        walkerPhone?.trim().isNotEmpty == true
            ? walkerPhone!.trim()
            : requestData['walkerPhone']?.toString().trim() ?? '';

    // ------------------------------------------------------------
    // TIME
    // ------------------------------------------------------------

    final Timestamp now = Timestamp.now();

    // ------------------------------------------------------------
    // CREATE A COMPLETELY NEW SESSION
    // ------------------------------------------------------------

    final DocumentReference<Map<String, dynamic>> sessionRef =
        _firestore.collection('liveWalkSessions').doc();

    final Map<String, dynamic> sessionData =
        <String, dynamic>{
      // ----------------------------------------------------------
      // SESSION
      // ----------------------------------------------------------

      'sessionId': sessionRef.id,

      // ACTUAL WALK ID
      'walkId': walkId,

      // ORIGINAL REQUEST DOCUMENT ID
      'walkRequestId': requestId,

      // ----------------------------------------------------------
      // OWNER
      // ----------------------------------------------------------

      'ownerId': ownerId,

      'ownerName': ownerName,

      // EXACT FIRESTORE FIELD
      'ownerPhone': ownerPhone,

      'ownerUid': ownerUid,

      'ownerAuthUid': ownerAuthUid,

      // ----------------------------------------------------------
      // WALKER
      // ----------------------------------------------------------

      'walkerId': id,

      'walkerUid': uid,

      'walkerName': finalWalkerName,

      'walkerPhone': finalWalkerPhone,

      // ----------------------------------------------------------
      // DOG
      // ----------------------------------------------------------

      'dogName':
          requestData['dogName']?.toString().trim() ?? '',

      'dogBreed':
          requestData['dogBreed']?.toString().trim() ?? '',

      // ----------------------------------------------------------
      // ADDRESS
      // ----------------------------------------------------------

      'address':
          requestData['address']?.toString().trim() ?? '',

      'ownerLocation':
          requestData['ownerLocation'],

      'ownerLocationType':
          requestData['ownerLocationType']?.toString() ??
              'search_snapshot',

      // ----------------------------------------------------------
      // ACCEPT / ARRIVAL
      // ----------------------------------------------------------

      'acceptedAt':
          requestData['acceptedAt'] ?? now,

      'reachedAt': now,

      'arrivalDistanceKm': _toDouble(
        requestData['arrivalDistanceKm'],
      ),

      'arrivalDistanceMeters': _toInt(
        requestData['arrivalDistanceMeters'],
      ),

      'arrivalDurationMinutes': _toInt(
        requestData['arrivalDurationMinutes'],
      ),

      // ----------------------------------------------------------
      // LIVE WALK STATE
      // ----------------------------------------------------------

      // IMPORTANT:
      // Walker has reached owner.
      // Walk has NOT started yet.
      'status': 'ready',

      'walkStarted': false,

      'walkEnded': false,

      'trackingStarted': false,

      'trackingEnded': false,

      'startedAt': null,

      'endedAt': null,

      'completedAt': null,

      // ----------------------------------------------------------
      // LIVE LOCATION
      // ----------------------------------------------------------

      'currentLocation': <String, dynamic>{
        'lat': 0.0,
        'lng': 0.0,
      },

      'distanceKm': 0.0,

      'elapsedSeconds': 0,

      'steps': 0,

      'peeCount': 0,

      'poopCount': 0,

      'routeCoordinates': <dynamic>[],

      'events': <dynamic>[],

      // ----------------------------------------------------------
      // SOURCE
      // ----------------------------------------------------------

      'source': 'insta_walk',

      'startedFromQr': false,

      // ----------------------------------------------------------
      // TIMESTAMPS
      // ----------------------------------------------------------

      'createdAt': now,

      'updatedAt': now,
    };

    // ------------------------------------------------------------
    // ATOMIC BATCH
    // ------------------------------------------------------------

    final WriteBatch batch = _firestore.batch();

    // Create NEW Live Walk Session.
    batch.set(
      sessionRef,
      sessionData,
    );

    // Update ONLY arrival information in walk_request.
    //
    // Do not store live GPS tracking here.
    batch.update(
      requestRef,
      <String, dynamic>{
        'reached': true,

        'reachedAt': now,

        'arrivalDistanceKm': _toDouble(
          requestData['arrivalDistanceKm'],
        ),

        'arrivalDistanceMeters': _toInt(
          requestData['arrivalDistanceMeters'],
        ),

        'arrivalDurationMinutes': _toInt(
          requestData['arrivalDurationMinutes'],
        ),

        'updatedAt': now,
      },
    );

    // Commit both operations atomically.
    await batch.commit();

    // Return the NEW liveWalkSessions document ID.
    return sessionRef.id;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value) ?? 0;
    }

    return 0;
  }
}
