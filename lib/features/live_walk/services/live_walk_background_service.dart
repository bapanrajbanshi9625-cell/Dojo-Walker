import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import 'live_walk_firestore_service.dart';
import 'live_walk_gps_service.dart';
import 'live_walk_state.dart';

class LiveWalkBackgroundService {
  LiveWalkBackgroundService._();

  static final LiveWalkBackgroundService instance =
      LiveWalkBackgroundService._();

  // ============================================================
  // SERVICES
  // ============================================================

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final LiveWalkState _state = LiveWalkState();

  late final LiveWalkFirestoreService _firestoreService =
      LiveWalkFirestoreService();

  late final LiveWalkGpsService _gpsService = LiveWalkGpsService(
    onPosition: (Position position) {
      unawaited(_processPosition(position));
    },
  );

  // ============================================================
  // SYNC
  // ============================================================

  Timer? _syncTimer;

  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  Stream<Position> get locationStream => _locationController.stream;

  // ============================================================
  // STATE GETTERS
  // ============================================================

  bool get isRunning => _state.running;

  String? get walkId => _state.walkId;

  String? get sessionId => _state.sessionId;

  Position? get lastPosition => _state.lastPosition;

  List<Map<String, double>> get routeCoordinates =>
      List<Map<String, double>>.unmodifiable(
        _state.routeCoordinates,
      );

  double get totalDistanceKm => _state.totalDistanceKm;

  double get totalDistanceMeters => _state.totalDistanceMeters;

  int get steps => _state.steps;

  int get peeCount => _state.peeCount;

  int get poopCount => _state.poopCount;

  DateTime? get startedAt => _state.startedAt;

  int get durationSeconds => _state.durationSeconds;

  // ============================================================
  // START WALK
  // ============================================================

  Future<bool> start({
    required String walkId,
    required String sessionId,
    double initialDistanceKm = 0.0,
    int initialSteps = 0,
    int initialPeeCount = 0,
    int initialPoopCount = 0,
    DateTime? initialStartedAt,
    List<Map<String, dynamic>>? initialRoute,
  }) async {
    final String cleanWalkId = walkId.trim();
    final String cleanSessionId = sessionId.trim();

    if (cleanWalkId.isEmpty || cleanSessionId.isEmpty) {
      return false;
    }

    // ----------------------------------------------------------
    // ALREADY RUNNING
    // ----------------------------------------------------------

    if (_state.running) {
      if (_state.walkId == cleanWalkId &&
          _state.sessionId == cleanSessionId) {
        return true;
      }

      await stop();
    }

    // ----------------------------------------------------------
    // AUTH
    // ----------------------------------------------------------

    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    // ----------------------------------------------------------
    // GPS PERMISSION
    // ----------------------------------------------------------

    final bool permission = await _gpsService.ensurePermission();

    if (!permission) {
      return false;
    }

    // ----------------------------------------------------------
    // LOAD REAL LIVE WALK SESSION
    //
    // liveWalkSessions/{sessionId}
    // ----------------------------------------------------------

    final Map<String, dynamic>? sessionData =
        await _firestoreService.getSession(cleanSessionId);

    if (sessionData == null) {
      return false;
    }

    // ----------------------------------------------------------
    // VERIFY WALK ID
    // ----------------------------------------------------------

    final String sessionWalkId =
        sessionData['walkId']?.toString().trim() ?? '';

    if (sessionWalkId.isNotEmpty &&
        sessionWalkId != cleanWalkId) {
      return false;
    }

    // ----------------------------------------------------------
    // VERIFY WALKER
    // ----------------------------------------------------------

    final String sessionWalkerUid =
        sessionData['walkerUid']?.toString().trim() ?? '';

    if (sessionWalkerUid.isNotEmpty &&
        sessionWalkerUid != user.uid) {
      return false;
    }

    // ----------------------------------------------------------
    // INITIAL STATE
    // ----------------------------------------------------------

    _state.walkId = cleanWalkId;
    _state.sessionId = cleanSessionId;

    _state.totalDistanceKm =
        initialDistanceKm < 0 ? 0.0 : initialDistanceKm;

    _state.steps = initialSteps < 0 ? 0 : initialSteps;

    _state.peeCount =
        initialPeeCount < 0 ? 0 : initialPeeCount;

    _state.poopCount =
        initialPoopCount < 0 ? 0 : initialPoopCount;

    _state.startedAt =
        initialStartedAt ??
        _readDateTime(sessionData['startedAt']) ??
        DateTime.now();

    _state.lastPosition = null;

    _state.routeCoordinates.clear();

    // ----------------------------------------------------------
    // RESTORE PREVIOUS ROUTE
    // ----------------------------------------------------------

    _restoreRoute(
      initialRoute ??
          _readRoute(
            sessionData['routeCoordinates'],
          ),
    );

    _state.running = true;

    try {
      // --------------------------------------------------------
      // START GPS
      // --------------------------------------------------------

      final bool gpsStarted = await _gpsService.start();

      if (!gpsStarted) {
        _state.running = false;
        return false;
      }

      // --------------------------------------------------------
      // FIRST GPS FIX
      // --------------------------------------------------------

      final Position? firstPosition =
          await _gpsService.getCurrentPosition();

      if (_state.running && firstPosition != null) {
        await _processPosition(firstPosition);
      }

      // --------------------------------------------------------
      // PERIODIC FIRESTORE SYNC
      // --------------------------------------------------------

      _syncTimer?.cancel();

      _syncTimer = Timer.periodic(
        const Duration(seconds: 15),
        (_) {
          if (_state.running) {
            unawaited(_syncCurrentState());
          }
        },
      );

      // --------------------------------------------------------
      // INITIAL SYNC
      // --------------------------------------------------------

      unawaited(_syncCurrentState());

      return true;
    } catch (_) {
      _state.running = false;

      await _gpsService.stop();

      return false;
    }
  }

  // ============================================================
  // GPS PROCESSING
  // ============================================================

  Future<void> _processPosition(
    Position position,
  ) async {
    if (!_state.running) {
      return;
    }

    // ----------------------------------------------------------
    // VALID POSITION
    // ----------------------------------------------------------

    if (!_validCoordinate(
      position.latitude,
      position.longitude,
    )) {
      return;
    }

    // Ignore very inaccurate GPS points.
    if (position.accuracy > 100) {
      return;
    }

    final Position? previous = _state.lastPosition;

    // ----------------------------------------------------------
    // FIRST POSITION
    // ----------------------------------------------------------

    if (previous == null) {
      _state.lastPosition = position;

      _addRoutePoint(
        position,
        force: true,
      );

      if (!_locationController.isClosed) {
        _locationController.add(position);
      }

      await _writeLocation(position);

      return;
    }

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double meters = Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      position.latitude,
      position.longitude,
    );

    // Ignore impossible GPS jumps.
    if (meters > 500) {
      return;
    }

    if (meters >= 0.5) {
      _state.totalDistanceKm += meters / 1000.0;
    }

    // ----------------------------------------------------------
    // SAVE POSITION
    // ----------------------------------------------------------

    _state.lastPosition = position;

    // ----------------------------------------------------------
    // ROUTE
    // ----------------------------------------------------------

    _addRoutePoint(position);

    // ----------------------------------------------------------
    // LOCAL LOCATION STREAM
    // ----------------------------------------------------------

    if (!_locationController.isClosed) {
      _locationController.add(position);
    }

    // ----------------------------------------------------------
    // FIRESTORE
    // ----------------------------------------------------------

    await _writeLocation(position);
  }

  // ============================================================
  // ROUTE POINT
  // ============================================================

  void _addRoutePoint(
    Position position, {
    bool force = false,
  }) {
    final double lat = position.latitude;
    final double lng = position.longitude;

    if (!_validCoordinate(lat, lng)) {
      return;
    }

    final Map<String, double> point = <String, double>{
      'lat': lat,
      'lng': lng,
    };

    // First point.
    if (_state.routeCoordinates.isEmpty) {
      _state.routeCoordinates.add(point);
      return;
    }

    // Force point.
    if (force) {
      _state.routeCoordinates.add(point);
      return;
    }

    final Map<String, double> last =
        _state.routeCoordinates.last;

    final double meters = Geolocator.distanceBetween(
      last['lat']!,
      last['lng']!,
      lat,
      lng,
    );

    // Ignore GPS noise below 5m.
    if (meters < 5) {
      return;
    }

    _state.routeCoordinates.add(point);

    // Keep memory bounded.
    if (_state.routeCoordinates.length > 3000) {
      _state.routeCoordinates.removeRange(
        0,
        _state.routeCoordinates.length - 3000,
      );
    }
  }

  // ============================================================
  // FIRESTORE LOCATION WRITE
  // ============================================================

  Future<void> _writeLocation(
    Position position,
  ) async {
    if (!_state.running) {
      return;
    }

    final String? currentWalkId = _state.walkId;
    final String? currentSessionId = _state.sessionId;

    if (currentWalkId == null ||
        currentSessionId == null ||
        currentWalkId.isEmpty ||
        currentSessionId.isEmpty) {
      return;
    }

    final List<Map<String, double>> route =
        _state.routeCoordinates
            .map(
              (Map<String, double> point) => <String, double>{
                'lat': point['lat']!,
                'lng': point['lng']!,
              },
            )
            .toList();

    try {
      await _firestoreService.writeLocation(
        walkId: currentWalkId,
        sessionId: currentSessionId,
        position: position,
        route: route,
        distanceKm: _state.totalDistanceKm,
        steps: _state.steps,
        peeCount: _state.peeCount,
        poopCount: _state.poopCount,
        startedAt: _state.startedAt,
      );
    } catch (_) {
      // Firestore failure must not stop GPS tracking.
    }
  }

  // ============================================================
  // PERIODIC SYNC
  // ============================================================

  Future<void> _syncCurrentState() async {
    if (!_state.running) {
      return;
    }

    final Position? position = _state.lastPosition;

    if (position == null) {
      return;
    }

    await _writeLocation(position);
  }

  // ============================================================
  // STEPS
  // ============================================================

  void updateSteps(int value) {
    if (value < 0) {
      return;
    }

    _state.steps = value;

    if (_state.running) {
      unawaited(_syncCurrentState());
    }
  }

  // ============================================================
  // ACTIVITIES
  // ============================================================

  void updateActivities({
    int? peeCount,
    int? poopCount,
  }) {
    if (peeCount != null && peeCount >= 0) {
      _state.peeCount = peeCount;
    }

    if (poopCount != null && poopCount >= 0) {
      _state.poopCount = poopCount;
    }

    if (_state.running) {
      unawaited(_syncCurrentState());
    }
  }

  // ============================================================
  // RECOVER WALK
  // ============================================================

  Future<bool> recover({
    required String sessionId,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final String cleanSessionId = sessionId.trim();

    if (cleanSessionId.isEmpty) {
      return false;
    }

    try {
      // --------------------------------------------------------
      // LOAD SESSION
      // --------------------------------------------------------

      final Map<String, dynamic>? data =
          await _firestoreService.getSession(
        cleanSessionId,
      );

      if (data == null) {
        return false;
      }

      // --------------------------------------------------------
      // VERIFY WALKER
      // --------------------------------------------------------

      final String walkerUid =
          data['walkerUid']?.toString().trim() ?? '';

      if (walkerUid.isNotEmpty &&
          walkerUid != user.uid) {
        return false;
      }

      // --------------------------------------------------------
      // WALK ID
      // --------------------------------------------------------

      final String recoveredWalkId =
          data['walkId']?.toString().trim() ?? '';

      if (recoveredWalkId.isEmpty) {
        return false;
      }

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      final String status =
          data['status']?.toString().trim().toLowerCase() ?? '';

      if (status == 'completed' ||
          status == 'ended') {
        return false;
      }

      // --------------------------------------------------------
      // RESTORE EVERYTHING
      // --------------------------------------------------------

      return start(
        walkId: recoveredWalkId,
        sessionId: cleanSessionId,
        initialDistanceKm:
            _toDouble(data['distanceKm']) ?? 0.0,
        initialSteps:
            _toInt(data['steps']) ?? 0,
        initialPeeCount:
            _toInt(data['peeCount']) ?? 0,
        initialPoopCount:
            _toInt(data['poopCount']) ?? 0,
        initialStartedAt:
            _readDateTime(data['startedAt']),
        initialRoute:
            _readRoute(data['routeCoordinates']),
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // CURRENT SESSION DATA
  // ============================================================

  Map<String, dynamic> getCurrentSessionData() {
    final Position? position = _state.lastPosition;

    return <String, dynamic>{
      'walkId': _state.walkId,
      'sessionId': _state.sessionId,

      'currentLocation': position == null
          ? null
          : <String, double>{
              'lat': position.latitude,
              'lng': position.longitude,
            },

      'currentLat': position?.latitude,
      'currentLng': position?.longitude,

      'distanceKm': _state.totalDistanceKm,
      'distanceMeters': _state.totalDistanceMeters,

      'durationSeconds': _state.durationSeconds,

      'steps': _state.steps,
      'peeCount': _state.peeCount,
      'poopCount': _state.poopCount,

      'startedAt': _state.startedAt,

      'startLocation':
          _state.routeCoordinates.isNotEmpty
              ? _state.routeCoordinates.first
              : null,

      'routeCoordinates':
          List<Map<String, double>>.from(
        _state.routeCoordinates,
      ),

      'routePointCount':
          _state.routeCoordinates.length,

      'status': _state.running ? 'active' : 'stopped',
    };
  }

  // ============================================================
  // RESTORE ROUTE
  // ============================================================

  void _restoreRoute(
    List<Map<String, dynamic>> route,
  ) {
    for (final Map<String, dynamic> item in route) {
      final double? lat = _toDouble(
        item['lat'] ?? item['latitude'],
      );

      final double? lng = _toDouble(
        item['lng'] ??
            item['longitude'] ??
            item['lon'],
      );

      if (lat == null ||
          lng == null ||
          !_validCoordinate(lat, lng)) {
        continue;
      }

      final Map<String, double> point = <String, double>{
        'lat': lat,
        'lng': lng,
      };

      if (_state.routeCoordinates.isEmpty) {
        _state.routeCoordinates.add(point);
        continue;
      }

      final Map<String, double> last =
          _state.routeCoordinates.last;

      final double meters = Geolocator.distanceBetween(
        last['lat']!,
        last['lng']!,
        lat,
        lng,
      );

      if (meters >= 5) {
        _state.routeCoordinates.add(point);
      }
    }

    if (_state.routeCoordinates.length > 3000) {
      _state.routeCoordinates.removeRange(
        0,
        _state.routeCoordinates.length - 3000,
      );
    }
  }

  // ============================================================
  // READ ROUTE
  // ============================================================

  List<Map<String, dynamic>> _readRoute(
    dynamic rawRoute,
  ) {
    final List<Map<String, dynamic>> result =
        <Map<String, dynamic>>[];

    if (rawRoute is! List) {
      return result;
    }

    for (final dynamic item in rawRoute) {
      if (item is Map) {
        result.add(
          Map<String, dynamic>.from(item),
        );
      }
    }

    return result;
  }

  // ============================================================
  // DATE
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

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double? _toDouble(
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

  int? _toInt(
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
  // VALID COORDINATE
  // ============================================================

  bool _validCoordinate(
    double lat,
    double lng,
  ) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }

  // ============================================================
  // STOP
  //
  // IMPORTANT:
  // This only stops local GPS tracking.
  //
  // It does NOT:
  // - delete the session
  // - delete the route
  // - modify walk_requests
  // - modify active_walks
  // ============================================================

  Future<void> stop() async {
    _state.running = false;

    _syncTimer?.cancel();
    _syncTimer = null;

    await _gpsService.stop();

    _state.reset();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stop();

    if (!_locationController.isClosed) {
      await _locationController.close();
    }
  }
}
