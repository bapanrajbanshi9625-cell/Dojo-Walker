import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/live_walk_session_service.dart';
import '../../../services/walker_availability_service.dart';
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

  /// Global availability service owns GPS lifecycle.
  ///
  /// ACCEPT  -> availability remains Online
  /// START   -> GPS untouched
  /// REACHED -> GPS untouched
  /// LIVE    -> GPS untouched
  /// COMPLETE -> active walk released + global Offline
  ///
  /// This controller NEVER calls startTracking/stopTracking
  /// directly on WalkerLocationService.
  final WalkerAvailabilityService _availabilityService =
      WalkerAvailabilityService.instance;

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

  Position? _currentPosition;

  Map<String, dynamic> _sessionData =
      <String, dynamic>{};

  StreamSubscription<
          DocumentSnapshot<Map<String, dynamic>>>?
      _sessionSubscription;

  StreamSubscription<Position>?
      _locationSubscription;

  Timer? _uiTicker;

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

  Position? get currentPosition =>
      _currentPosition;

  bool get hasCurrentPosition =>
      _currentPosition != null;

  Map<String, dynamic> get sessionData =>
      Map<String, dynamic>.unmodifiable(
        _sessionData,
      );

  // ============================================================
  // SESSION TIMELINE
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
  // LIVE DURATION
  // ============================================================

  DateTime? get liveStartedAt {
    final dynamic value =
        _sessionData['startedAt'];

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  int get durationSeconds {
    final DateTime? start =
        liveStartedAt;

    if (start == null) {
      return 0;
    }

    final int seconds =
        DateTime.now()
            .difference(start)
            .inSeconds;

    return seconds < 0 ? 0 : seconds;
  }

  int get durationMinutes {
    return durationSeconds ~/ 60;
  }

  String get formattedDuration {
    final int totalSeconds =
        durationSeconds;

    final int minutes =
        totalSeconds ~/ 60;

    final int seconds =
        totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

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
        (_sessionData['status']
                    ?.toString() ??
                '')
            .trim()
            .toLowerCase();

    return status == 'reached' ||
        status == 'arrived' ||
        status == 'ready';
  }

  // ============================================================
  // GPS READY
  //
  // This only reads session data.
  // It does NOT control GPS.
  // ============================================================

  bool get gpsReady {
    final dynamic location =
        _sessionData['currentLocation'];

    if (location is GeoPoint) {
      return location.latitude != 0 ||
          location.longitude != 0;
    }

    if (location is Map) {
      final double? lat =
          _readDouble(
        location['lat'] ??
            location['latitude'],
      );

      final double? lng =
          _readDouble(
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

  DocumentReference<Map<String, dynamic>>
      get sessionRef {
    return _sessionService.sessionRef(
      requestId,
    );
  }

  // ============================================================
  // FIRESTORE SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get sessionStream {
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
      await _locationSubscription?.cancel();

      _sessionSubscription = null;
      _locationSubscription = null;

      if (_disposed) {
        return;
      }

      final DocumentSnapshot<
              Map<String, dynamic>> snapshot =
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
      // START LISTENING TO GLOBAL GPS STREAM
      //
      // IMPORTANT:
      // This only listens.
      // It does NOT start or stop GPS.
      // --------------------------------------------------------

      _listenToWalkerLocation();

      _sessionSubscription =
          sessionStream.listen(
        (
          DocumentSnapshot<
                  Map<String, dynamic>> snapshot,
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
  // GLOBAL WALKER LOCATION LISTENER
  //
  // WalkerLocationService is the canonical GPS source.
  //
  // This controller only consumes its stream.
  // ============================================================

  void _listenToWalkerLocation() {
    if (_disposed) {
      return;
    }

    _locationSubscription?.cancel();

    _locationSubscription =
        _availabilityService.locationStream.listen(
      (Position position) {
        if (_disposed) {
          return;
        }

        if (!_availabilityService.isOnline) {
          return;
        }

        final double latitude =
            position.latitude;

        final double longitude =
            position.longitude;

        final double accuracy =
            position.accuracy;

        if (!latitude.isFinite ||
            !longitude.isFinite ||
            !accuracy.isFinite) {
          return;
        }

        if (latitude == 0.0 &&
            longitude == 0.0) {
          return;
        }

        _currentPosition = position;

        // ------------------------------------------------------
        // UPDATE LOCAL SESSION DATA
        //
        // This makes the Live Walk UI react immediately to
        // every new GPS position.
        // ------------------------------------------------------

        _sessionData =
            <String, dynamic>{
          ..._sessionData,
          'currentLocation': GeoPoint(
            latitude,
            longitude,
          ),
          'walkerLatitude': latitude,
          'walkerLongitude': longitude,
          'locationAccuracy': accuracy,
          'locationUpdatedAt':
              Timestamp.now(),
        };

        debugPrint(
          'LiveWalk GPS UI Update: '
          'requestId=$requestId '
          'lat=$latitude '
          'lng=$longitude '
          'accuracy=${accuracy}m',
        );

        // ------------------------------------------------------
        // FIRESTORE SYNC
        //
        // Latest walker position is written to the canonical
        // liveWalkSessions document so the owner/admin live
        // map can also receive the moving position.
        //
        // GPS itself is NOT controlled here.
        // ------------------------------------------------------

        unawaited(
          _syncCurrentLocationToFirestore(
            position,
          ),
        );

        notifyListeners();
      },
      onError: (Object error) {
        if (_disposed) {
          return;
        }

        debugPrint(
          'LiveWalk GPS location stream error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // FIRESTORE CURRENT LOCATION
  // ============================================================

  Future<void> _syncCurrentLocationToFirestore(
    Position position,
  ) async {
    if (_disposed) {
      return;
    }

    try {
      await sessionRef.update(
        <String, dynamic>{
          'currentLocation': GeoPoint(
            position.latitude,
            position.longitude,
          ),
          'walkerLatitude':
              position.latitude,
          'walkerLongitude':
              position.longitude,
          'locationAccuracy':
              position.accuracy,
          'locationUpdatedAt':
              FieldValue.serverTimestamp(),
        },
      );
    } catch (error) {
      if (_disposed) {
        return;
      }

      debugPrint(
        'LiveWalk current location Firestore sync '
        'failed: $error',
      );
    }
  }

  // ============================================================
  // LIVE UI TICKER
  // ============================================================

  void _startUiTicker() {
    _uiTicker?.cancel();

    if (!_walkStarted || _disposed) {
      return;
    }

    _uiTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (_disposed || !_walkStarted) {
          return;
        }

        _syncLocalMetrics();

        notifyListeners();
      },
    );
  }

  void _stopUiTicker() {
    _uiTicker?.cancel();
    _uiTicker = null;
  }

  // ============================================================
  // LOCAL METRICS SYNC
  // ============================================================

  void _syncLocalMetrics() {
    if (_disposed) {
      return;
    }

    final double localDistance =
        _backgroundService.totalDistanceKm;

    if (localDistance >= 0 &&
        localDistance > _distanceKm) {
      _distanceKm = localDistance;
    }

    final int localSteps =
        _backgroundService.steps;

    if (localSteps >= 0 &&
        localSteps > _steps) {
      _steps = localSteps;
    }

    final int localPee =
        _backgroundService.peeCount;

    if (localPee >= 0 &&
        localPee > _peeCount) {
      _peeCount = localPee;
    }

    final int localPoop =
        _backgroundService.poopCount;

    if (localPoop >= 0 &&
        localPoop > _poopCount) {
      _poopCount = localPoop;
    }

    _sessionData =
        <String, dynamic>{
      ..._sessionData,
      'distanceKm': _distanceKm,
      'steps': _steps,
      'peeCount': _peeCount,
      'poopCount': _poopCount,
    };
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

    final Map<String, dynamic> previousData =
        _sessionData;

    _sessionData =
        Map<String, dynamic>.from(data);

    // ----------------------------------------------------------
    // RESTORE CURRENT LOCATION
    // ----------------------------------------------------------

    final dynamic firestoreLocation =
        data['currentLocation'];

    if (firestoreLocation is GeoPoint) {
      _currentPosition = _positionFromGeoPoint(
        firestoreLocation,
      );
    }

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double? firestoreDistance =
        _readDouble(
      data['distanceKm'],
    );

    final double localDistance =
        _backgroundService.totalDistanceKm;

    if (localDistance >= 0 &&
        localDistance > _distanceKm) {
      _distanceKm = localDistance;
    }

    if (firestoreDistance != null &&
        firestoreDistance >= 0 &&
        firestoreDistance > _distanceKm) {
      _distanceKm = firestoreDistance;
    }

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final int? firestoreSteps =
        _readInt(
      data['steps'],
    );

    final int localSteps =
        _backgroundService.steps;

    if (localSteps >= 0 &&
        localSteps > _steps) {
      _steps = localSteps;
    }

    if (firestoreSteps != null &&
        firestoreSteps >= 0 &&
        firestoreSteps > _steps) {
      _steps = firestoreSteps;
    }

    // ----------------------------------------------------------
    // PEE
    // ----------------------------------------------------------

    final int? firestorePee =
        _readInt(
      data['peeCount'],
    );

    final int localPee =
        _backgroundService.peeCount;

    if (localPee >= 0 &&
        localPee > _peeCount) {
      _peeCount = localPee;
    }

    if (firestorePee != null &&
        firestorePee >= 0 &&
        firestorePee > _peeCount) {
      _peeCount = firestorePee;
    }

    // ----------------------------------------------------------
    // POOP
    // ----------------------------------------------------------

    final int? firestorePoop =
        _readInt(
      data['poopCount'],
    );

    final int localPoop =
        _backgroundService.poopCount;

    if (localPoop >= 0 &&
        localPoop > _poopCount) {
      _poopCount = localPoop;
    }

    if (firestorePoop != null &&
        firestorePoop >= 0 &&
        firestorePoop > _poopCount) {
      _poopCount = firestorePoop;
    }

    // ----------------------------------------------------------
    // KEEP LIVE VALUES IN LOCAL SESSION DATA
    // ----------------------------------------------------------

    _sessionData =
        <String, dynamic>{
      ..._sessionData,
      'distanceKm': _distanceKm,
      'steps': _steps,
      'peeCount': _peeCount,
      'poopCount': _poopCount,
    };

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

      _stopUiTicker();
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

      _startUiTicker();
    }

    // ----------------------------------------------------------
    // OTHER
    // ----------------------------------------------------------

    else {
      _walkStarted = false;
      _stopUiTicker();
    }

    debugPrint(
      'LiveWalk timeline: '
      'requestId=$requestId '
      'status=$status '
      'walkStarted=$_walkStarted '
      'completed=$_walkCompleted '
      'distance=$_distanceKm '
      'steps=$_steps '
      'pee=$_peeCount '
      'poop=$_poopCount '
      'startedAt=${data['startedAt']} '
      'completedAt=${data['completedAt']}',
    );

    if (previousData.isEmpty &&
        _sessionData.isNotEmpty) {
      // Initial session state received.
    }

    notifyListeners();
  }

  // ============================================================
  // POSITION FROM GEOPOINT
  //
  // Used only to restore a Firestore location into the
  // controller's local Position state.
  // ============================================================

  Position _positionFromGeoPoint(
    GeoPoint point,
  ) {
    return Position(
      latitude: point.latitude,
      longitude: point.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
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

    if (distance > _distanceKm) {
      _distanceKm = distance;

      _sessionData =
          <String, dynamic>{
        ..._sessionData,
        'distanceKm': _distanceKm,
      };

      notifyListeners();
    }
  }

  // ============================================================
  // RECORD DOG ACTIVITY
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

    // ----------------------------------------------------------
    // LOCAL OPTIMISTIC INCREMENT
    // ----------------------------------------------------------

    if (field == 'peeCount') {
      _peeCount++;
    } else {
      _poopCount++;
    }

    _sessionData =
        <String, dynamic>{
      ..._sessionData,
      field: field == 'peeCount'
          ? _peeCount
          : _poopCount,
    };

    notifyListeners();

    try {
      await sessionRef.update(
        <String, dynamic>{
          field: FieldValue.increment(1),
        },
      );

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
      if (!_disposed) {
        if (field == 'peeCount') {
          if (_peeCount > 0) {
            _peeCount--;
          }
        } else {
          if (_poopCount > 0) {
            _poopCount--;
          }
        }

        _sessionData =
            <String, dynamic>{
          ..._sessionData,
          field: field == 'peeCount'
              ? _peeCount
              : _poopCount,
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
        peeCount >= _peeCount) {
      _peeCount = peeCount;
    }

    if (poopCount != null &&
        poopCount >= _poopCount) {
      _poopCount = poopCount;
    }

    _sessionData =
        <String, dynamic>{
      ..._sessionData,
      'peeCount': _peeCount,
      'poopCount': _poopCount,
    };

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

    if (value < _steps) {
      return;
    }

    _steps = value;

    _sessionData =
        <String, dynamic>{
      ..._sessionData,
      'steps': _steps,
    };

    notifyListeners();

    _backgroundService.updateSteps(
      value,
    );
  }

  // ============================================================
  // START WALK
  //
  // GPS IS NOT STARTED HERE.
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

    if (!reached) {
      throw Exception(
        'Please reach the owner before starting the walk.',
      );
    }

    // ----------------------------------------------------------
    // GLOBAL ONLINE GUARD
    // ----------------------------------------------------------

    if (!_availabilityService.isOnline) {
      throw Exception(
        'You must be Online to start the walk.',
      );
    }

    if (!_availabilityService.canPerformWalkAction()) {
      throw Exception(
        _availabilityService.unavailableMessage,
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
      // MARK FIRESTORE SESSION ACTIVE
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
      // START METRICS
      //
      // IMPORTANT:
      // This does NOT start GPS.
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
      // LOCAL ACTIVE STATE
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
        'distanceKm': _distanceKm,
        'steps': _steps,
        'peeCount': _peeCount,
        'poopCount': _poopCount,
      };

      // Keep the latest GPS position available immediately.
      if (_currentPosition != null) {
        _sessionData =
            <String, dynamic>{
          ..._sessionData,
          'currentLocation': GeoPoint(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          ),
        };
      }

      _startUiTicker();

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
        'GPS=controlled globally by availability',
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
  // GPS lifecycle is delegated to the global availability
  // service.
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

      // --------------------------------------------------------
      // STEP 1
      // COMPLETE FIRESTORE
      // --------------------------------------------------------

      await _sessionService.completeWalk(
        requestId: requestId,
      );

      // --------------------------------------------------------
      // STEP 2
      // STOP WALK METRICS
      //
      // IMPORTANT:
      // Background metrics service is separate from GPS.
      // --------------------------------------------------------

      await _backgroundService.stop();

      // --------------------------------------------------------
      // STEP 3
      // RELEASE ACTIVE WALK
      //
      // This unlocks the global Online/Offline control.
      // --------------------------------------------------------

      await _availabilityService.setActiveWalk(false);

      // --------------------------------------------------------
      // STEP 4
      // GLOBAL OFFLINE
      //
      // WalkerAvailabilityService owns the actual GPS stop.
      //
      // No direct WalkerLocationService.stopTracking().
      // --------------------------------------------------------

      try {
        await _availabilityService.goOffline();
      } catch (error) {
        debugPrint(
          'Unable to switch Walker Offline after completion: '
          '$error',
        );
      }

      if (_disposed) {
        return;
      }

      _stopUiTicker();

      // --------------------------------------------------------
      // STEP 5
      // COMPLETED
      // --------------------------------------------------------

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
        'distanceKm': _distanceKm,
        'steps': _steps,
        'peeCount': _peeCount,
        'poopCount': _poopCount,
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
        'GPS=delegated to global availability',
      );

      debugPrint(
        'Availability=Offline',
      );

      debugPrint(
        'Distance=$_distanceKm',
      );

      debugPrint(
        'Steps=$_steps',
      );

      debugPrint(
        'Pee=$_peeCount',
      );

      debugPrint(
        'Poop=$_poopCount',
      );

      debugPrint(
        'Duration=$formattedDuration',
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

    if (value == 'active' ||
        value == 'started' ||
        value == 'live') {
      if (!_walkCompleted &&
          !_walkStarted) {
        _walkStarted = true;
        _startUiTicker();
        notifyListeners();
      }

      return;
    }

    if (value == 'completed' ||
        value == 'ended') {
      _walkStarted = false;
      _walkCompleted = true;
      _stopUiTicker();

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

    _stopUiTicker();

    _walkStarted = false;
    _startingWalk = false;
    _endingWalk = false;
    _walkCompleted = false;

    _distanceKm = 0.0;
    _steps = 0;

    _peeCount = 0;
    _poopCount = 0;

    _currentPosition = null;

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

    _stopUiTicker();

    final StreamSubscription<
            DocumentSnapshot<Map<String, dynamic>>>?
        sessionSubscription =
        _sessionSubscription;

    _sessionSubscription = null;

    if (sessionSubscription != null) {
      unawaited(
        sessionSubscription.cancel(),
      );
    }

    final StreamSubscription<Position>?
        locationSubscription =
        _locationSubscription;

    _locationSubscription = null;

    if (locationSubscription != null) {
      unawaited(
        locationSubscription.cancel(),
      );
    }

    // IMPORTANT:
    //
    // No GPS stop here.
    //
    // Controller disposal/navigation must never accidentally
    // kill global GPS tracking during an active walk.
    //
    // GPS is controlled by WalkerAvailabilityService only.

    super.dispose();
  }
}
