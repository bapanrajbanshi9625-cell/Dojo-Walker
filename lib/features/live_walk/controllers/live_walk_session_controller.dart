import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/live_walk_session_service.dart';
import '../../../services/walker_location_service.dart';
import '../services/live_walk_background_service.dart';

class LiveWalkSessionController extends ChangeNotifier {
  LiveWalkSessionController({
    required this.requestId,
    required this.ownerUid,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    this.ownerPhone,
  });

  // ============================================================
  // DATA
  // ============================================================

  /// CANONICAL WALK / REQUEST ID
  ///
  /// Same ID:
  ///
  /// walk_request/{requestId}
  /// liveWalkSessions/{requestId}
  /// walk_history/{requestId}
  ///
  /// Example:
  /// DW000001
  final String requestId;

  final String ownerUid;
  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  // ============================================================
  // COMPATIBILITY GETTERS
  // ============================================================

  String get walkId => requestId;

  String get sessionId => requestId;

  // ============================================================
  // SERVICES
  // ============================================================

  final LiveWalkBackgroundService _backgroundService =
      LiveWalkBackgroundService.instance;

  final LiveWalkSessionService _sessionService =
      LiveWalkSessionService.instance;

  /// CANONICAL GPS SERVICE.
  ///
  /// GPS is started ONLY at Accept.
  /// GPS is stopped ONLY at Complete.
  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  // ============================================================
  // STATE
  // ============================================================

  bool _walkStarted = false;
  bool _startingWalk = false;
  bool _endingWalk = false;
  bool _walkCompleted = false;
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

  bool get completed => _walkCompleted;

  bool get busy => _startingWalk || _endingWalk;

  double get distanceKm => _distanceKm;

  double get totalDistanceKm => _distanceKm;

  int get steps => _steps;

  int get peeCount => _peeCount;

  int get poopCount => _poopCount;

  Map<String, dynamic> get sessionData =>
      Map<String, dynamic>.unmodifiable(
        _sessionData,
      );

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
  // GPS READY
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
        location['lat'] ??
            location['latitude'],
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
    return _sessionService.sessionRef(
      requestId,
    );
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
        'requestId=$requestId',
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
          'liveWalkSessions/$requestId',
        );
      } else {
        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        if (data.isNotEmpty) {
          updateFromSession(data);
        }
      }

      // --------------------------------------------------------
      // REAL-TIME SESSION LISTENER
      // --------------------------------------------------------

      _sessionSubscription =
          sessionStream.listen(
        (
          DocumentSnapshot<Map<String, dynamic>> snapshot,
        ) {
          if (_disposed ||
              !snapshot.exists) {
            return;
          }

          final Map<String, dynamic> data =
              snapshot.data() ??
                  <String, dynamic>{};

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
        'LiveWalkSessionController.initialize: '
        '$error',
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
        _readDouble(
      data['distanceKm'],
    );

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
        _readInt(
      data['steps'],
    );

    if (firestoreSteps != null &&
        firestoreSteps >= 0) {
      _steps = firestoreSteps;
    }

    // ----------------------------------------------------------
    // PEE
    // ----------------------------------------------------------

    final int? firestorePee =
        _readInt(
      data['peeCount'],
    );

    if (firestorePee != null &&
        firestorePee >= 0) {
      _peeCount = firestorePee;
    }

    // ----------------------------------------------------------
    // POOP
    // ----------------------------------------------------------

    final int? firestorePoop =
        _readInt(
      data['poopCount'],
    );

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
        walkEnded ||
        data['completedAt'] != null;

    // ----------------------------------------------------------
    // COMPLETED
    // ----------------------------------------------------------

    if (completed) {
      _walkStarted = false;
      _walkCompleted = true;
    }

    // ----------------------------------------------------------
    // ACTIVE
    // ----------------------------------------------------------

    else if (status == 'active' ||
        status == 'started' ||
        status == 'live' ||
        firestoreWalkStarted ||
        trackingStarted) {
      _walkStarted = true;
      _walkCompleted = false;
    }

    // ----------------------------------------------------------
    // OTHER / NOT STARTED
    // ----------------------------------------------------------

    else {
      _walkStarted = false;
    }

    debugPrint(
      'LiveWalk timeline: '
      'requestId=$requestId '
      'status=$status '
      'walkStarted=$_walkStarted '
      'completed=$_walkCompleted '
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
    if (_disposed || !_walkStarted) {
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
  // RECORD DOG ACTIVITY
  // ============================================================
  //
  // Single source of truth:
  //
  // Controller
  //      ↓
  // Firestore atomic increment
  //      ↓
  // Background metrics
  //
  // No separate activity controller/service.
  // ============================================================

  Future<void> recordDogActivity({
    required String type,
  }) async {
    if (_disposed ||
        !_walkStarted ||
        _endingWalk) {
      return;
    }

    final String normalized =
        type.trim().toLowerCase();

    final String field;

    if (normalized == 'pee') {
      field = 'peeCount';
    } else if (normalized == 'poop') {
      field = 'poopCount';
    } else {
      throw ArgumentError.value(
        type,
        'type',
        'Unsupported dog activity.',
      );
    }

    final int previousCount =
        field == 'peeCount'
            ? _peeCount
            : _poopCount;

    final int nextCount =
        previousCount + 1;

    // ----------------------------------------------------------
    // OPTIMISTIC LOCAL UPDATE
    // ----------------------------------------------------------

    if (field == 'peeCount') {
      _peeCount = nextCount;
    } else {
      _poopCount = nextCount;
    }

    _sessionData =
        <String, dynamic>{
      ..._sessionData,
      field: nextCount,
    };

    notifyListeners();

    try {
      // --------------------------------------------------------
      // FIRESTORE ATOMIC INCREMENT
      // --------------------------------------------------------

      await sessionRef.update(
        <String, dynamic>{
          field: FieldValue.increment(1),
        },
      );

      // --------------------------------------------------------
      // BACKGROUND METRICS SYNC
      // --------------------------------------------------------

      try {
        _backgroundService.updateActivities(
          peeCount: _peeCount,
          poopCount: _poopCount,
        );
      } catch (error) {
        debugPrint(
          'LiveWalk activity background update failed: '
          '$error',
        );
      }
    } catch (error) {
      // --------------------------------------------------------
      // ROLLBACK LOCAL STATE
      // --------------------------------------------------------

      if (!_disposed) {
        if (field == 'peeCount') {
          _peeCount = previousCount;
        } else {
          _poopCount = previousCount;
        }

        _sessionData =
            <String, dynamic>{
          ..._sessionData,
          field: previousCount,
        };

        notifyListeners();
      }

      rethrow;
    }
  }

  // ============================================================
  // ACTIVITY UPDATE
  // ============================================================

  void updateActivities({
    int? peeCount,
    int? poopCount,
  }) {
    if (_disposed || !_walkStarted) {
      return;
    }

    if (peeCount != null &&
        peeCount >= 0) {
      _peeCount = peeCount;
    }

    if (poopCount != null &&
        poopCount >= 0) {
      _poopCount = poopCount;
    }

    notifyListeners();

    _backgroundService.updateActivities(
      peeCount: _peeCount,
      poopCount: _poopCount,
    );
  }

  // ============================================================
  // STEPS UPDATE
  // ============================================================

  void updateSteps(
    int value,
  ) {
    if (_disposed ||
        !_walkStarted ||
        value < 0) {
      return;
    }

    _steps = value;

    notifyListeners();

    _backgroundService.updateSteps(
      value,
    );
  }

  // ============================================================
  // START WALK / ROCKSTAR
  //
  // IMPORTANT:
  //
  // GPS IS NOT STARTED HERE.
  //
  // GPS was already started by ACCEPT.
  //
  // Rockstar only starts:
  // - seconds
  // - minutes
  // - distance/KM
  // - route
  // - steps
  // - pee/poop tracking
  // ============================================================

  Future<void> startWalk() async {
    if (_disposed) {
      return;
    }

    if (_walkStarted ||
        _walkCompleted) {
      return;
    }

    if (_startingWalk ||
        _endingWalk) {
      return;
    }

    // ----------------------------------------------------------
    // MUST REACH OWNER FIRST
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
        'requestId=$requestId',
      );

      // --------------------------------------------------------
      // STEP 1
      // MARK LIVE SESSION ACTIVE
      // --------------------------------------------------------

      await _sessionService.startWalk(
        requestId: requestId,
        ownerUid: ownerUid,
        ownerName: ownerName,
        dogName: dogName,
        dogBreed: dogBreed,
      );

      if (_disposed) {
        return;
      }

      // --------------------------------------------------------
      // STEP 2
      // START COUNTING / METRICS
      //
      // DOES NOT START GPS.
      // --------------------------------------------------------

      final bool metricsStarted =
          await _backgroundService.start(
        requestId: requestId,
        initialDistanceKm: _distanceKm,
        initialSteps: _steps,
        initialPeeCount: _peeCount,
        initialPoopCount: _poopCount,
      );

      if (!metricsStarted) {
        throw Exception(
          'Unable to start live walk metrics.',
        );
      }

      if (_disposed) {
        return;
      }

      // --------------------------------------------------------
      // STEP 3
      // LOCAL STATE
      // --------------------------------------------------------

      _walkStarted = true;
      _walkCompleted = false;

      final Timestamp startTime =
          Timestamp.now();

      _sessionData =
          <String, dynamic>{
        ..._sessionData,
        'requestId': requestId,
        'sessionId': requestId,
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
                startTime,
      };

      debugPrint(
        '==================================================',
      );

      debugPrint(
        'LIVE WALK STARTED',
      );

      debugPrint(
        'requestId=$requestId',
      );

      debugPrint(
        'Counting=started',
      );

      debugPrint(
        'Distance=started',
      );

      debugPrint(
        'Steps=started',
      );

      debugPrint(
        'GPS=already running from Accept',
      );

      debugPrint(
        '==================================================',
      );

      notifyListeners();
    } catch (error) {
      debugPrint(
        'LiveWalkSessionController.startWalk: '
        '$error',
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
  // END / COMPLETE WALK
  //
  // GPS OFF ONLY HERE.
  // ============================================================

  Future<void> endWalk() async {
    if (_disposed) {
      return;
    }

    if (_endingWalk) {
      return;
    }

    if (_walkCompleted) {
      debugPrint(
        'Live walk already completed: '
        'requestId=$requestId',
      );
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
        'requestId=$requestId',
      );

      // ========================================================
      // STEP 1
      // COMPLETE FIRESTORE SESSION
      // ========================================================

      await _sessionService.completeWalk(
        requestId: requestId,
      );

      // ========================================================
      // STEP 2
      // STOP METRICS SERVICE
      //
      // IMPORTANT:
      // This does NOT stop GPS.
      // ========================================================

      await _backgroundService.stop();

      // ========================================================
      // STEP 3
      // GPS OFF
      //
      // THIS IS THE ONLY GPS OFF GUARD.
      // ========================================================

      await _locationService.stopTracking();

      if (_disposed) {
        return;
      }

      // ========================================================
      // STEP 4
      // LOCAL COMPLETED STATE
      // ========================================================

      final Timestamp completionTime =
          Timestamp.now();

      _walkStarted = false;
      _walkCompleted = true;

      _sessionData =
          <String, dynamic>{
        ..._sessionData,
        'requestId': requestId,
        'sessionId': requestId,
        'status': 'completed',
        'walkStarted': false,
        'trackingStarted': true,
        'trackingEnded': true,
        'walkEnded': true,
        'completedAt':
            _sessionData['completedAt'] ??
                completionTime,
        'endedAt':
            _sessionData['endedAt'] ??
                completionTime,
      };

      debugPrint(
        '==================================================',
      );

      debugPrint(
        'LIVE WALK COMPLETED SUCCESSFULLY',
      );

      debugPrint(
        'requestId=$requestId',
      );

      debugPrint(
        'status=completed',
      );

      debugPrint(
        'Metrics=stopped',
      );

      debugPrint(
        'GPS=OFF',
      );

      debugPrint(
        'Review can now be opened by LiveWalkScreen',
      );

      debugPrint(
        '==================================================',
      );

      notifyListeners();
    } catch (error) {
      debugPrint(
        'LiveWalkSessionController.endWalk: '
        '$error',
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

    // ----------------------------------------------------------
    // ACTIVE
    // ----------------------------------------------------------

    if (value == 'active' ||
        value == 'started' ||
        value == 'live') {
      if (!_walkCompleted &&
          !_walkStarted) {
        _walkStarted = true;
        notifyListeners();
      }

      return;
    }

    // ----------------------------------------------------------
    // COMPLETED
    // ----------------------------------------------------------

    if (value == 'completed' ||
        value == 'ended') {
      _walkStarted = false;
      _walkCompleted = true;

      notifyListeners();
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
    _walkCompleted = false;

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

    final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
        subscription =
        _sessionSubscription;

    _sessionSubscription = null;

    if (subscription != null) {
      unawaited(
        subscription.cancel(),
      );
    }

    // IMPORTANT:
    //
    // Do NOT stop GPS here.
    //
    // GPS lifecycle is controlled only by:
    // Accept -> ON
    // Complete -> OFF
    //
    super.dispose();
  }
}
