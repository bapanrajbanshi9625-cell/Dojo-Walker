import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/live_walk_background_service.dart';
import '../../../core/services/live_walk_session_service.dart';
import '../../../services/walk_request_service.dart';

class LiveWalkSessionController extends ChangeNotifier {
  LiveWalkSessionController({
    required this.walkId,
    required this.ownerUid,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    this.ownerPhone,
    String? sessionId,
  }) : sessionId = _cleanSessionId(
          sessionId,
          walkId,
        );

  // ============================================================
  // DATA
  // ============================================================

  final String walkId;
  final String ownerUid;
  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  final String sessionId;

  // ============================================================
  // SERVICES
  // ============================================================

  final WalkRequestService _walkRequestService =
      WalkRequestService.instance;

  final LiveWalkBackgroundService _backgroundService =
      LiveWalkBackgroundService.instance;

  final LiveWalkSessionService _sessionService =
      LiveWalkSessionService.instance;

  // ============================================================
  // STATE
  // ============================================================

  bool _walkStarted = false;
  bool _startingWalk = false;
  bool _endingWalk = false;

  double _distanceKm = 0.0;
  int _steps = 0;

  Map<String, dynamic> _sessionData =
      <String, dynamic>{};

  StreamSubscription<
          DocumentSnapshot<Map<String, dynamic>>>?
      _sessionSubscription;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get walkStarted => _walkStarted;

  bool get startingWalk => _startingWalk;

  bool get endingWalk => _endingWalk;

  bool get ending => _endingWalk;

  bool get busy =>
      _startingWalk || _endingWalk;

  double get distanceKm => _distanceKm;

  double get totalDistanceKm => _distanceKm;

  int get steps => _steps;

  Map<String, dynamic> get sessionData =>
      Map<String, dynamic>.unmodifiable(
        _sessionData,
      );

  // ============================================================
  // TIMELINE GETTERS
  // ============================================================

  dynamic get createdAt =>
      _sessionData['createdAt'];

  dynamic get acceptedAt =>
      _sessionData['acceptedAt'];

  dynamic get reachedAt =>
      _sessionData['reachedAt'];

  dynamic get startedAt =>
      _sessionData['startedAt'];

  dynamic get completedAt =>
      _sessionData['completedAt'];

  dynamic get endedAt =>
      _sessionData['endedAt'];

  // ============================================================
  // GPS READY
  // ============================================================

  bool get gpsReady {
    final dynamic location =
        _sessionData['currentLocation'];

    if (location is! Map) {
      return false;
    }

    final double? lat = _readDouble(
      location['lat'] ?? location['latitude'],
    );

    final double? lng = _readDouble(
      location['lng'] ??
          location['longitude'] ??
          location['lon'],
    );

    if (lat == null || lng == null) {
      return false;
    }

    return lat != 0 || lng != 0;
  }

  // ============================================================
  // SESSION REFERENCE
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      get sessionRef {
    return _sessionService.sessionRef(
      sessionId,
    );
  }

  // ============================================================
  // SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get sessionStream {
    return sessionRef.snapshots();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    try {
      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await sessionRef.get();

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        updateFromSession(data);
      }

      syncDistance();

      await _sessionSubscription?.cancel();

      _sessionSubscription =
          sessionStream.listen(
        (
          DocumentSnapshot<
                  Map<String, dynamic>>
              snapshot,
        ) {
          final Map<String, dynamic> data =
              snapshot.data() ??
                  <String, dynamic>{};

          if (data.isEmpty) {
            return;
          }

          updateFromSession(data);
        },
        onError: (Object error) {
          debugPrint(
            'LiveWalkSessionController session stream error: $error',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'LiveWalkSessionController.initialize: $e',
      );
    }
  }

  // ============================================================
  // UPDATE FROM FIRESTORE
  // ============================================================

  void updateFromSession(
    Map<String, dynamic> data,
  ) {
    if (data.isEmpty) {
      return;
    }

    _sessionData =
        Map<String, dynamic>.from(data);

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double? firestoreDistance =
        _readDouble(
      data['distanceKm'],
    );

    if (firestoreDistance != null &&
        firestoreDistance >= 0) {
      _distanceKm =
          firestoreDistance;
    } else {
      syncDistance();
    }

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final int? firestoreSteps =
        _readInt(
      data['steps'],
    );

    if (firestoreSteps != null &&
        firestoreSteps >= 0) {
      _steps = firestoreSteps;
    }

    // ----------------------------------------------------------
    // STATUS
    // ----------------------------------------------------------

    final String status =
        data['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    final bool firestoreWalkStarted =
        data['walkStarted'] == true;

    final bool trackingStarted =
        data['trackingStarted'] == true;

    if (status == 'active' ||
        status == 'started' ||
        status == 'live' ||
        firestoreWalkStarted) {
      _walkStarted = true;
    } else if (status == 'completed' ||
        status == 'ended') {
      _walkStarted = false;
    }

    // ----------------------------------------------------------
    // TIMELINE DEBUG
    // ----------------------------------------------------------

    debugPrint(
      'LiveWalk timeline: '
      'createdAt=${data['createdAt']} '
      'acceptedAt=${data['acceptedAt']} '
      'reachedAt=${data['reachedAt']} '
      'startedAt=${data['startedAt']} '
      'completedAt=${data['completedAt']} '
      'trackingStarted=$trackingStarted',
    );

    notifyListeners();
  }

  // ============================================================
  // DISTANCE SYNC
  // ============================================================

  void syncDistance() {
    final double distance =
        _backgroundService.totalDistanceKm;

    if (distance < 0) {
      return;
    }

    if (_distanceKm == distance) {
      return;
    }

    _distanceKm = distance;

    notifyListeners();
  }

  // ============================================================
  // START WALK
  //
  // IMPORTANT:
  //
  // ONLY liveWalkSessions is used.
  //
  // active_walks is NOT used here.
  //
  // Expected Firestore state:
  //
  // status          = active
  // walkStarted     = true
  // trackingStarted = true
  // trackingEnded   = false
  // walkEnded       = false
  // startedAt       = server timestamp
  // updatedAt       = server timestamp
  // ============================================================

  Future<void> startWalk() async {
    if (_walkStarted ||
        _startingWalk ||
        _endingWalk) {
      return;
    }

    _startingWalk = true;

    notifyListeners();

    try {
      await _sessionService.startWalk(
        sessionId: sessionId,
        walkId: walkId,
        ownerUid: ownerUid,
        ownerName: ownerName,
        dogName: dogName,
        dogBreed: dogBreed,
      );

      _walkStarted = true;

      _sessionData = <String, dynamic>{
        ..._sessionData,
        'walkId': walkId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'dogName': dogName,
        'dogBreed': dogBreed,
        'status': 'active',
        'walkStarted': true,
        'trackingStarted': true,
        'trackingEnded': false,
        'walkEnded': false,
      };
    } catch (e) {
      debugPrint(
        'LiveWalkSessionController.startWalk: $e',
      );

      rethrow;
    } finally {
      _startingWalk = false;

      notifyListeners();
    }
  }

  // ============================================================
  // END WALK
  //
  // ONLY liveWalkSessions is used for the session.
  //
  // Then walk request is closed.
  //
  // GPS stops only after successful Firestore completion.
  // ============================================================

  Future<void> endWalk() async {
    if (_endingWalk) {
      return;
    }

    if (!_walkStarted) {
      throw Exception(
        'Please start the walk first.',
      );
    }

    _endingWalk = true;

    notifyListeners();

    try {
      // ========================================================
      // 1. COMPLETE LIVE WALK SESSION
      // ========================================================

      await _sessionService.completeWalk(
        sessionId: sessionId,
        walkId: walkId,
      );

      // ========================================================
      // 2. END WALK REQUEST
      // ========================================================

      await _walkRequestService.endLiveWalk(
        walkId,
        sessionId: sessionId,
      );

      // ========================================================
      // 3. STOP GPS
      // ========================================================

      await _stopGps();

      _walkStarted = false;

      _sessionData = <String, dynamic>{
        ..._sessionData,
        'status': 'completed',
        'walkStarted': false,
        'trackingStarted': true,
        'trackingEnded': true,
        'walkEnded': true,
      };
    } catch (e) {
      debugPrint(
        'LiveWalkSessionController.endWalk: $e',
      );

      rethrow;
    } finally {
      _endingWalk = false;

      notifyListeners();
    }
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> _stopGps() async {
    try {
      await _backgroundService.stop();
    } catch (e) {
      debugPrint(
        'Live GPS stop error: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // FIRESTORE STATUS SYNC
  // ============================================================

  void syncFirestoreStatus(
    String? status,
  ) {
    final String value =
        status?.trim().toLowerCase() ?? '';

    if (value == 'active' ||
        value == 'started' ||
        value == 'live') {
      if (!_walkStarted) {
        _walkStarted = true;
        notifyListeners();
      }

      return;
    }

    if (value == 'completed' ||
        value == 'ended') {
      if (_walkStarted) {
        _walkStarted = false;
        notifyListeners();
      }
    }
  }

  // ============================================================
  // TIMELINE VALIDATION
  // ============================================================

  bool get hasAcceptedTime =>
      _sessionData['acceptedAt'] != null;

  bool get hasReachedTime =>
      _sessionData['reachedAt'] != null;

  bool get hasStartedTime =>
      _sessionData['startedAt'] != null;

  bool get hasCompletedTime =>
      _sessionData['completedAt'] != null;

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _walkStarted = false;
    _startingWalk = false;
    _endingWalk = false;

    _distanceKm = 0.0;
    _steps = 0;

    _sessionData =
        <String, dynamic>{};

    notifyListeners();
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double? _readDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // INT
  // ============================================================

  int? _readInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // SESSION ID CLEANER
  // ============================================================

  static String _cleanSessionId(
    String? value,
    String walkId,
  ) {
    final String clean =
        value?.trim() ?? '';

    if (clean.isNotEmpty) {
      return clean;
    }

    return 'session-${walkId.trim()}';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    unawaited(
      _sessionSubscription?.cancel(),
    );

    _sessionSubscription = null;

    super.dispose();
  }
}
