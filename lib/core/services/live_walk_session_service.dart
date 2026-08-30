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
    return _firestore.collection('liveWalkSessions');
  }

  CollectionReference<Map<String, dynamic>>
      get _activeWalks {
    return _firestore.collection('active_walks');
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
  // FIND ACTIVE WALK DOCUMENT
  //
  // active_walks document ID जरूरी नहीं कि walkId हो.
  // इसलिए पहले walkId field से खोजेंगे.
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _findActiveWalk(
    String walkId,
  ) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return null;
    }

    final QuerySnapshot<Map<String, dynamic>>
        query =
        await _activeWalks
            .where(
              'walkId',
              isEqualTo: cleanWalkId,
            )
            .limit(1)
            .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    return null;
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

    // ==========================================================
    // AUTH UID
    //
    // IMPORTANT:
    // Walker UID हमेशा Firebase Auth UID रहेगा.
    // Caller से empty आया तो automatically currentUser.uid.
    // ==========================================================

    final String authUid =
        _currentAuthUid;

    final String cleanWalkerUid =
        walkerUid.trim().isNotEmpty
            ? walkerUid.trim()
            : authUid;

    // ==========================================================
    // SECURITY
    //
    // अगर walkerUid दिया गया है तो वही logged-in walker होना
    // चाहिए.
    // ==========================================================

    if (cleanWalkerUid != authUid) {
      throw Exception(
        'Walker authentication mismatch.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        session =
        sessionRef(cleanSessionId);

    final DocumentSnapshot<Map<String, dynamic>>
        sessionSnapshot =
        await session.get();

    final Map<String, dynamic> existing =
        sessionSnapshot.data() ??
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
    // SESSION DATA
    // ==========================================================

    final Map<String, dynamic>
        sessionData =
        <String, dynamic>{
      'walkId': cleanWalkId,

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

      // --------------------------------------------------------
      // TIMESTAMPS
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
      // CURRENT LOCATION
      // --------------------------------------------------------

      if (existing['currentLocation'] != null)
        'currentLocation':
            existing['currentLocation'],
    };

    // ==========================================================
    // ACTIVE WALK DATA
    // ==========================================================

    final Map<String, dynamic>
        activeWalkData =
        <String, dynamic>{
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

      // --------------------------------------------------------
      // TIMESTAMPS
      // --------------------------------------------------------

      'startedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    // ==========================================================
    // BATCH
    // ==========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ----------------------------------------------------------
    // LIVE SESSION
    // ----------------------------------------------------------

    batch.set(
      session,
      sessionData,
      SetOptions(
        merge: true,
      ),
    );

    // ----------------------------------------------------------
    // FIND ACTIVE WALK
    // ----------------------------------------------------------

    final DocumentSnapshot<
            Map<String, dynamic>>?
        existingActiveWalk =
        await _findActiveWalk(
      cleanWalkId,
    );

    // ----------------------------------------------------------
    // UPDATE EXISTING ACTIVE WALK
    // ----------------------------------------------------------

    if (existingActiveWalk != null) {
      batch.set(
        existingActiveWalk.reference,
        activeWalkData,
        SetOptions(
          merge: true,
        ),
      );
    }

    // ----------------------------------------------------------
    // CREATE NEW ACTIVE WALK
    // ----------------------------------------------------------

    else {
      batch.set(
        _activeWalks.doc(cleanWalkId),
        activeWalkData,
        SetOptions(
          merge: true,
        ),
      );
    }

    // ==========================================================
    // COMMIT
    // ==========================================================

    await batch.commit();
  }

  // ============================================================
  // COMPLETE WALK
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

    // Ensure logged-in user exists.
    _currentAuthUid;

    final DocumentReference<Map<String, dynamic>>
        session =
        sessionRef(cleanSessionId);

    final DocumentSnapshot<Map<String, dynamic>>
        sessionSnapshot =
        await session.get();

    if (!sessionSnapshot.exists) {
      throw Exception(
        'Live walk session was not found.',
      );
    }

    final Map<String, dynamic> sessionData =
        sessionSnapshot.data() ??
            <String, dynamic>{};

    final String cleanWalkId =
        (walkId ??
                sessionData['walkId']
                    ?.toString() ??
                '')
            .trim();

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // COMPLETE LIVE SESSION
    // ==========================================================

    batch.set(
      session,
      <String, dynamic>{
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

    // ==========================================================
    // COMPLETE ACTIVE WALK
    // ==========================================================

    if (cleanWalkId.isNotEmpty) {
      final DocumentSnapshot<
              Map<String, dynamic>>?
          activeWalk =
          await _findActiveWalk(
        cleanWalkId,
      );

      if (activeWalk != null) {
        batch.set(
          activeWalk.reference,
          <String, dynamic>{
            'status':
                'completed',

            'endedAt':
                FieldValue.serverTimestamp(),

            'completedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      } else {
        batch.set(
          _activeWalks.doc(cleanWalkId),
          <String, dynamic>{
            'walkId':
                cleanWalkId,

            'status':
                'completed',

            'endedAt':
                FieldValue.serverTimestamp(),

            'completedAt':
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

    // ==========================================================
    // COMMIT
    // ==========================================================

    await batch.commit();
  }
}
