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

  CollectionReference<Map<String, dynamic>>
      get _sessions {
    return _firestore.collection(
      'liveWalkSessions',
    );
  }

  CollectionReference<Map<String, dynamic>>
      get _history {
    return _firestore.collection(
      'walk_history',
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
  //
  // IMPORTANT:
  // One Walk = One Live Session.
  //
  // Therefore:
  //
  // liveWalkSessions/{walkId}
  //
  // Example:
  // liveWalkSessions/DW-000001
  // ============================================================

  DocumentReference<Map<String, dynamic>> sessionRef(
    String walkId,
  ) {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    return _sessions.doc(cleanWalkId);
  }

  // ============================================================
  // GET SESSION
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>>
      getSession(
    String walkId,
  ) async {
    return sessionRef(walkId).get();
  }

  // ============================================================
  // START WALK
  //
  // IMPORTANT:
  //
  // sessionId is accepted for compatibility with existing callers,
  // but the canonical ID is always walkId.
  //
  // Firestore:
  //
  // liveWalkSessions/DW-000001
  //
  // sessionId = DW-000001
  // walkId    = DW-000001
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

    if (cleanWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ==========================================================
    // ONE WALK = ONE SESSION
    //
    // Ignore any old/random session ID.
    // The Walk ID is the canonical session ID.
    // ==========================================================

    final String canonicalSessionId =
        cleanWalkId;

    // Keep this validation only for compatibility.
    // If an old caller passes a different sessionId, we do not
    // create a wrong Firestore document.
    if (cleanSessionId.isNotEmpty &&
        cleanSessionId != cleanWalkId) {
      // Intentionally use walkId as the canonical ID.
      //
      // No exception here because older callers may still pass
      // an old session ID.
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
        sessionRef(cleanWalkId);

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
      // --------------------------------------------------------
      // IDENTIFIERS
      // --------------------------------------------------------

      'sessionId':
          canonicalSessionId,

      'walkId':
          cleanWalkId,

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
    // liveWalkSessions/{walkId}
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
  // IMPORTANT:
  //
  // 1. Read final live session.
  // 2. Verify walker.
  // 3. Mark live session completed.
  // 4. Save same completed walk to walk_history.
  //
  // History document ID = walkId.
  //
  // liveWalkSessions/DW-000001
  // walk_history/DW-000001
  // ============================================================

  Future<void> completeWalk({
    required String sessionId,
    required String walkId,
  }) async {
    final String cleanSessionId =
        sessionId.trim();

    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ==========================================================
    // CANONICAL SESSION ID
    //
    // Ignore random/old session ID.
    // ==========================================================

    final String canonicalSessionId =
        cleanWalkId;

    // Keep compatibility with existing callers.
    if (cleanSessionId.isNotEmpty &&
        cleanSessionId != cleanWalkId) {
      // Intentionally ignored.
      //
      // walkId remains the canonical ID.
    }

    final String authUid =
        _currentAuthUid;

    final DocumentReference<Map<String, dynamic>>
        session =
        sessionRef(cleanWalkId);

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

    // ==========================================================
    // ALREADY COMPLETED
    // ==========================================================

    if (status == 'completed' ||
        status == 'ended') {
      await _ensureHistoryExists(
        sessionId:
            canonicalSessionId,
        walkId:
            cleanWalkId,
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
        Map<String, dynamic>.from(data);

    completedSessionData.addAll(
      <String, dynamic>{
        'sessionId':
            canonicalSessionId,

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
    // liveWalkSessions/{walkId}
    // walk_history/{walkId}
    // ==========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ----------------------------------------------------------
    // LIVE SESSION
    // ----------------------------------------------------------

    batch.set(
      session,
      <String, dynamic>{
        'sessionId':
            canonicalSessionId,

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
    // IMPORTANT:
    // Document ID = Walk ID.
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>>
        historyRef =
        _history.doc(cleanWalkId);

    batch.set(
      historyRef,
      _buildHistoryData(
        sessionData:
            completedSessionData,
        sessionId:
            canonicalSessionId,
        walkId:
            cleanWalkId,
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
  // Because document ID = walkId, duplicate history documents
  // cannot be created for the same walk.
  // ============================================================

  Future<void> _ensureHistoryExists({
    required String sessionId,
    required String walkId,
    required Map<String, dynamic> sessionData,
    required String authUid,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        historyRef =
        _history.doc(walkId);

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
        sessionId:
            walkId,
        walkId:
            walkId,
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
    required String sessionId,
    required String walkId,
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

        'sessionId':
            walkId,

        'walkId':
            walkId,

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
