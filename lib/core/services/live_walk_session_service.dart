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

  CollectionReference<Map<String, dynamic>> get _walkRequests {
    return _firestore.collection(
      'walk_request',
    );
  }

  CollectionReference<Map<String, dynamic>> get _qrConnections {
    return _firestore.collection(
      'qr_connections',
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

    if (!snapshot.exists) {
      throw Exception(
        'Live walk session was not found. '
        'Please accept the walk again.',
      );
    }

    final Map<String, dynamic> existing =
        snapshot.data() ??
            <String, dynamic>{};

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

    final Map<String, dynamic> sessionData =
        <String, dynamic>{
      'requestId':
          cleanRequestId,

      'sessionId':
          cleanRequestId,

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

      'walkStarted':
          true,

      'walkEnded':
          false,

      'trackingStarted':
          true,

      'trackingEnded':
          false,

      'startedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

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

      'routeCoordinates':
          existing['routeCoordinates'] ??
              <dynamic>[],

      if (existing['currentLocation'] != null)
        'currentLocation':
            existing['currentLocation'],

      if (existing['currentLat'] != null)
        'currentLat':
            existing['currentLat'],

      if (existing['currentLng'] != null)
        'currentLng':
            existing['currentLng'],

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
  // INSTA WALK:
  //   liveWalkSessions -> completed
  //   walk_request     -> completed
  //   walk_history     -> save
  //
  // QR WALK:
  //   qr_connections   -> read full data
  //   liveWalkSessions -> completed
  //   walk_request     -> DO NOT TOUCH
  //   walk_history     -> save
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

    final DocumentReference<Map<String, dynamic>>
        request =
        _walkRequests.doc(
      cleanRequestId,
    );

    final DocumentReference<Map<String, dynamic>>
        history =
        _history.doc(
      cleanRequestId,
    );

    // ==========================================================
    // GET LIVE SESSION
    // ==========================================================

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
    // VERIFY REQUEST ID
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
    // SOURCE CHECK
    // ==========================================================

    final String source =
        data['source']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    final bool isQrWalk =
        source == 'qr';

    // ==========================================================
    // QR CONNECTION DATA
    //
    // QR connection document is:
    //
    // qr_connections/{ownerId}
    //
    // ownerId is taken from the live session first.
    // ownerUid is used as fallback.
    // ==========================================================

    Map<String, dynamic> qrConnectionData =
        <String, dynamic>{};

    if (isQrWalk) {
      final String ownerId =
          _firstString(
        <dynamic>[
          data['ownerId'],
          data['ownerUid'],
        ],
      );

      if (ownerId.isNotEmpty) {
        final DocumentSnapshot<Map<String, dynamic>>
            qrSnapshot =
            await _qrConnections
                .doc(ownerId)
                .get();

        if (qrSnapshot.exists) {
          qrConnectionData =
              Map<String, dynamic>.from(
            qrSnapshot.data() ??
                <String, dynamic>{},
          );
        }
      }
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
      // --------------------------------------------------------
      // QR:
      // NEVER COMPLETE walk_request.
      // --------------------------------------------------------

      if (isQrWalk) {
        await _ensureHistoryExists(
          requestId:
              cleanRequestId,
          sessionData:
              data,
          authUid:
              authUid,
          qrConnectionData:
              qrConnectionData,
        );

        return;
      }

      // --------------------------------------------------------
      // INSTA:
      // Keep existing behavior.
      // --------------------------------------------------------

      await _completeRequestIfNeeded(
        requestRef:
            request,
        requestId:
            cleanRequestId,
      );

      await _ensureHistoryExists(
        requestId:
            cleanRequestId,
        sessionData:
            data,
        authUid:
            authUid,
        qrConnectionData:
            qrConnectionData,
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
    // BUILD HISTORY
    //
    // QR:
    //   qr_connections data + live session data
    //
    // INSTA:
    //   existing live session data
    // ==========================================================

    final Map<String, dynamic> historyData =
        _buildHistoryData(
      sessionData:
          completedSessionData,
      requestId:
          cleanRequestId,
      authUid:
          authUid,
      completedAt:
          completedTime,
      qrConnectionData:
          qrConnectionData,
    );

    // ==========================================================
    // ATOMIC SAVE
    // ==========================================================

    final WriteBatch batch =
        _firestore.batch();

    // ----------------------------------------------------------
    // 1. LIVE SESSION
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
    // 2. WALK REQUEST
    //
    // ONLY INSTA WALK.
    //
    // QR WALK MUST NEVER WRITE HERE.
    // ----------------------------------------------------------

    if (!isQrWalk) {
      batch.set(
        request,
        <String, dynamic>{
          'status':
              'completed',

          'completedAt':
              completedTime,

          'updatedAt':
              completedTime,
        },
        SetOptions(
          merge: true,
        ),
      );
    }

    // ----------------------------------------------------------
    // 3. WALK HISTORY
    // ----------------------------------------------------------

    batch.set(
      history,
      historyData,
      SetOptions(
        merge: true,
      ),
    );

    // ==========================================================
    // COMMIT
    // ==========================================================

    await batch.commit();
  }

  // ============================================================
  // COMPLETE REQUEST IF NEEDED
  //
  // INSTA WALK ONLY.
  // ============================================================

  Future<void> _completeRequestIfNeeded({
    required DocumentReference<Map<String, dynamic>>
        requestRef,
    required String requestId,
  }) async {
    final DocumentSnapshot<Map<String, dynamic>>
        requestSnapshot =
        await requestRef.get();

    if (!requestSnapshot.exists) {
      return;
    }

    final Map<String, dynamic> requestData =
        requestSnapshot.data() ??
            <String, dynamic>{};

    final String requestStatus =
        requestData['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    if (requestStatus == 'completed') {
      return;
    }

    await requestRef.update(
      <String, dynamic>{
        'status':
            'completed',

        'completedAt':
            FieldValue.serverTimestamp(),

        'updatedAt':
            FieldValue.serverTimestamp(),
      },
    );
  }

  // ============================================================
  // ENSURE HISTORY EXISTS
  // ============================================================

  Future<void> _ensureHistoryExists({
    required String requestId,
    required Map<String, dynamic> sessionData,
    required String authUid,
    required Map<String, dynamic> qrConnectionData,
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
        qrConnectionData:
            qrConnectionData,
      ),
      SetOptions(
        merge: true,
      ),
    );
  }

  // ============================================================
  // BUILD HISTORY DATA
  //
  // For QR:
  //   Full QR connection data is included.
  //
  // Live session data is then applied over it so that
  // live metrics remain canonical.
  // ============================================================

  Map<String, dynamic> _buildHistoryData({
    required Map<String, dynamic> sessionData,
    required String requestId,
    required String authUid,
    required Timestamp completedAt,
    Map<String, dynamic>? qrConnectionData,
  }) {
    final Map<String, dynamic> history =
        <String, dynamic>{};

    // ==========================================================
    // QR CONNECTION DATA FIRST
    // ==========================================================

    if (qrConnectionData != null &&
        qrConnectionData.isNotEmpty) {
      history.addAll(
        Map<String, dynamic>.from(
          qrConnectionData,
        ),
      );
    }

    // ==========================================================
    // LIVE SESSION DATA SECOND
    //
    // This keeps live GPS/metrics/session values canonical.
    // ==========================================================

    history.addAll(
      Map<String, dynamic>.from(
        sessionData,
      ),
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
