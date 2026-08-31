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
  // LIVE SESSION COLLECTION
  //
  // ONLY liveWalkSessions is used by this service.
  //
  // walk_requests is the original request.
  // liveWalkSessions is the actual running/completed walk.
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _sessions {
    return _firestore.collection('liveWalkSessions');
  }

  // ============================================================
  // CURRENT AUTH UID
  // ============================================================

  String get _currentAuthUid {
    final User? user = _auth.currentUser;

    final String uid =
        user?.uid.trim() ?? '';

    if (uid.isEmpty) {
      throw Exception(
        'Walker authentication is missing. Please login again.',
      );
    }

    return uid;
  }

  // ============================================================
  // SESSION REFERENCE
  //
  // liveWalkSessions/{sessionId}
  // ============================================================

  DocumentReference<Map<String, dynamic>> sessionRef(
    String sessionId,
  ) {
    final String cleanId =
        sessionId.trim();

    if (cleanId.isEmpty) {
      throw Exception(
        'Live walk session ID is missing.',
      );
    }

    return _sessions.doc(cleanId);
  }

  // ============================================================
  // GET LIVE SESSION
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getSession(
    String sessionId,
  ) async {
    final DocumentReference<Map<String, dynamic>>
        reference =
        sessionRef(sessionId);

    return reference.get();
  }

  // ============================================================
  // START WALK
  //
  // IMPORTANT:
  //
  // sessionId = REAL liveWalkSessions document ID
  //
  // walkId = walk_requests document ID
  //
  // Example:
  //
  // walkId:
  // 2GN4eWEi6XISWOqURYrF
  //
  // session:
  // liveWalkSessions/{REAL_SESSION_ID}
  //
  // This method NEVER writes to walk_requests.
  // This method NEVER writes to active_walks.
  // ============================================================

  Future<void> startWalk({
    required String sessionId,
    required String walkId,
    required String ownerUid,
    required String ownerName,
    required String dogName,
    String dogBreed = '',
    String walkerUid = '',
    String walkerId = '',
    String walkerName = '',
    String walkerPhone = '',
  }) async {
    final String cleanSessionId =
        sessionId.trim();

    final String cleanWalkId =
        walkId.trim();

    if (cleanSessionId.isEmpty) {
      throw Exception(
        'Live walk session ID is missing.',
      );
    }

    if (cleanWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

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
        sessionRef(cleanSessionId);

    // ==========================================================
    // SESSION MUST ALREADY EXIST
    //
    // It should have been created after request acceptance.
    // We do NOT create a new session here.
    // ==========================================================

    final DocumentSnapshot<Map<String, dynamic>>
        sessionSnapshot =
        await session.get();

    if (!sessionSnapshot.exists) {
      throw Exception(
        'Live walk session was not found. '
        'Please accept the walk again.',
      );
    }

    final Map<String, dynamic> existing =
        sessionSnapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // SECURITY / OWNERSHIP CHECK
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
    // WALK ID CHECK
    //
    // liveWalkSessions must contain the same walkId.
    // ==========================================================

    final String existingWalkId =
        existing['walkId']
                ?.toString()
                .trim() ??
            '';

    if (existingWalkId.isNotEmpty &&
        existingWalkId != cleanWalkId) {
      throw Exception(
        'Walk ID does not match the live session.',
      );
    }

    // ==========================================================
    // ALREADY COMPLETED
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

    // ==========================================================
    // ALREADY ACTIVE
    // ==========================================================

    if (currentStatus == 'active' ||
        currentStatus == 'started' ||
        currentStatus == 'live') {
      return;
    }

    // ==========================================================
    // START LIVE SESSION
    // ==========================================================

    final Map<String, dynamic>
        sessionData =
        <String, dynamic>{
      // IDENTIFIERS
      'sessionId':
          cleanSessionId,

      'walkId':
          cleanWalkId,

      // OWNER
      'ownerUid':
          ownerUid.trim(),

      'ownerName':
          ownerName.trim(),

      // DOG
      'dogName':
          dogName.trim(),

      'dogBreed':
          dogBreed.trim(),

      // WALKER
      'walkerUid':
          cleanWalkerUid,

      'walkerId':
          walkerId.trim(),

      'walkerName':
          walkerName.trim(),

      'walkerPhone':
          walkerPhone.trim(),

      // STATUS
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

      // START
      'startedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      // STATS
      'distanceKm':
          existing['distanceKm'] ?? 0.0,

      'elapsedSeconds':
          existing['elapsedSeconds'] ?? 0,

      'steps':
          existing['steps'] ?? 0,

      'peeCount':
          existing['peeCount'] ?? 0,

      'poopCount':
          existing['poopCount'] ?? 0,

      // ROUTE
      'routeCoordinates':
          existing['routeCoordinates'] ??
              <dynamic>[],

      // CURRENT LOCATION
      if (existing['currentLocation'] != null)
        'currentLocation':
            existing['currentLocation'],

      // EVENTS
      'events':
          existing['events'] ??
              <dynamic>[],
    };

    await session.set(
      sessionData,
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // COMPLETE WALK
  //
  // IMPORTANT:
  //
  // ONLY:
  // liveWalkSessions/{sessionId}
  //
  // is updated here.
  //
  // NO:
  // walk_requests
  //
  // NO:
  // active_walks
  //
  // ============================================================

  Future<void> completeWalk({
    required String sessionId,
    required String walkId,
  }) async {
    final String cleanSessionId =
        sessionId.trim();

    final String cleanWalkId =
        walkId.trim();

    if (cleanSessionId.isEmpty) {
      throw Exception(
        'Live walk session ID is missing.',
      );
    }

    if (cleanWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final String authUid =
        _currentAuthUid;

    // ==========================================================
    // LIVE SESSION
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        session =
        sessionRef(cleanSessionId);

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
    // VERIFY WALK ID
    // ==========================================================

    final String sessionWalkId =
        data['walkId']
                ?.toString()
                .trim() ??
            '';

    if (sessionWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing from the live session.',
      );
    }

    if (sessionWalkId != cleanWalkId) {
      throw Exception(
        'Walk ID does not match the live session.',
      );
    }

    // ==========================================================
    // VERIFY WALKER
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
    // VERIFY STATUS
    // ==========================================================

    final String status =
        data['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (status == 'completed' ||
        status == 'ended') {
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
    // COMPLETE LIVE SESSION
    //
    // ONLY THIS DOCUMENT IS UPDATED.
    // ==========================================================

    await session.set(
      <String, dynamic>{
        'sessionId':
            cleanSessionId,

        'walkId':
            cleanWalkId,

        'status':
            'completed',

        'walkStarted':
            false,

        'walkEnded':
            true,

        'trackingEnded':
            true,

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
  }
}
