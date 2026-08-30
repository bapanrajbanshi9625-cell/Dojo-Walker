import 'package:cloud_firestore/cloud_firestore.dart';

class LiveWalkSessionService {
  LiveWalkSessionService._();

  static final LiveWalkSessionService instance =
      LiveWalkSessionService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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
  // SESSION REFERENCE
  // ============================================================

  DocumentReference<Map<String, dynamic>> sessionRef(
    String sessionId,
  ) {
    return _sessions.doc(sessionId.trim());
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

    // ----------------------------------------------------------
    // ALREADY ACTIVE
    // ----------------------------------------------------------

    if (currentStatus == 'active' ||
        currentStatus == 'started' ||
        currentStatus == 'live') {
      return;
    }

    // ----------------------------------------------------------
    // SESSION DATA
    // ----------------------------------------------------------

    final Map<String, dynamic>
        sessionData =
        <String, dynamic>{
      'walkId': cleanWalkId,

      'ownerUid': ownerUid.trim(),
      'ownerName': ownerName.trim(),

      'dogName': dogName.trim(),
      'dogBreed': dogBreed.trim(),

      'walkerUid': walkerUid.trim(),
      'walkerId': walkerId.trim(),
      'walkerName':
          walkerName.trim(),
      'walkerPhone':
          walkerPhone.trim(),

      'status': 'active',

      'walkStarted': true,

      'startedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

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

      'routeCoordinates':
          existing['routeCoordinates'] ??
              <dynamic>[],

      if (existing['currentLocation'] != null)
        'currentLocation':
            existing['currentLocation'],
    };

    // ----------------------------------------------------------
    // ACTIVE WALK DATA
    // ----------------------------------------------------------

    final Map<String, dynamic>
        activeWalkData =
        <String, dynamic>{
      'walkId': cleanWalkId,

      'ownerUid': ownerUid.trim(),
      'ownerName': ownerName.trim(),

      'dogName': dogName.trim(),
      'dogBreed': dogBreed.trim(),

      'walkerUid': walkerUid.trim(),
      'walkerId': walkerId.trim(),
      'walkerName':
          walkerName.trim(),
      'walkerPhone':
          walkerPhone.trim(),

      'status': 'active',

      'startedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),
    };

    // ----------------------------------------------------------
    // BATCH
    // ----------------------------------------------------------

    final WriteBatch batch =
        _firestore.batch();

    batch.set(
      session,
      sessionData,
      SetOptions(
        merge: true,
      ),
    );

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
      // अगर पुराना active_walk नहीं मिला,
      // नया document walkId के नाम से बनेगा.
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

    final DocumentReference<Map<String, dynamic>>
        session =
        sessionRef(cleanSessionId);

    final DocumentSnapshot<Map<String, dynamic>>
        sessionSnapshot =
        await session.get();

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

    // ----------------------------------------------------------
    // COMPLETE SESSION
    // ----------------------------------------------------------

    batch.set(
      session,
      <String, dynamic>{
        'status': 'completed',
        'walkStarted': false,
        'walkEnded': true,
        'trackingEnded': true,
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

    // ----------------------------------------------------------
    // COMPLETE ACTIVE WALK
    // ----------------------------------------------------------

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
            'status': 'completed',
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
        // Fallback: walkId document
        batch.set(
          _activeWalks.doc(cleanWalkId),
          <String, dynamic>{
            'walkId': cleanWalkId,
            'status': 'completed',
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

    await batch.commit();
  }
}
