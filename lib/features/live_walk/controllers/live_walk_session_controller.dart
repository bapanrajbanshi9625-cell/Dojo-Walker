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

  /// REAL FIRESTORE DOCUMENT:
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

  double _distanceKm = 0.0;
  int _steps = 0;

  int _peeCount = 0;
  int _poopCount = 0;

  Map<String, dynamic> _sessionData = <String, dynamic>{};

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _sessionSubscription;

  Timer? _liveStatsTimer;

  DateTime? _startedAtLocal;

  Duration _elapsedDuration = Duration.zero;

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

  Duration get elapsedDuration => _elapsedDuration;

  Map<String, dynamic> get sessionData =>
      Map<String, dynamic>.unmodifiable(_sessionData);

  // ============================================================
  // TIMELINE
  // ============================================================

  dynamic get createdAt => _sessionData['createdAt'];

  dynamic get acceptedAt => _sessionData['acceptedAt'];

  dynamic get reachedAt => _sessionData['reachedAt'];

  dynamic get startedAt => _sessionData['startedAt'];

  dynamic get completedAt => _sessionData['completedAt'];

  dynamic get endedAt => _sessionData['endedAt'];

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

  DocumentReference<Map<String, dynamic>> get sessionRef {
    return _sessionService.sessionRef(sessionId);
  }

  // ============================================================
  // SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>> get sessionStream {
    return sessionRef.snapshots();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    try {
      debugPrint(
        'LiveWalkSessionController.initialize '
        'walkId=$walkId '
        'sessionId=$sessionId',
      );

      await _sessionSubscription?.cancel();
      _sessionSubscription = null;

      // --------------------------------------------------------
      // FIRST SNAPSHOT
      // --------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await sessionRef.get();

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() ?? <String, dynamic>{};

        if (data.isNotEmpty) {
          updateFromSession(data);
        }
      } else {
        debugPrint(
          'Live session not found: '
          'liveWalkSessions/$sessionId',
        );
      }

      // --------------------------------------------------------
      // REAL-TIME STREAM
      // --------------------------------------------------------

      _sessionSubscription = sessionStream.listen(
        (
          DocumentSnapshot<Map<String, dynamic>> snapshot,
        ) {
          if (!snapshot.exists) {
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
          debugPrint(
            'LiveWalk session stream error: $error',
          );
        },
        cancelOnError: false,
      );
    } catch (error) {
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
    if (data.isEmpty) {
      return;
    }

    _sessionData = Map<String, dynamic>.from(data);

    // ----------------------------------------------------------
    // DISTANCE
    //
    // While walking, local background GPS is the live source.
    // Firestore remains the persistent/sync source.
    // ----------------------------------------------------------

    final double? firestoreDistance =
        _readDouble(data['distanceKm']);

    final double backgroundDistance =
        _backgroundService.totalDistanceKm;

    if (_walkStarted) {
      if (backgroundDistance >= 0) {
        _distanceKm = backgroundDistance;
      } else if (firestoreDistance != null &&
          firestoreDistance >= 0) {
        _distanceKm = firestoreDistance;
      }
    } else {
      if (firestoreDistance != null &&
          firestoreDistance >= 0) {
        _distanceKm = firestoreDistance;
      } else if (backgroundDistance >= 0) {
        _distanceKm = backgroundDistance;
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

    final int backgroundSteps =
        _backgroundService.steps;

    if (_walkStarted &&
        backgroundSteps >= 0 &&
        backgroundSteps > _steps) {
      _steps = backgroundSteps;
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
        data['status']?.toString().trim().toLowerCase() ?? '';

    final bool firestoreWalkStarted =
        data['walkStarted'] == true;

    final bool trackingStarted =
        data['trackingStarted'] == true;

    final bool walkEnded =
        data['walkEnded'] == true;

    final bool active =
        status == 'active' ||
        status == 'started' ||
        status == 'live' ||
        firestoreWalkStarted ||
        trackingStarted;

    final bool completed =
        status == 'completed' ||
        status == 'ended' ||
        walkEnded;

    if (completed) {
      _walkStarted = false;
      _stopLiveStatsTimer();

      _restoreCompletedDuration(data);
    } else if (active) {
      _walkStarted = true;

      _restoreStartedAt(data);

      _startLiveStatsTimer();
      _updateLiveStats();
    }

    debugPrint(
      'LiveWalk timeline: '
      'walkId=$walkId '
      'sessionId=$sessionId '
      'status=$status '
      'createdAt=${data['createdAt']} '
      'acceptedAt=${data['acceptedAt']} '
      'reachedAt=${data['reachedAt']} '
      'startedAt=${data['startedAt']} '
      'completedAt=${data['completedAt']} '
      'endedAt=${data['endedAt']} '
      'distanceKm=$_distanceKm '
      'steps=$_steps '
      'duration=${_elapsedDuration.inSeconds}s',
    );

    notifyListeners();
  }

  // ============================================================
  // RESTORE START TIME
  // ============================================================

  void _restoreStartedAt(
    Map<String, dynamic> data,
  ) {
    final DateTime? firestoreStart =
        _readDateTime(data['startedAt']);

    if (firestoreStart != null) {
      _startedAtLocal = firestoreStart;
      return;
    }

    if (_startedAtLocal == null) {
      _startedAtLocal = DateTime.now();
    }
  }

  // ============================================================
  // RESTORE COMPLETED DURATION
  // ============================================================

  void _restoreCompletedDuration(
    Map<String, dynamic> data,
  ) {
    final int? durationSeconds =
        _readInt(data['durationSeconds']);

    if (durationSeconds != null &&
        durationSeconds >= 0) {
      _elapsedDuration =
          Duration(seconds: durationSeconds);

      return;
    }

    final int? durationMinutes =
        _readInt(data['durationMinutes']);

    if (durationMinutes != null &&
        durationMinutes >= 0) {
      _elapsedDuration =
          Duration(minutes: durationMinutes);

      return;
    }

    final DateTime? start =
        _readDateTime(data['startedAt']);

    final DateTime? end =
        _readDateTime(
          data['completedAt'] ??
              data['endedAt'],
        );

    if (start != null && end != null) {
      final Duration duration =
          end.difference(start);

      if (!duration.isNegative) {
        _elapsedDuration = duration;
      }
    }
  }

  // ============================================================
  // START LIVE TIMER
  // ============================================================

  void _startLiveStatsTimer() {
    if (_liveStatsTimer != null) {
      return;
    }

    _liveStatsTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        _updateLiveStats();
      },
    );
  }

  // ============================================================
  // STOP LIVE TIMER
  // ============================================================

  void _stopLiveStatsTimer() {
    _liveStatsTimer?.cancel();
    _liveStatsTimer = null;
  }

  // ============================================================
  // UPDATE LIVE STATS
  // ============================================================

  void _updateLiveStats() {
    if (!_walkStarted) {
      return;
    }

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double backgroundDistance =
        _backgroundService.totalDistanceKm;

    if (backgroundDistance >= 0) {
      _distanceKm = backgroundDistance;
    }

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final int backgroundSteps =
        _backgroundService.steps;

    if (backgroundSteps >= 0) {
      _steps = backgroundSteps;
    }

    // ----------------------------------------------------------
    // DURATION
    // ----------------------------------------------------------

    final DateTime? start =
        _startedAtLocal;

    if (start != null) {
      final Duration elapsed =
          DateTime.now().difference(start);

      if (!elapsed.isNegative) {
        _elapsedDuration = elapsed;
      }
    }

    notifyListeners();
  }

  // ============================================================
  // PUBLIC DISTANCE SYNC
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
  // ACTIVITY UPDATE
  // ============================================================

  void updateActivities({
    int? peeCount,
    int? poopCount,
  }) {
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
    if (value < 0) {
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
    if (_walkStarted ||
        _startingWalk ||
        _endingWalk) {
      return;
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
      // FIRESTORE START
      // --------------------------------------------------------

      await _sessionService.startWalk(
        sessionId: sessionId,
        walkId: walkId,
        ownerUid: ownerUid,
        ownerName: ownerName,
        dogName: dogName,
        dogBreed: dogBreed,
      );

      // --------------------------------------------------------
      // LOCAL START TIME
      // --------------------------------------------------------

      _startedAtLocal = DateTime.now();
      _elapsedDuration = Duration.zero;

      // --------------------------------------------------------
      // BACKGROUND GPS
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
        'startedAt': Timestamp.fromDate(
          _startedAtLocal!,
        ),
      };

      // --------------------------------------------------------
      // LIVE TIMER
      // --------------------------------------------------------

      _startLiveStatsTimer();

      notifyListeners();

      debugPrint(
        'Live walk started successfully '
        'sessionId=$sessionId '
        'startedAt=$_startedAtLocal',
      );
    } catch (error) {
      debugPrint(
        'LiveWalkSessionController.startWalk: $error',
      );

      rethrow;
    } finally {
      _startingWalk = false;

      notifyListeners();
    }
  }

  // ============================================================
  // END WALK
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
      debugPrint(
        'Completing live walk '
        'walkId=$walkId '
        'sessionId=$sessionId',
      );

      // --------------------------------------------------------
      // FINAL LIVE STATS
      // --------------------------------------------------------

      _updateLiveStats();

      final double finalDistance =
          _backgroundService.totalDistanceKm;

      if (finalDistance >= 0) {
        _distanceKm = finalDistance;
      }

      final int finalSteps =
          _backgroundService.steps;

      if (finalSteps >= 0) {
        _steps = finalSteps;
      }

      final Duration finalDuration =
          _elapsedDuration;

      // --------------------------------------------------------
      // STOP LIVE TIMER
      // --------------------------------------------------------

      _stopLiveStatsTimer();

      // --------------------------------------------------------
      // COMPLETE FIRESTORE SESSION
      // --------------------------------------------------------

      await _sessionService.completeWalk(
        sessionId: sessionId,
        walkId: walkId,
      );

      // --------------------------------------------------------
      // STOP BACKGROUND GPS
      // --------------------------------------------------------

      _backgroundService.stop();

      // --------------------------------------------------------
      // LOCAL STATE
      // --------------------------------------------------------

      _walkStarted = false;

      _elapsedDuration = finalDuration;

      _sessionData = <String, dynamic>{
        ..._sessionData,
        'sessionId': sessionId,
        'walkId': walkId,
        'status': 'completed',
        'walkStarted': false,
        'trackingStarted': true,
        'trackingEnded': true,
        'walkEnded': true,
        'distanceKm': _distanceKm,
        'steps': _steps,
        'durationSeconds':
            finalDuration.inSeconds,
        'durationMinutes':
            finalDuration.inMinutes,
        'completedAt':
            Timestamp.now(),
        'endedAt':
            Timestamp.now(),
      };

      debugPrint(
        'Live walk completed: '
        'liveWalkSessions/$sessionId '
        'distanceKm=$_distanceKm '
        'steps=$_steps '
        'durationSeconds=${finalDuration.inSeconds}',
      );
    } catch (error) {
      debugPrint(
        'LiveWalkSessionController.endWalk: $error',
      );

      rethrow;
    } finally {
      _endingWalk = false;

      notifyListeners();
    }
  }

  // ============================================================
  // FIRESTORE STATUS
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
        _restoreStartedAt(_sessionData);
        _startLiveStatsTimer();
        notifyListeners();
      }

      return;
    }

    if (value == 'completed' ||
        value == 'ended') {
      if (_walkStarted) {
        _walkStarted = false;
        _stopLiveStatsTimer();
        notifyListeners();
      }
    }
  }

  // ============================================================
  // TIMELINE FLAGS
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
    _stopLiveStatsTimer();

    _walkStarted = false;
    _startingWalk = false;
    _endingWalk = false;

    _distanceKm = 0.0;
    _steps = 0;

    _peeCount = 0;
    _poopCount = 0;

    _startedAtLocal = null;
    _elapsedDuration = Duration.zero;

    _sessionData = <String, dynamic>{};

    notifyListeners();
  }

  // ============================================================
  // READ DATETIME
  // ============================================================

  DateTime? _readDateTime(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is int) {
      // Supports millisecondsSinceEpoch.
      return DateTime.fromMillisecondsSinceEpoch(
        value,
      );
    }

    if (value is String) {
      return DateTime.tryParse(
        value.trim(),
      );
    }

    return null;
  }

  // ============================================================
  // READ DOUBLE
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
  // READ INT
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
    _stopLiveStatsTimer();

    final StreamSubscription<
        DocumentSnapshot<Map<String, dynamic>>>?
        subscription = _sessionSubscription;

    _sessionSubscription = null;

    if (subscription != null) {
      unawaited(subscription.cancel());
    }

    super.dispose();
  }
}
