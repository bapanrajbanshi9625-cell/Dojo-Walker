import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// ============================================================
/// DOJO WALKER
/// LIVE WALK BACKGROUND SERVICE
///
/// PRIMARY RECORD:
/// liveWalkSessions/{sessionId}
///
/// IMPORTANT:
/// - Route starts from the first valid GPS point after Start Walk.
/// - Every meaningful movement is added to routeCoordinates.
/// - Route remains stored in Firestore until the walk is completed.
/// - This service does NOT use active_walk / active_walks.
/// - This service does NOT modify walk_requests.
/// - sessionId MUST be the real liveWalkSessions document ID.
/// ============================================================

class LiveWalkBackgroundService {
  LiveWalkBackgroundService._();

  static final LiveWalkBackgroundService instance =
      LiveWalkBackgroundService._();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  // ============================================================
  // GPS
  // ============================================================

  StreamSubscription<Position>? _positionSubscription;

  Timer? _syncTimer;

  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  Stream<Position> get locationStream =>
      _locationController.stream;

  // ============================================================
  // CURRENT WALK
  // ============================================================

  String? _walkId;
  String? _sessionId;

  bool _running = false;

  bool get isRunning => _running;

  String? get walkId => _walkId;

  String? get sessionId => _sessionId;

  // ============================================================
  // LOCATION
  // ============================================================

  Position? _lastPosition;

  Position? get lastPosition => _lastPosition;

  // ============================================================
  // ROUTE
  // ============================================================

  final List<Map<String, double>> _routeCoordinates =
      <Map<String, double>>[];

  List<Map<String, double>> get routeCoordinates =>
      List<Map<String, double>>.unmodifiable(
        _routeCoordinates,
      );

  // ============================================================
  // DISTANCE
  // ============================================================

  double _totalDistanceKm = 0.0;

  double get totalDistanceKm => _totalDistanceKm;

  double get totalDistanceMeters =>
      _totalDistanceKm * 1000.0;

  // ============================================================
  // START TIME
  // ============================================================

  DateTime? _startedAt;

  DateTime? get startedAt => _startedAt;

  // ============================================================
  // DURATION
  // ============================================================

  int get durationSeconds {
    final DateTime? started = _startedAt;

    if (started == null) {
      return 0;
    }

    final int seconds =
        DateTime.now().difference(started).inSeconds;

    return seconds < 0 ? 0 : seconds;
  }

  // ============================================================
  // STEPS
  // ============================================================

  int _steps = 0;

  int get steps => _steps;

  void updateSteps(int value) {
    if (value < 0) {
      return;
    }

    _steps = value;

    if (_running) {
      unawaited(_syncCurrentState());
    }
  }

  // ============================================================
  // ACTIVITIES
  // ============================================================

  int _peeCount = 0;
  int _poopCount = 0;

  int get peeCount => _peeCount;

  int get poopCount => _poopCount;

  void updateActivities({
    int? peeCount,
    int? poopCount,
  }) {
    if (peeCount != null && peeCount >= 0) {
      _peeCount = peeCount;
    }

    if (poopCount != null && poopCount >= 0) {
      _poopCount = poopCount;
    }

    if (_running) {
      unawaited(_syncCurrentState());
    }
  }

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

    if (_running) {
      if (_walkId == cleanWalkId &&
          _sessionId == cleanSessionId) {
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
    // LOCATION PERMISSION
    // ----------------------------------------------------------

    final bool permission =
        await _ensureLocationPermission();

    if (!permission) {
      return false;
    }

    // ----------------------------------------------------------
    // REAL SESSION MUST EXIST
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>>
        sessionSnapshot =
        await _liveWalkSessions
            .doc(cleanSessionId)
            .get();

    if (!sessionSnapshot.exists) {
      return false;
    }

    final Map<String, dynamic> sessionData =
        sessionSnapshot.data() ??
            <String, dynamic>{};

    // ----------------------------------------------------------
    // VERIFY WALK ID
    // ----------------------------------------------------------

    final String sessionWalkId =
        sessionData['walkId']
                ?.toString()
                .trim() ??
            '';

    if (sessionWalkId.isNotEmpty &&
        sessionWalkId != cleanWalkId) {
      return false;
    }

    // ----------------------------------------------------------
    // VERIFY WALKER
    // ----------------------------------------------------------

    final String sessionWalkerUid =
        sessionData['walkerUid']
                ?.toString()
                .trim() ??
            '';

    if (sessionWalkerUid.isNotEmpty &&
        sessionWalkerUid != user.uid) {
      return false;
    }

    // ==========================================================
    // INITIAL STATE
    // ==========================================================

    _walkId = cleanWalkId;
    _sessionId = cleanSessionId;

    _totalDistanceKm =
        initialDistanceKm < 0
            ? 0.0
            : initialDistanceKm;

    _steps =
        initialSteps < 0
            ? 0
            : initialSteps;

    _peeCount =
        initialPeeCount < 0
            ? 0
            : initialPeeCount;

    _poopCount =
        initialPoopCount < 0
            ? 0
            : initialPoopCount;

    _startedAt =
        initialStartedAt ??
        _readDateTime(sessionData['startedAt']) ??
        DateTime.now();

    _lastPosition = null;

    _routeCoordinates.clear();

    // ==========================================================
    // RESTORE EXISTING ROUTE
    // ==========================================================

    _restoreRoute(
      initialRoute ??
          _readRoute(
            sessionData['routeCoordinates'],
          ),
    );

    _running = true;

    // ==========================================================
    // GPS STREAM
    // ==========================================================

    try {
  await _positionSubscription?.cancel();

  _positionSubscription =
      Geolocator.getPositionStream().listen(
    (Position position) {
      if (!_running) {
try {
  await _positionSubscription?.cancel();

  _positionSubscription =
      Geolocator.getPositionStream().listen(
    (Position position) {
      if (!_running) {
        return;
      }

      unawaited(
        _processPosition(position),
      );
    },
    onError: (_) {
      // GPS stream error does not terminate walk.
    },
    cancelOnError: false,
  );

  // ==========================================================
  // FIRST GPS FIX
  // ==========================================================

  try {
    final Position position =
        await Geolocator.getCurrentPosition();

    if (_running) {
      await _processPosition(position);
    }
  } catch (_) {
    // Temporary GPS failure.
  }

  // ==========================================================
  // PERIODIC FIRESTORE SYNC
  // ==========================================================

  _syncTimer?.cancel();

  _syncTimer = Timer.periodic(
    const Duration(seconds: 15),
    (_) {
      if (!_running) {
        return;
      }

      unawaited(
        _syncCurrentState(),
      );
    },
  );

  // ==========================================================
  // INITIAL SYNC
  // ==========================================================

  unawaited(
    _syncCurrentState(),
  );

  return true;
} catch (_) {
  _running = false;

  await _positionSubscription?.cancel();

  _positionSubscription = null;

  return false;
}

  // ============================================================
  // LOCATION PERMISSION
  // ============================================================

  Future<bool> _ensureLocationPermission() async {
  final bool serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    return false;
  }

  LocationPermission permission =
      await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return false;
  }

  return true;
  }

  // ============================================================
  // PROCESS GPS POSITION
  // ============================================================

  Future<void> _processPosition(
    Position position,
  ) async {
    if (!_running) {
      return;
    }

    final double lat = position.latitude;
    final double lng = position.longitude;

    if (!_validCoordinate(lat, lng)) {
      return;
    }

    // Ignore extremely inaccurate GPS points.
    if (position.accuracy > 100) {
      return;
    }

    final Position? previous = _lastPosition;

    // ==========================================================
    // FIRST POINT
    //
    // This becomes the START LOCATION.
    // ==========================================================

    if (previous == null) {
      _lastPosition = position;

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

    // ==========================================================
    // DISTANCE FROM PREVIOUS GPS FIX
    // ==========================================================

    final double meters =
        Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      lat,
      lng,
    );

    // Ignore impossible GPS jumps.
    if (meters > 500) {
      return;
    }

    // ==========================================================
    // DISTANCE
    // ==========================================================

    if (meters >= 0.5) {
      _totalDistanceKm +=
          meters / 1000.0;
    }

    // ==========================================================
    // SAVE CURRENT POSITION
    // ==========================================================

    _lastPosition = position;

    // ==========================================================
    // ROUTE POLYLINE
    //
    // Add a point only when walker has moved >= 5m.
    // ==========================================================

    _addRoutePoint(position);

    // ==========================================================
    // LOCAL LOCATION STREAM
    // ==========================================================

    if (!_locationController.isClosed) {
      _locationController.add(position);
    }

    // ==========================================================
    // FIRESTORE
    // ==========================================================

    await _writeLocation(position);
  }

  // ============================================================
  // ADD ROUTE POINT
  // ============================================================

  void _addRoutePoint(
    Position position, {
    bool force = false,
  }) {
    final Map<String, double> point =
        <String, double>{
      'lat': position.latitude,
      'lng': position.longitude,
    };

    if (!_validCoordinate(
      point['lat']!,
      point['lng']!,
    )) {
      return;
    }

    // First point is ALWAYS accepted.
    if (_routeCoordinates.isEmpty) {
      _routeCoordinates.add(point);
      return;
    }

    if (force) {
      _routeCoordinates.add(point);
      return;
    }

    final Map<String, double> last =
        _routeCoordinates.last;

    final double meters =
        Geolocator.distanceBetween(
      last['lat']!,
      last['lng']!,
      point['lat']!,
      point['lng']!,
    );

    // ==========================================================
    // POLYLINE FILTER
    //
    // Less than 5m = GPS noise.
    // 5m or more = real route movement.
    // ==========================================================

    if (meters < 5) {
      return;
    }

    _routeCoordinates.add(point);

    // Keep memory bounded.
    if (_routeCoordinates.length > 3000) {
      _routeCoordinates.removeRange(
        0,
        _routeCoordinates.length - 3000,
      );
    }
  }

  // ============================================================
  // WRITE LOCATION
  // ============================================================

  Future<void> _writeLocation(
    Position position,
  ) async {
    if (!_running) {
      return;
    }

    final String? walkId = _walkId;
    final String? sessionId = _sessionId;

    if (walkId == null ||
        sessionId == null ||
        walkId.isEmpty ||
        sessionId.isEmpty) {
      return;
    }

    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    // ==========================================================
    // CURRENT LOCATION
    // ==========================================================

    final Map<String, dynamic> currentLocation =
        <String, dynamic>{
      'lat': position.latitude,
      'lng': position.longitude,
    };

    // ==========================================================
    // COPY ROUTE
    // ==========================================================

    final List<Map<String, double>> route =
        _routeCoordinates
            .map(
              (Map<String, double> point) =>
                  <String, double>{
                'lat': point['lat']!,
                'lng': point['lng']!,
              },
            )
            .toList();

    // ==========================================================
    // START LOCATION
    // ==========================================================

    final Map<String, double> startLocation =
        route.isNotEmpty
            ? route.first
            : <String, double>{
                'lat': position.latitude,
                'lng': position.longitude,
              };

    // ==========================================================
    // SESSION DATA
    // ==========================================================

    final Map<String, dynamic> data =
        <String, dynamic>{
      'walkerUid': user.uid,

      'walkId': walkId,

      'sessionId': sessionId,

      // --------------------------------------------------------
      // LOCATION
      // --------------------------------------------------------

      'currentLocation': currentLocation,

      'currentLat': position.latitude,

      'currentLng': position.longitude,

      // --------------------------------------------------------
      // ROUTE
      // --------------------------------------------------------

      'startLocation': startLocation,

      'routeCoordinates': route,

      'routePointCount': route.length,

      // --------------------------------------------------------
      // METRICS
      // --------------------------------------------------------

      'distanceKm': _totalDistanceKm,

      'distanceMeters': totalDistanceMeters,

      'durationSeconds': durationSeconds,

      'steps': _steps,

      'peeCount': _peeCount,

      'poopCount': _poopCount,

      // --------------------------------------------------------
      // START
      // --------------------------------------------------------

      'startedAt':
          _startedAt == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(_startedAt!),

      // --------------------------------------------------------
      // GPS METADATA
      // --------------------------------------------------------

      'gpsAccuracy': position.accuracy,

      'gpsHeading': position.heading,

      'gpsSpeed': position.speed,

      'gpsUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      'status': 'active',

      'walkStarted': true,

      'walkEnded': false,

      'trackingStarted': true,

      'trackingEnded': false,
    };

    // ==========================================================
    // PRIMARY SESSION ONLY
    // ==========================================================

    try {
      await _liveWalkSessions
          .doc(sessionId)
          .set(
            data,
            SetOptions(
              merge: true,
            ),
          );
    } catch (_) {
      // Firestore failure must not stop GPS tracking.
    }
  }

  // ============================================================
  // PERIODIC SYNC
  // ============================================================

  Future<void> _syncCurrentState() async {
    if (!_running) {
      return;
    }

    final Position? position = _lastPosition;

    if (position == null) {
      return;
    }

    await _writeLocation(position);
  }

  // ============================================================
  // CURRENT SESSION DATA
  // ============================================================

  Map<String, dynamic> getCurrentSessionData() {
    final Position? position = _lastPosition;

    final List<Map<String, double>> route =
        _routeCoordinates
            .map(
              (Map<String, double> point) =>
                  <String, double>{
                'lat': point['lat']!,
                'lng': point['lng']!,
              },
            )
            .toList();

    return <String, dynamic>{
      'walkId': _walkId,

      'sessionId': _sessionId,

      'currentLocation':
          position == null
              ? null
              : <String, double>{
                  'lat': position.latitude,
                  'lng': position.longitude,
                },

      'currentLat': position?.latitude,

      'currentLng': position?.longitude,

      'distanceKm': _totalDistanceKm,

      'distanceMeters': totalDistanceMeters,

      'durationSeconds': durationSeconds,

      'steps': _steps,

      'peeCount': _peeCount,

      'poopCount': _poopCount,

      'startedAt': _startedAt,

      'startLocation':
          route.isNotEmpty
              ? route.first
              : null,

      'routeCoordinates': route,

      'routePointCount': route.length,

      'status':
          _running
              ? 'active'
              : 'stopped',
    };
  }

  // ============================================================
  // RECOVER
  //
  // NOTE:
  // The controller should provide the REAL sessionId.
  // This method does not invent one.
  // ============================================================

  Future<bool> recover({
    required String sessionId,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final String cleanSessionId =
        sessionId.trim();

    if (cleanSessionId.isEmpty) {
      return false;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>>
          snapshot =
          await _liveWalkSessions
              .doc(cleanSessionId)
              .get();

      if (!snapshot.exists) {
        return false;
      }

      final Map<String, dynamic> data =
          snapshot.data() ??
              <String, dynamic>{};

      final String walkerUid =
          data['walkerUid']
                  ?.toString()
                  .trim() ??
              '';

      if (walkerUid.isNotEmpty &&
          walkerUid != user.uid) {
        return false;
      }

      final String walkId =
          data['walkId']
                  ?.toString()
                  .trim() ??
              '';

      if (walkId.isEmpty) {
        return false;
      }

      final String status =
          data['status']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (status == 'completed' ||
          status == 'ended') {
        return false;
      }

      final double distance =
          _toDouble(
                data['distanceKm'],
              ) ??
              0.0;

      final int steps =
          _toInt(
                data['steps'],
              ) ??
              0;

      final int pee =
          _toInt(
                data['peeCount'],
              ) ??
              0;

      final int poop =
          _toInt(
                data['poopCount'],
              ) ??
              0;

      final DateTime? startedAt =
          _readDateTime(
            data['startedAt'],
          );

      final List<Map<String, dynamic>>
          route =
          _readRoute(
        data['routeCoordinates'],
      );

      return await start(
        walkId: walkId,
        sessionId: cleanSessionId,
        initialDistanceKm:
            distance,
        initialSteps:
            steps,
        initialPeeCount:
            pee,
        initialPoopCount:
            poop,
        initialStartedAt:
            startedAt,
        initialRoute:
            route,
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // RESTORE ROUTE
  // ============================================================

  void _restoreRoute(
    List<Map<String, dynamic>> route,
  ) {
    for (final Map<String, dynamic> item
        in route) {
      final double? lat =
          _toDouble(
        item['lat'] ??
            item['latitude'],
      );

      final double? lng =
          _toDouble(
        item['lng'] ??
            item['longitude'] ??
            item['lon'],
      );

      if (lat == null || lng == null) {
        continue;
      }

      if (!_validCoordinate(lat, lng)) {
        continue;
      }

      final Map<String, double> point =
          <String, double>{
        'lat': lat,
        'lng': lng,
      };

      if (_routeCoordinates.isEmpty) {
        _routeCoordinates.add(point);
        continue;
      }

      final Map<String, double> last =
          _routeCoordinates.last;

      final double meters =
          Geolocator.distanceBetween(
        last['lat']!,
        last['lng']!,
        lat,
        lng,
      );

      if (meters >= 5) {
        _routeCoordinates.add(point);
      }
    }

    if (_routeCoordinates.length > 3000) {
      _routeCoordinates.removeRange(
        0,
        _routeCoordinates.length - 3000,
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
  // This only stops LOCAL GPS tracking.
  // It does NOT delete the Firestore route.
  // ============================================================

  Future<void> stop() async {
    _running = false;

    _syncTimer?.cancel();
    _syncTimer = null;

    await _positionSubscription?.cancel();
    _positionSubscription = null;

    _lastPosition = null;

    _walkId = null;
    _sessionId = null;

    _startedAt = null;

    _totalDistanceKm = 0.0;

    _steps = 0;

    _peeCount = 0;
    _poopCount = 0;

    _routeCoordinates.clear();
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
