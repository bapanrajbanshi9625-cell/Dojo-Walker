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
  // COMPLETE WALK + SAVE HISTORY
  //
  // IMPORTANT:
  //
  // 1. Read final live session.
  // 2. Verify walker.
  // 3. Mark live session completed.
  // 4. Save the same completed walk to walk_history.
  //
  // History document ID = sessionId.
  //
  // This makes the operation idempotent and prevents duplicate
  // history documents for the same live session.
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

    // ==========================================================
    // ALREADY COMPLETED
    //
    // Even if the live session is already completed, make sure
    // History exists.
    // ==========================================================

    if (status == 'completed' ||
        status == 'ended') {
      await _ensureHistoryExists(
        sessionId: cleanSessionId,
        walkId: cleanWalkId,
        sessionData: data,
        authUid: authUid,
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
    //
    // Keep ALL existing session information and add completed
    // state.
    // ==========================================================

    final Map<String, dynamic>
        completedSessionData =
        Map<String, dynamic>.from(data);

    completedSessionData.addAll(
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
    // Both documents are written together.
    //
    // liveWalkSessions/{sessionId}
    // walk_history/{sessionId}
    //
    // If the batch fails, neither write is committed.
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
    // ----------------------------------------------------------

    final DocumentReference<Map<String, dynamic>>
        historyRef =
        _history.doc(cleanSessionId);

    batch.set(
      historyRef,
      _buildHistoryData(
        sessionData:
            completedSessionData,
        sessionId:
            cleanSessionId,
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
  // Because the document ID is sessionId, this does not create
  // another history entry.
  // ============================================================

  Future<void> _ensureHistoryExists({
    required String sessionId,
    required String walkId,
    required Map<String, dynamic> sessionData,
    required String authUid,
  }) async {
    final DocumentReference<Map<String, dynamic>>
        historyRef =
        _history.doc(sessionId);

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
            sessionId,
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
  // Existing live session fields are preserved so Walk History
  // can use the same data.
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
            sessionId,

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
      history['steps'] = 0;
    }

    // ==========================================================
    // ACTIVITIES
    // ==========================================================

    if (!history.containsKey('peeCount')) {
      history['peeCount'] = 0;
    }

    if (!history.containsKey('poopCount')) {
      history['poopCount'] = 0;
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
