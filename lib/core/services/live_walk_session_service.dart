import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LiveWalkSessionService {
  LiveWalkSessionService._();

  static final LiveWalkSessionService instance =
      LiveWalkSessionService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _sessions {
    return _firestore.collection(
      'liveWalkSessions',
    );
  }

  CollectionReference<Map<String, dynamic>> get _history {
    return _firestore.collection(
      'walk_history',
    );
  }

  // ============================================================
  // AUTH
  // ============================================================

  String get _currentAuthUid {
    final User? user = _auth.currentUser;

    final String uid = user?.uid.trim() ?? '';

    if (uid.isEmpty) {
      throw Exception(
        'Walker authentication is missing. '
        'Please login again.',
      );
    }

    return uid;
  }

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

  bool _isValidRequestId(String requestId) {
    return RegExp(r'^DW\d{6}$').hasMatch(
      requestId.trim(),
    );
  }

  String _cleanRequestId(String requestId) {
    final String cleanRequestId =
        requestId.trim();

    if (cleanRequestId.isEmpty) {
      throw Exception(
        'Request ID is missing.',
      );
    }

    if (!_isValidRequestId(cleanRequestId)) {
      throw Exception(
        'Invalid Request ID. '
        'Expected format: DW000001.',
      );
    }

    return cleanRequestId;
  }

  // ============================================================
  // SESSION REFERENCE
  //
  // ONE WALK = ONE SESSION
  //
  // liveWalkSessions/{requestId}
  //
  // Example:
  // liveWalkSessions/DW000001
  // ============================================================

  DocumentReference<Map<String, dynamic>> sessionRef(
    String requestId,
  ) {
    final String cleanRequestId =
        _cleanRequestId(requestId);

    return _sessions.doc(
      cleanRequestId,
    );
  }

  // ============================================================
  // GET SESSION
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>> getSession(
    String requestId,
  ) async {
    return sessionRef(requestId).get();
  }

  // ============================================================
  // START WALK
  //
  // Canonical ID:
  //
  // requestId
  //
  // Firestore:
  //
  // liveWalkSessions/{requestId}
  //
  // sessionId = requestId
  //
  // No separate walkId.
  // ============================================================

  Future<void> startWalk({
    required String requestId,
    required String ownerUid,
    required String ownerName,
    required String dogName,
    String dogBreed = '',
    String walkerUid = '',
    String walkerId = '',
    String walkerName = '',
    String walkerPhone = '',
  }) async {
    final String cleanRequestId =
        _cleanRequestId(requestId);

    final String authUid =
        _currentAuthUid;

    final String cleanWalkerUid =
        walkerUid.trim().isNotEmpty
            ? walkerUid.trim()
            : authUid;

    if (cleanWalkerUid != authUid) {
      throw Exception(
        'Walker authentication mismatch.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        session =
        sessionRef(cleanRequestId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await session.get();

    // ==========================================================
    // SESSION MUST EXIST
    // ==========================================================

    if (!snapshot.exists) {
      throw Exception(
        'Live walk session was not found. '
        'Please accept the walk again.',
      );
    }

    final Map<String, dynamic> existing =
        snapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // VERIFY WALKER
    // ==========================================================

    final String existingWalkerUid =
        existing['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (existingWalkerUid.isNotEmpty &&
        existingWalkerUid != authUid) {
      throw Exception(
        'You are not authorized to start this walk.',
      );
    }

    // ==========================================================
    // VERIFY REQUEST ID
    //
    // Firestore document ID is authoritative.
    // ==========================================================

    final String existingRequestId =
        existing['requestId']
                ?.toString()
                .trim() ??
            '';

    if (existingRequestId.isNotEmpty &&
        existingRequestId != cleanRequestId) {
      throw Exception(
        'Request ID does not match the live session.',
      );
    }

    // ==========================================================
    // STATUS
    // ==========================================================

    final String currentStatus =
        existing['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (currentStatus == 'completed' ||
        currentStatus == 'ended') {
      throw Exception(
        'This walk has already been completed.',
      );
    }

    if (currentStatus == 'active' ||
        currentStatus == 'started' ||
        currentStatus == 'live') {
      return;
    }

    // ==========================================================
    // START
    // ==========================================================

    final Map<String, dynamic> sessionData =
        <String, dynamic>{
      // --------------------------------------------------------
      // IDENTIFIERS
      // --------------------------------------------------------

      'requestId':
          cleanRequestId,

      'sessionId':
          cleanRequestId,

      // --------------------------------------------------------
      // OWNER
      // --------------------------------------------------------

      'ownerUid':
          ownerUid.trim(),

      'ownerName':
          ownerName.trim(),

      // --------------------------------------------------------
      // DOG
      // --------------------------------------------------------

      'dogName':
          dogName.trim(),

      'dogBreed':
          dogBreed.trim(),

      // --------------------------------------------------------
      // WALKER
      // --------------------------------------------------------

      'walkerUid':
          cleanWalkerUid,

      'walkerId':
          walkerId.trim(),

      'walkerName':
          walkerName.trim(),

      'walkerPhone':
          walkerPhone.trim(),

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

      // --------------------------------------------------------
      // TIME
      // --------------------------------------------------------

      'startedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      // --------------------------------------------------------
      // STATS
      // --------------------------------------------------------

      'distanceKm':
          existing['distanceKm'] ?? 0.0,

      'distanceMeters':
          existing['distanceMeters'] ?? 0.0,

      'durationSeconds':
          existing['durationSeconds'] ?? 0,

      'steps':
          existing['steps'] ?? 0,

      'peeCount':
          existing['peeCount'] ?? 0,

      'poopCount':
          existing['poopCount'] ?? 0,

      // --------------------------------------------------------
      // ROUTE
      // --------------------------------------------------------

      'routeCoordinates':
          existing['routeCoordinates'] ??
              <dynamic>[],

      // --------------------------------------------------------
      // LOCATION
      // --------------------------------------------------------

      if (existing['currentLocation'] != null)
        'currentLocation':
            existing['currentLocation'],

      if (existing['currentLat'] != null)
        'currentLat':
            existing['currentLat'],

      if (existing['currentLng'] != null)
        'currentLng':
            existing['currentLng'],

      // --------------------------------------------------------
      // EVENTS
      // --------------------------------------------------------

      'events':
          existing['events'] ??
              <dynamic>[],
    };

    // ==========================================================
    // WRITE TO CANONICAL DOCUMENT
    //
    // liveWalkSessions/{requestId}
    // ==========================================================

    await session.set(
      sessionData,
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // COMPLETE WALK + SAVE HISTORY
  //
  // SAME REQUEST ID:
  //
  // liveWalkSessions/{requestId}
  // walk_history/{requestId}
  // ============================================================

  Future<void> completeWalk({
    required String requestId,
  }) async {
    final String cleanRequestId =
        _cleanRequestId(requestId);

    final String authUid =
        _currentAuthUid;

    final DocumentReference<Map<String, dynamic>>
        session =
        sessionRef(cleanRequestId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await session.get();

    if (!snapshot.exists) {
      throw Exception(
        'Live walk session was not found.',
      );
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // REQUEST ID
    //
    // Document ID is authoritative.
    // ==========================================================

    final String sessionRequestId =
        data['requestId']
                ?.toString()
                .trim() ??
            '';

    if (sessionRequestId.isNotEmpty &&
        sessionRequestId != cleanRequestId) {
      throw Exception(
        'Request ID does not match the live session.',
      );
    }

    // ==========================================================
    // WALKER
    // ==========================================================

    final String sessionWalkerUid =
        data['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (sessionWalkerUid.isEmpty) {
      throw Exception(
        'Walker information is missing from the live session.',
      );
    }

    if (sessionWalkerUid != authUid) {
      throw Exception(
        'You are not authorized to complete this walk.',
      );
    }

    // ==========================================================
    // STATUS
    // ==========================================================

    final String status =
        data['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    // ==========================================================
    // ALREADY COMPLETED
    // ==========================================================

    if (status == 'completed' ||
        status == 'ended') {
      await _ensureHistoryExists(
        requestId:
            cleanRequestId,
        sessionData:
            data,
        authUid:
            authUid,
      );

      return;
    }

    if (status != 'active' &&
        status != 'started' &&
        status != 'live') {
      throw Exception(
        'This live walk is not active.',
      );
    }

    // ==========================================================
    // COMPLETION TIMESTAMP
    // ==========================================================

    final Timestamp completedTime =
        Timestamp.now();

    // ==========================================================
    // FINAL SESSION DATA
    // ==========================================================

    final Map<String, dynamic>
        completedSessionData =
        Map<String, dynamic>.from(
      data,
    );

    completedSessionData.addAll(
      <String, dynamic>{
        'requestId':
            cleanRequestId,

        'sessionId':
            cleanRequestId,

        'status':
            'completed',

        'walkStarted':
            false,

        'walkEnded':
            true,

        'trackingEnded':
            true,

        'completedAt':
            completedTime,

        'endedAt':
            completedTime,

        'updatedAt':
            completedTime,
      },
    );

    // ==========================================================
    // ATOMIC SAVE
    //
    // liveWalkSessions/{requestId}
    // walk_history/{requestId}
    // ==========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ----------------------------------------------------------
    // LIVE SESSION
    // ----------------------------------------------------------

    batch.set(
      session,
      <String, dynamic>{
        'requestId':
            cleanRequestId,

        'sessionId':
            cleanRequestId,

        'status':
            'completed',

        'walkStarted':
            false,

        'walkEnded':
            true,

        'trackingEnded':
            true,

        'completedAt':
            completedTime,

        'endedAt':
            completedTime,

        'updatedAt':
            completedTime,
      },
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // HISTORY
    //
    // Document ID = Request ID.
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>>
        historyRef =
        _history.doc(cleanRequestId);

    batch.set(
      historyRef,
      _buildHistoryData(
        sessionData:
            completedSessionData,
        requestId:
            cleanRequestId,
        authUid:
            authUid,
        completedAt:
            completedTime,
      ),
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // COMMIT
    // ----------------------------------------------------------

    await batch.commit();
  }

  // ============================================================
  // ENSURE HISTORY EXISTS
  //
  // Used when completeWalk() is called again after the session
  // has already been completed.
  //
  // Document ID = requestId.
  // ============================================================

  Future<void> _ensureHistoryExists({
    required String requestId,
    required Map<String, dynamic> sessionData,
    required String authUid,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        historyRef =
        _history.doc(requestId);

    final DocumentSnapshot<Map<String, dynamic>>
        historySnapshot =
        await historyRef.get();

    if (historySnapshot.exists) {
      return;
    }

    final dynamic existingCompletedAt =
        sessionData['completedAt'];

    final Timestamp completedAt =
        existingCompletedAt is Timestamp
            ? existingCompletedAt
            : Timestamp.now();

    await historyRef.set(
      _buildHistoryData(
        sessionData:
            sessionData,
        requestId:
            requestId,
        authUid:
            authUid,
        completedAt:
            completedAt,
      ),
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // BUILD HISTORY DATA
  //
  // Existing live session fields are preserved.
  // ============================================================

  Map<String, dynamic> _buildHistoryData({
    required Map<String, dynamic> sessionData,
    required String requestId,
    required String authUid,
    required Timestamp completedAt,
  }) {
    final Map<String, dynamic> history =
        Map<String, dynamic>.from(
      sessionData,
    );

    history.addAll(
      <String, dynamic>{
        // ------------------------------------------------------
        // IDENTIFIERS
        // ------------------------------------------------------

        'requestId':
            requestId,

        'sessionId':
            requestId,

        'walkerUid':
            sessionData['walkerUid'] ??
                authUid,

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        'status':
            'completed',

        'walkStarted':
            false,

        'walkEnded':
            true,

        'trackingEnded':
            true,

        'completed':
            true,

        // ------------------------------------------------------
        // COMPLETION TIME
        // ------------------------------------------------------

        'completedAt':
            completedAt,

        'endedAt':
            sessionData['endedAt'] ??
                completedAt,

        'updatedAt':
            completedAt,

        // ------------------------------------------------------
        // HISTORY SOURCE
        // ------------------------------------------------------

        'source':
            sessionData['source'] ??
                'live_walk',

        'historyCreatedAt':
            sessionData['historyCreatedAt'] ??
                completedAt,

        'historyUpdatedAt':
            completedAt,
      },
    );

    // ==========================================================
    // CANONICAL WALKER IMAGE FALLBACK
    // ==========================================================

    final String walkerImage =
        _firstString(
      <dynamic>[
        sessionData['walkerProfileImage'],
        sessionData['profileImageUrl'],
        sessionData['profileImage'],
        sessionData['photoUrl'],
        sessionData['photoURL'],
        sessionData['profilePhoto'],
        sessionData['profilePhotoUrl'],
        sessionData['selfie'],
        sessionData['selfieUrl'],
        sessionData['imageUrl'],
        sessionData['image'],
      ],
    );

    if (walkerImage.isNotEmpty) {
      history['walkerProfileImage'] =
          walkerImage;
    }

    // ==========================================================
    // CANONICAL WALKER NAME
    // ==========================================================

    final String walkerName =
        _firstString(
      <dynamic>[
        sessionData['walkerName'],
        sessionData['fullName'],
        sessionData['Walker Name'],
      ],
    );

    if (walkerName.isNotEmpty) {
      history['walkerName'] =
          walkerName;
    }

    // ==========================================================
    // CANONICAL WALKER PHONE
    // ==========================================================

    final String walkerPhone =
        _firstString(
      <dynamic>[
        sessionData['walkerPhone'],
        sessionData['phone'],
        sessionData['phoneNumber'],
        sessionData['mobileNumber'],
        sessionData['Mobile number'],
      ],
    );

    if (walkerPhone.isNotEmpty) {
      history['walkerPhone'] =
          walkerPhone;
    }

    // ==========================================================
    // DISTANCE
    // ==========================================================

    if (!history.containsKey('distanceKm')) {
      history['distanceKm'] =
          0.0;
    }

    if (!history.containsKey('distanceMeters')) {
      final dynamic distance =
          history['distanceKm'];

      if (distance is num) {
        history['distanceMeters'] =
            distance.toDouble() * 1000.0;
      } else {
        history['distanceMeters'] =
            0.0;
      }
    }

    // ==========================================================
    // STEPS
    // ==========================================================

    if (!history.containsKey('steps')) {
      history['steps'] =
          0;
    }

    // ==========================================================
    // ACTIVITIES
    // ==========================================================

    if (!history.containsKey('peeCount')) {
      history['peeCount'] =
          0;
    }

    if (!history.containsKey('poopCount')) {
      history['poopCount'] =
          0;
    }

    // ==========================================================
    // ROUTE
    // ==========================================================

    if (!history.containsKey('routeCoordinates')) {
      history['routeCoordinates'] =
          <dynamic>[];
    }

    if (!history.containsKey('routePointCount')) {
      final dynamic route =
          history['routeCoordinates'];

      history['routePointCount'] =
          route is List
              ? route.length
              : 0;
    }

    return history;
  }

  // ============================================================
  // STRING FALLBACK
  // ============================================================

  String _firstString(
    List<dynamic> values,
  ) {
    for (final dynamic value in values) {
      final String text =
          value?.toString().trim() ?? '';

      if (text.isNotEmpty &&
          text.toLowerCase() != 'null') {
        return text;
      }
    }

    return '';
  }
}
