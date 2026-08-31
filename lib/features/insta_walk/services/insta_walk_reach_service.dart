import 'package:cloud_firestore/cloud_firestore.dart';

class InstaWalkReachService {
  InstaWalkReachService._();

  static final InstaWalkReachService instance =
      InstaWalkReachService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// Marks the walker as reached and creates a new
  /// liveWalkSessions document.
  ///
  /// IMPORTANT:
  /// After this point, the actual walk data belongs to
  /// liveWalkSessions, not walk_request.
  Future<String> createLiveWalkSession({
    required String walkRequestId,
    required String walkerUid,
    required String walkerId,
    String? walkerName,
    String? walkerPhone,
  }) async {
    if (walkRequestId.trim().isEmpty) {
      throw Exception('Walk request ID is missing.');
    }

    if (walkerUid.trim().isEmpty) {
      throw Exception('Walker UID is missing.');
    }

    if (walkerId.trim().isEmpty) {
      throw Exception('Walker ID is missing.');
    }

    final DocumentReference<Map<String, dynamic>> requestRef =
        _firestore
            .collection('walk_request')
            .doc(walkRequestId.trim());

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

    final String existingWalkerUid =
        requestData['walkerUid']?.toString().trim() ?? '';

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid != walkerUid.trim()) {
      throw Exception(
        'This walk is assigned to another Walker.',
      );
    }

    final String status =
        requestData['status']?.toString().trim().toLowerCase() ?? '';

    if (status != 'accepted') {
      throw Exception(
        'This walk is not in accepted status.',
      );
    }

    final Timestamp now =
        Timestamp.now();

    final DocumentReference<Map<String, dynamic>> sessionRef =
        _firestore
            .collection('liveWalkSessions')
            .doc();

    final Map<String, dynamic> sessionData =
        <String, dynamic>{
      // ----------------------------------------------------------
      // SESSION
      // ----------------------------------------------------------

      'sessionId': sessionRef.id,
      'walkId': walkRequestId.trim(),

      // ----------------------------------------------------------
      // OWNER
      // ----------------------------------------------------------

      'ownerId':
          requestData['ownerId']?.toString() ?? '',

      'ownerName':
          requestData['ownerName']?.toString() ?? '',

      'ownerPhone':
          requestData['ownerPhone']?.toString() ?? '',

      'ownerUid':
          requestData['ownerAuthUid']?.toString().trim().isNotEmpty ==
                  true
              ? requestData['ownerAuthUid']
              : requestData['ownerUid'],

      'ownerAuthUid':
          requestData['ownerAuthUid']?.toString() ?? '',

      // ----------------------------------------------------------
      // WALKER
      // ----------------------------------------------------------

      'walkerId': walkerId.trim(),

      'walkerUid': walkerUid.trim(),

      'walkerName':
          walkerName?.trim().isNotEmpty == true
              ? walkerName!.trim()
              : requestData['walkerName']?.toString() ?? '',

      'walkerPhone':
          walkerPhone?.trim().isNotEmpty == true
              ? walkerPhone!.trim()
              : requestData['walkerPhone']?.toString() ?? '',

      // ----------------------------------------------------------
      // DOG
      // ----------------------------------------------------------

      'dogName':
          requestData['dogName']?.toString() ?? '',

      'dogBreed':
          requestData['dogBreed']?.toString() ?? '',

      // ----------------------------------------------------------
      // LOCATION
      // ----------------------------------------------------------

      'address':
          requestData['address']?.toString() ?? '',

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

      'reachedAt':
          now,

      'arrivalDistanceKm':
          _toDouble(
        requestData['arrivalDistanceKm'],
      ),

      'arrivalDistanceMeters':
          _toInt(
        requestData['arrivalDistanceMeters'],
      ),

      'arrivalDurationMinutes':
          _toInt(
        requestData['arrivalDurationMinutes'],
      ),

      // ----------------------------------------------------------
      // WALK STATE
      // ----------------------------------------------------------

      'status': 'ready',

      'walkStarted': false,

      'walkEnded': false,

      'trackingStarted': false,

      'trackingEnded': false,

      'startedAt': null,

      'endedAt': null,

      'completedAt': null,

      // ----------------------------------------------------------
      // LIVE WALK DATA
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

      'routeCoordinates':
          <dynamic>[],

      'events':
          <dynamic>[],

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

    final WriteBatch batch =
        _firestore.batch();

    // Create Live Walk Session.
    batch.set(
      sessionRef,
      sessionData,
    );

    // Update ONLY arrival/reach information in walk_request.
    //
    // No live walk tracking data is written here.
    batch.update(
      requestRef,
      <String, dynamic>{
        'reached': true,
        'reachedAt': now,

        'arrivalDistanceKm':
            _toDouble(
          requestData['arrivalDistanceKm'],
        ),

        'arrivalDistanceMeters':
            _toInt(
          requestData['arrivalDistanceMeters'],
        ),

        'arrivalDurationMinutes':
            _toInt(
          requestData['arrivalDurationMinutes'],
        ),

        'updatedAt': now,
      },
    );

    await batch.commit();

    return sessionRef.id;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  double _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }

    return 0.0;
  }

  int _toInt(
    dynamic value,
  ) {
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
