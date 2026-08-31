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
  // FIND SESSION BY WALK ID
  //
  // IMPORTANT:
  // Agar passed sessionId wrong/missing ho,
  // to walkId se actual live session find hoga.
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _findSessionByWalkId(
    String walkId,
  ) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return null;
    }

    final QuerySnapshot<Map<String, dynamic>>
        result =
        await _sessions
            .where(
              'walkId',
              isEqualTo: cleanWalkId,
            )
            .limit(1)
            .get();

    if (result.docs.isEmpty) {
      return null;
    }

    return result.docs.first;
  }

  // ============================================================
  // FIND ACTIVE WALK BY WALK ID
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

    // Already active
    if (currentStatus == 'active' ||
        currentStatus == 'started' ||
        currentStatus == 'live') {
      return;
    }

    // ==========================================================
    // SESSION
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

      'trackingEnded':
          false,

      // START TIME
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

      // LOCATION
      if (existing['currentLocation'] != null)
        'currentLocation':
            existing['currentLocation'],

      // IMPORTANT WALK EVENTS
      'events':
          existing['events'] ??
              <dynamic>[],
    };

    // ==========================================================
    // ACTIVE WALK
    // ==========================================================

    final Map<String, dynamic>
        activeWalkData =
        <String, dynamic>{
      'walkId':
          cleanWalkId,

      'ownerUid':
          ownerUid.trim(),

      'ownerName':
          ownerName.trim(),

      'dogName':
          dogName.trim(),

      'dogBreed':
          dogBreed.trim(),

      'walkerUid':
          cleanWalkerUid,

      'walkerId':
          walkerId.trim(),

      'walkerName':
          walkerName.trim(),

      'walkerPhone':
          walkerPhone.trim(),

      'status':
          'active',

      'startedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // LIVE SESSION
    // ==========================================================

    batch.set(
      session,
      sessionData,
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // ACTIVE WALK
    // ==========================================================

    final DocumentSnapshot<
            Map<String, dynamic>>?
        existingActiveWalk =
        await _findActiveWalk(
      cleanWalkId,
    );

    if (existingActiveWalk != null) {
      batch.set(
        existingActiveWalk.reference,
        activeWalkData,
        SetOptions(
          merge: true,
        ),
      );
    } else {
      batch.set(
        _activeWalks.doc(cleanWalkId),
        activeWalkData,
        SetOptions(
          merge: true,
        ),
      );
    }

    await batch.commit();
  }

  // ============================================================
  // COMPLETE WALK
  //
  // IMPORTANT FIX:
  //
  // sessionId से session नहीं मिले तो walkId से खोजेंगे.
  // ============================================================

  Future<void> completeWalk({
    required String sessionId,
    String? walkId,
  }) async {
    final String cleanSessionId =
        sessionId.trim();

    final String cleanPassedWalkId =
        walkId?.trim() ?? '';

    if (cleanSessionId.isEmpty &&
        cleanPassedWalkId.isEmpty) {
      throw Exception(
        'Live walk session ID and walk ID are missing.',
      );
    }

    // Ensure authenticated walker.
    final String authUid =
        _currentAuthUid;

    DocumentSnapshot<Map<String, dynamic>>?
        sessionSnapshot;

    DocumentReference<Map<String, dynamic>>?
        sessionReference;

    // ==========================================================
    // 1. TRY SESSION ID
    // ==========================================================

    if (cleanSessionId.isNotEmpty) {
      final DocumentReference<
              Map<String, dynamic>>
          ref =
          sessionRef(cleanSessionId);

      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await ref.get();

      if (snapshot.exists) {
        sessionSnapshot = snapshot;
        sessionReference = ref;
      }
    }

    // ==========================================================
    // 2. FALLBACK: FIND BY WALK ID
    // ==========================================================

    if (sessionSnapshot == null &&
        cleanPassedWalkId.isNotEmpty) {
      final DocumentSnapshot<
              Map<String, dynamic>>?
          found =
          await _findSessionByWalkId(
        cleanPassedWalkId,
      );

      if (found != null) {
        sessionSnapshot = found;
        sessionReference = found.reference;
      }
    }

    // ==========================================================
    // 3. SESSION MUST EXIST
    // ==========================================================

    if (sessionSnapshot == null ||
        sessionReference == null) {
      throw Exception(
        'Live walk session was not found for this walk.',
      );
    }

    final Map<String, dynamic>
        sessionData =
        sessionSnapshot.data() ??
            <String, dynamic>{};

    // ==========================================================
    // SECURITY CHECK
    //
    // Only attached walker can complete.
    // ==========================================================

    final String sessionWalkerUid =
        sessionData['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (sessionWalkerUid.isNotEmpty &&
        sessionWalkerUid != authUid) {
      throw Exception(
        'You are not authorized to complete this walk.',
      );
    }

    // ==========================================================
    // WALK ID
    // ==========================================================

    final String cleanWalkId =
        cleanPassedWalkId.isNotEmpty
            ? cleanPassedWalkId
            : (
                sessionData['walkId']
                        ?.toString()
                        .trim() ??
                    ''
              );

    // ==========================================================
    // BATCH
    // ==========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ==========================================================
    // COMPLETE LIVE SESSION
    // ==========================================================

    batch.set(
      sessionReference,
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

      final Map<String, dynamic>
          activeData =
          <String, dynamic>{
        'walkId':
            cleanWalkId,

        'status':
            'completed',

        'walkEnded':
            true,

        'trackingEnded':
            true,

        'endedAt':
            FieldValue.serverTimestamp(),

        'completedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      };

      if (activeWalk != null) {
        batch.set(
          activeWalk.reference,
          activeData,
          SetOptions(
            merge: true,
          ),
        );
      } else {
        batch.set(
          _activeWalks.doc(cleanWalkId),
          activeData,
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
