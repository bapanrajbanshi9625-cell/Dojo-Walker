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
  // START WALK
  //
  // IMPORTANT:
  //
  // active_walks collection is NOT used anymore.
  //
  // Complete timeline is maintained inside:
  //
  // liveWalkSessions/{sessionId}
  //
  // Timeline:
  //
  // createdAt
  // acceptedAt
  // reachedAt
  // startedAt
  // completedAt
  // endedAt
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

    // ==========================================================
    // AUTH
    // ==========================================================

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

    // ==========================================================
    // SESSION
    // ==========================================================

    final DocumentReference<Map<String, dynamic>>
        session =
        sessionRef(cleanSessionId);

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await session.get();

    final Map<String, dynamic> existing =
        snapshot.data() ??
            <String, dynamic>{};

    final String currentStatus =
        existing['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    // ==========================================================
    // ALREADY ACTIVE
    // ==========================================================

    if (currentStatus == 'active' ||
        currentStatus == 'started' ||
        currentStatus == 'live') {
      return;
    }

    // ==========================================================
    // START WALK DATA
    // ==========================================================

    final Map<String, dynamic> data =
        <String, dynamic>{
      // --------------------------------------------------------
      // IDENTIFIERS
      // --------------------------------------------------------

      'sessionId':
          cleanSessionId,

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

      'trackingEnded':
          false,

      // --------------------------------------------------------
      // TIMELINE
      //
      // startedAt is ONLY written when Start Walk happens.
      // Existing acceptedAt / reachedAt / createdAt remain intact.
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

      'elapsedSeconds':
          existing['elapsedSeconds'] ?? 0,

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
    };

    // ==========================================================
    // WRITE ONLY TO liveWalkSessions
    // ==========================================================

    await session.set(
      data,
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // COMPLETE WALK
  //
  // No active_walks update.
  //
  // Everything stays in liveWalkSessions.
  // ============================================================

  Future<void> completeWalk({
    required String sessionId,
    String? walkId,
  }) async {
    final String cleanSessionId =
        sessionId.trim();

    if (cleanSessionId.isEmpty) {
      throw Exception(
        'Live walk session ID is missing.',
      );
    }

    // Ensure authenticated walker.
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

    // ==========================================================
    // COMPLETE SESSION
    // ==========================================================

    await session.set(
      <String, dynamic>{
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

        // ------------------------------------------------------
        // TIMELINE
        // ------------------------------------------------------

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
