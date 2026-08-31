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
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _sessions {
    return _firestore.collection(
      'liveWalkSessions',
    );
  }

  // ============================================================
  // AUTH
  // ============================================================

  String get _currentAuthUid {
    final User? user =
        _auth.currentUser;

    final String uid =
        user?.uid.trim() ?? '';

    if (uid.isEmpty) {
      throw Exception(
        'Walker authentication is missing. '
        'Please login again.',
      );
    }

    return uid;
  }

  // ============================================================
  // SESSION REFERENCE
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
  // GET SESSION
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getSession(
    String sessionId,
  ) async {
    return sessionRef(sessionId).get();
  }

  // ============================================================
  // START WALK
  //
  // ONLY liveWalkSessions/{sessionId}
  //
  // walk_requests is NEVER modified.
  // active_walk is handled by background service.
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

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await session.get();

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
    // VERIFY WALK ID
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

    final Map<String, dynamic>
        sessionData =
        <String, dynamic>{
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

      // TIME
      'startedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      // STATS
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

      // ROUTE
      'routeCoordinates':
          existing['routeCoordinates'] ??
              <dynamic>[],

      // LOCATION
      if (existing['currentLocation'] != null)
        'currentLocation':
            existing['currentLocation'],

      if (existing['currentLat'] != null)
        'currentLat':
            existing['currentLat'],

      if (existing['currentLng'] != null)
        'currentLng':
            existing['currentLng'],

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
  // ONLY liveWalkSessions/{sessionId}
  //
  // walk_requests is NEVER modified.
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
    // WALK ID
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
    // COMPLETE
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
