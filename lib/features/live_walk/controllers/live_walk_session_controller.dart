import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/live_walk_background_service.dart';
import '../../../core/services/live_walk_session_service.dart';

class LiveWalkSessionController extends ChangeNotifier {
  LiveWalkSessionController({
    required this.walkId,
    required this.ownerUid,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    required this.sessionId,
    this.ownerPhone,
  });

  // ============================================================
  // DATA
  // ============================================================

  final String walkId;
  final String ownerUid;
  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  /// REAL FIRESTORE DOCUMENT ID
  ///
  /// liveWalkSessions/{sessionId}
  final String sessionId;

  // ============================================================
  // SERVICES
  // ============================================================

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
  bool _disposed = false;

  double _distanceKm = 0.0;
  int _steps = 0;

  int _peeCount = 0;
  int _poopCount = 0;

  Map<String, dynamic> _sessionData = <String, dynamic>{};

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _sessionSubscription;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get walkStarted => _walkStarted;

  bool get startingWalk => _startingWalk;

  bool get endingWalk => _endingWalk;

  bool get ending => _endingWalk;

  bool get busy => _startingWalk || _endingWalk;

  double get distanceKm => _distanceKm;

  double get totalDistanceKm => _distanceKm;

  int get steps => _steps;

  int get peeCount => _peeCount;

  int get poopCount => _poopCount;

  Map<String, dynamic> get sessionData =>
      Map<String, dynamic>.unmodifiable(_sessionData);

  // ============================================================
  // SESSION TIMELINE
  // ============================================================

  dynamic get createdAt => _sessionData['createdAt'];

  dynamic get acceptedAt => _sessionData['acceptedAt'];

  dynamic get reachedAt => _sessionData['reachedAt'];

  dynamic get startedAt => _sessionData['startedAt'];

  dynamic get completedAt => _sessionData['completedAt'];

  dynamic get endedAt => _sessionData['endedAt'];

  // ============================================================
  // REACH STATE
  //
  // IMPORTANT:
  // Live Walk START is allowed only after Reach.
  // ============================================================

  bool get hasAcceptedTime =>
      _sessionData['acceptedAt'] != null;

  bool get hasReachedTime =>
      _sessionData['reachedAt'] != null;

  bool get hasStartedTime =>
      _sessionData['startedAt'] != null;

  bool get hasCompletedTime =>
      _sessionData['completedAt'] != null;

  bool get reached {
    if (hasReachedTime) {
      return true;
    }

    final String status =
        (_sessionData['status']?.toString() ?? '')
            .trim()
            .toLowerCase();

    return status == 'reached' ||
        status == 'arrived' ||
        status == 'ready';
  }

  // ============================================================
  // GPS
  // ============================================================

  bool get gpsReady {
    final dynamic location =
        _sessionData['currentLocation'];

    if (location is GeoPoint) {
      return location.latitude != 0 ||
          location.longitude != 0;
    }

    if (location is Map) {
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

    return false;
  }

  // ============================================================
  // FIRESTORE SESSION REFERENCE
  // ============================================================

  DocumentReference<Map<String, dynamic>> get sessionRef {
    return _sessionService.sessionRef(sessionId);
  }

  // ============================================================
  // FIRESTORE SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> get sessionStream {
    return sessionRef.snapshots();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_disposed) {
      return;
    }

    try {
      debugPrint(
        'LiveWalkSessionController.initialize '
        'walkId=$walkId '
        'sessionId=$sessionId',
      );

      await _sessionSubscription?.cancel();

      if (_disposed) {
        return;
      }

      // --------------------------------------------------------
      // FIRST SNAPSHOT
      // --------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await sessionRef.get();

      if (_disposed) {
        return;
      }

      if (!snapshot.exists) {
        debugPrint(
          'Live session not found: '
          'liveWalkSessions/$sessionId',
        );
      } else {
        final Map<String, dynamic> data =
            snapshot.data() ?? <String, dynamic>{};

        if (data.isNotEmpty) {
          updateFromSession(data);
        }
      }

      // --------------------------------------------------------
      // REAL-TIME SESSION LISTENER
      // --------------------------------------------------------

      _sessionSubscription = sessionStream.listen(
        (
          DocumentSnapshot<Map<String, dynamic>> snapshot,
        ) {
          if (_disposed || !snapshot.exists) {
            return;
          }

          final Map<String, dynamic> data =
              snapshot.data() ?? <String, dynamic>{};

          if (data.isEmpty) {
            return;
          }

          updateFromSession(data);
        },
        onError: (Object error) {
          if (_disposed) {
            return;
          }

          debugPrint(
            'LiveWalk session stream error: $error',
          );
        },
        cancelOnError: false,
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      debugPrint(
        'LiveWalkSessionController.initialize: $error',
      );
    }
  }

  // ============================================================
  // UPDATE FROM FIRESTORE
  // ============================================================

  void updateFromSession(
    Map<String, dynamic> data,
  ) {
    if (_disposed || data.isEmpty) {
      return;
    }

    _sessionData =
        Map<String, dynamic>.from(data);

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double? firestoreDistance =
        _readDouble(data['distanceKm']);

    if (firestoreDistance != null &&
        firestoreDistance >= 0) {
      _distanceKm = firestoreDistance;
    } else {
      final double localDistance =
          _backgroundService.totalDistanceKm;

      if (localDistance >= 0) {
        _distanceKm = localDistance;
      }
    }

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final int? firestoreSteps =
        _readInt(data['steps']);

    if (firestoreSteps != null &&
        firestoreSteps >= 0) {
      _steps = firestoreSteps;
    }

    // ----------------------------------------------------------
    // PEE
    // ----------------------------------------------------------

    final int? firestorePee =
        _readInt(data['peeCount']);

    if (firestorePee != null &&
        firestorePee >= 0) {
      _peeCount = firestorePee;
    }

    // ----------------------------------------------------------
    // POOP
    // ----------------------------------------------------------

    final int? firestorePoop =
        _readInt(data['poopCount']);

    if (firestorePoop != null &&
        firestorePoop >= 0) {
      _poopCount = firestorePoop;
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

    final bool walkEnded =
        data['walkEnded'] == true;

    final bool completed =
        status == 'completed' ||
        status == 'ended' ||
        walkEnded;

    if (completed) {
      _walkStarted = false;
    } else if (status == 'active' ||
        status == 'started' ||
        status == 'live' ||
        firestoreWalkStarted ||
        trackingStarted) {
      _walkStarted = true;
    } else {
      _walkStarted = false;
    }

    debugPrint(
      'LiveWalk timeline: '
      'walkId=$walkId '
      'sessionId=$sessionId '
      'status=$status '
      'reachedAt=${data['reachedAt']} '
      'startedAt=${data['startedAt']} '
      'completedAt=${data['completedAt']}',
    );

    notifyListeners();
  }

  // ============================================================
  // DISTANCE SYNC
  // ============================================================

  void syncDistance() {
    if (_disposed) {
      return;
    }

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
  // ACTIVITY UPDATE
  // ============================================================

  void updateActivities({
    int? peeCount,
    int? poopCount,
  }) {
    if (_disposed) {
      return;
    }

    if (peeCount != null && peeCount >= 0) {
      _peeCount = peeCount;
    }

    if (poopCount != null && poopCount >= 0) {
      _poopCount = poopCount;
    }

    notifyListeners();

    // This method returns void.
    _backgroundService.updateActivities(
      peeCount: _peeCount,
      poopCount: _poopCount,
    );
  }

  // ============================================================
  // STEPS UPDATE
  // ============================================================

  void updateSteps(int value) {
    if (_disposed || value < 0) {
      return;
    }

    _steps = value;

    notifyListeners();

    _backgroundService.updateSteps(value);
  }

  // ============================================================
  // START WALK
  // ============================================================

  Future<void> startWalk() async {
    if (_disposed) {
      return;
    }

    if (_walkStarted) {
      return;
    }

    if (_startingWalk || _endingWalk) {
      return;
    }

    // ----------------------------------------------------------
    // IMPORTANT:
    // Walker must reach owner/destination before starting.
    // ----------------------------------------------------------

    if (!reached) {
      throw Exception(
        'Please reach the owner before starting the walk.',
      );
    }

    _startingWalk = true;

    notifyListeners();

    try {
      debugPrint(
        'Starting live walk '
        'walkId=$walkId '
        'sessionId=$sessionId',
      );

      // --------------------------------------------------------
      // FIRESTORE
      // --------------------------------------------------------

      await _sessionService.startWalk(
        sessionId: sessionId,
        walkId: walkId,
        ownerUid: ownerUid,
        ownerName: ownerName,
        dogName: dogName,
        dogBreed: dogBreed,
      );

      if (_disposed) {
        return;
      }

      // --------------------------------------------------------
      // BACKGROUND GPS
      //
      // start() returns void.
      // --------------------------------------------------------

      _backgroundService.start(
        walkId: walkId,
        sessionId: sessionId,
        initialDistanceKm: _distanceKm,
        initialSteps: _steps,
        initialPeeCount: _peeCount,
        initialPoopCount: _poopCount,
      );

      // --------------------------------------------------------
      // LOCAL STATE
      // --------------------------------------------------------

      _walkStarted = true;

      _sessionData = <String, dynamic>{
        ..._sessionData,
        'sessionId': sessionId,
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
        'startedAt':
            _sessionData['startedAt'] ??
            Timestamp.now(),
      };

      notifyListeners();
    } catch (error) {
      debugPrint(
        'LiveWalkSessionController.startWalk: $error',
      );

      rethrow;
    } finally {
      if (!_disposed) {
        _startingWalk = false;
        notifyListeners();
      }
    }
  }

  // ============================================================
  // END WALK
  // ============================================================

  Future<void> endWalk() async {
    if (_disposed) {
      return;
    }

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
      debugPrint(
        'Completing live walk '
        'walkId=$walkId '
        'sessionId=$sessionId',
      );

      // --------------------------------------------------------
      // COMPLETE FIRESTORE SESSION
      // --------------------------------------------------------

      await _sessionService.completeWalk(
        sessionId: sessionId,
        walkId: walkId,
      );

      if (_disposed) {
        return;
      }

      // --------------------------------------------------------
      // STOP GPS
      //
      // stop() returns void.
      // --------------------------------------------------------

      _backgroundService.stop();

      // --------------------------------------------------------
      // LOCAL STATE
      // --------------------------------------------------------

      _walkStarted = false;

      _sessionData = <String, dynamic>{
        ..._sessionData,
        'sessionId': sessionId,
        'walkId': walkId,
        'status': 'completed',
        'walkStarted': false,
        'trackingStarted': true,
        'trackingEnded': true,
        'walkEnded': true,
        'completedAt':
            _sessionData['completedAt'] ??
            Timestamp.now(),
        'endedAt':
            _sessionData['endedAt'] ??
            Timestamp.now(),
      };

      debugPrint(
        'Live walk completed: '
        'liveWalkSessions/$sessionId',
      );
    } catch (error) {
      debugPrint(
        'LiveWalkSessionController.endWalk: $error',
      );

      rethrow;
    } finally {
      if (!_disposed) {
        _endingWalk = false;
        notifyListeners();
      }
    }
  }

  // ============================================================
  // FIRESTORE STATUS SYNC
  // ============================================================

  void syncFirestoreStatus(
    String? status,
  ) {
    if (_disposed) {
      return;
    }

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
  // RESET
  // ============================================================

  void reset() {
    if (_disposed) {
      return;
    }

    _walkStarted = false;
    _startingWalk = false;
    _endingWalk = false;

    _distanceKm = 0.0;
    _steps = 0;

    _peeCount = 0;
    _poopCount = 0;

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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _disposed = true;

    final StreamSubscription<
        DocumentSnapshot<Map<String, dynamic>>>?
        subscription = _sessionSubscription;

    _sessionSubscription = null;

    if (subscription != null) {
      unawaited(
        subscription.cancel(),
      );
    }

    super.dispose();
  }
}
