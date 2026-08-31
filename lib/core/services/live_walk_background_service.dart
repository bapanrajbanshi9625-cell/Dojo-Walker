import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// ============================================================
/// DOJO WALKER
/// LIVE WALK BACKGROUND SERVICE
///
/// PRIMARY:
/// liveWalkSessions/{sessionId}
///
/// MIRROR:
/// active_walk/{walkId}
///
/// ORIGINAL REQUEST:
/// walk_requests/{walkId}
///
/// IMPORTANT:
/// This service NEVER modifies walk_requests.
///
/// ROUTE RULE:
/// First valid GPS point after Start Walk is the START point.
/// Every meaningful movement point is appended to routeCoordinates.
/// The complete Start -> Complete route is preserved.
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

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _activeWalks =>
      _firestore.collection('active_walk');

  CollectionReference<Map<String, dynamic>> get _liveWalkSessions =>
      _firestore.collection('liveWalkSessions');

  CollectionReference<Map<String, dynamic>> get _walkRequests =>
      _firestore.collection('walk_requests');

  // ============================================================
  // GPS
  // ============================================================

  StreamSubscription<Position>? _positionSubscription;

  Timer? _syncTimer;

  // ============================================================
  // LOCATION STREAM
  // ============================================================

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
  //
  // COMPLETE ROUTE FROM START TO COMPLETE
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

    unawaited(_syncCurrentState());
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

    unawaited(_syncCurrentState());
  }

  // ============================================================
  // START
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
    // ----------------------------------------------------------
    // ALREADY RUNNING
    // ----------------------------------------------------------

    if (_running) {
      if (_walkId == walkId &&
          _sessionId == sessionId) {
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
    // SESSION MUST EXIST
    // ----------------------------------------------------------

    final DocumentSnapshot<Map<String, dynamic>>
        sessionSnapshot =
        await _liveWalkSessions
            .doc(sessionId)
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
        sessionWalkId != walkId.trim()) {
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

    // ----------------------------------------------------------
    // INITIAL STATE
    // ----------------------------------------------------------

    _walkId = walkId.trim();

    _sessionId = sessionId.trim();

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
        initialStartedAt ?? DateTime.now();

    _lastPosition = null;

    _routeCoordinates.clear();

    // ----------------------------------------------------------
    // RESTORE EXISTING ROUTE
    //
    // Used only during recovery.
    // ----------------------------------------------------------

    if (initialRoute != null) {
      for (final Map<String, dynamic> item
          in initialRoute) {
        final double? lat = _toDouble(
          item['lat'] ?? item['latitude'],
        );

        final double? lng = _toDouble(
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

        _routeCoordinates.add(
          <String, double>{
            'lat': lat,
            'lng': lng,
          },
        );
      }
    }

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
            return;
          }

          unawaited(
            _processPosition(position),
          );
        },
        onError: (Object error) {
          // GPS errors do not terminate the walk.
        },
        cancelOnError: false,
      );

      // --------------------------------------------------------
      // FIRST GPS FIX
      // --------------------------------------------------------

      try {
        final Position position =
            await Geolocator.getCurrentPosition();

        if (_running) {
          await _processPosition(position);
        }
      } catch (_) {
        // Temporary GPS failure.
      }

      // --------------------------------------------------------
      // PERIODIC FIRESTORE SYNC
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // INITIAL SYNC
      // --------------------------------------------------------

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
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ============================================================
  // PROCESS GPS
  // ============================================================

  Future<void> _processPosition(
    Position position,
  ) async {
    if (!_running) {
      return;
    }

    if (!_validCoordinate(
      position.latitude,
      position.longitude,
    )) {
      return;
    }

    // Ignore extremely inaccurate GPS fixes.
    if (position.accuracy > 100) {
      return;
    }

    final Position? previous = _lastPosition;

    // ==========================================================
    // DISTANCE
    // ==========================================================

    if (previous != null) {
      final double meters =
          Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );

      // Prevent unrealistic GPS jumps.
      if (meters > 0 && meters <= 500) {
        _totalDistanceKm +=
            meters / 1000.0;
      }
    }

    // ==========================================================
    // CURRENT LOCATION
    // ==========================================================

    _lastPosition = position;

    // ==========================================================
    // ROUTE
    //
    // First valid point = START.
    // Every meaningful movement point is appended.
    // ==========================================================

    _addRoutePoint(position);

    // ==========================================================
    // LOCAL STREAM
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
    Position position,
  ) {
    final Map<String, double> point =
        <String, double>{
      'lat': position.latitude,
      'lng': position.longitude,
    };

    // ----------------------------------------------------------
    // FIRST POINT
    //
    // This becomes the permanent START point.
    // ----------------------------------------------------------

    if (_routeCoordinates.isEmpty) {
      _routeCoordinates.add(point);
      return;
    }

    // ----------------------------------------------------------
    // MOVEMENT FILTER
    //
    // Ignore GPS jitter below 5 meters.
    // ----------------------------------------------------------

    final Map<String, double> last =
        _routeCoordinates.last;

    final double meters =
        Geolocator.distanceBetween(
      last['lat']!,
      last['lng']!,
      position.latitude,
      position.longitude,
    );

    if (meters < 5) {
      return;
    }

    // ----------------------------------------------------------
    // ADD NEW ROUTE POINT
    //
    // IMPORTANT:
    // NO 3000 POINT LIMIT.
    // COMPLETE START -> END ROUTE IS PRESERVED.
    // ----------------------------------------------------------

    _routeCoordinates.add(point);
  }

  // ============================================================
  // WRITE LOCATION
  // ============================================================

  Future<void> _writeLocation(
    Position position,
  ) async {
    final String? walkId = _walkId;

    final String? sessionId = _sessionId;

    if (!_running ||
        walkId == null ||
        sessionId == null) {
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
    // COMPLETE ROUTE COPY
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
    // SAFE DURATION
    // ==========================================================

    final int safeDurationSeconds =
        durationSeconds;

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
    // ACTIVE WALK MIRROR
    // ==========================================================

    final Map<String, dynamic> activeData =
        <String, dynamic>{
      'walkerUid': user.uid,

      'walkId': walkId,

      'sessionId': sessionId,

      // Current moving location.
      'currentLat': position.latitude,

      'currentLng': position.longitude,

      'currentLocation': currentLocation,

      // Complete route.
      'routeCoordinates': route,

      // Permanent START location.
      'startLocation': startLocation,

      'distance': '${_totalDistanceKm.toStringAsFixed(2)} km',

      'distanceKm': _totalDistanceKm,

      'distanceMeters': totalDistanceMeters,

      'durationSeconds': safeDurationSeconds,

      'steps': _steps,

      'peeCount': _peeCount,

      'poopCount': _poopCount,

      'startedAt':
          Timestamp.fromDate(_startedAt!),

      'gpsAccuracy': position.accuracy,

      'gpsHeading': position.heading,

      'gpsSpeed': position.speed,

      'gpsUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      'status': 'active',

      'walkStarted': true,

      'walkEnded': false,

      'trackingStarted': true,

      'trackingEnded': false,
    };

    // ==========================================================
    // PRIMARY LIVE SESSION
    // ==========================================================

    final Map<String, dynamic> sessionData =
        <String, dynamic>{
      'walkerUid': user.uid,

      'walkId': walkId,

      'sessionId': sessionId,

      // Current moving location.
      'currentLocation': currentLocation,

      'currentLat': position.latitude,

      'currentLng': position.longitude,

      // Complete Start -> current route.
      'routeCoordinates': route,

      // Permanent START.
      'startLocation': startLocation,

      'distanceKm': _totalDistanceKm,

      'distanceMeters': totalDistanceMeters,

      'durationSeconds': safeDurationSeconds,

      'steps': _steps,

      'peeCount': _peeCount,

      'poopCount': _poopCount,

      'startedAt':
          Timestamp.fromDate(_startedAt!),

      'gpsAccuracy': position.accuracy,

      'gpsHeading': position.heading,

      'gpsSpeed': position.speed,

      'gpsUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      'status': 'active',

      'walkStarted': true,

      'walkEnded': false,

      'trackingStarted': true,

      'trackingEnded': false,
    };

    // ==========================================================
    // BATCH WRITE
    // ==========================================================

    try {
      final WriteBatch batch =
          _firestore.batch();

      // --------------------------------------------------------
      // MIRROR
      // active_walk/{walkId}
      // --------------------------------------------------------

      batch.set(
        _activeWalks.doc(walkId),
        activeData,
        SetOptions(merge: true),
      );

      // --------------------------------------------------------
      // PRIMARY
      // liveWalkSessions/{sessionId}
      // --------------------------------------------------------

      batch.set(
        _liveWalkSessions.doc(sessionId),
        sessionData,
        SetOptions(merge: true),
      );

      await batch.commit();
    } catch (_) {
      // Firestore failure does not stop GPS tracking.
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
    return <String, dynamic>{
      'walkId': _walkId,

      'sessionId': _sessionId,

      'currentLocation':
          _lastPosition == null
              ? null
              : <String, double>{
                  'lat':
                      _lastPosition!.latitude,
                  'lng':
                      _lastPosition!.longitude,
                },

      'currentLat':
          _lastPosition?.latitude,

      'currentLng':
          _lastPosition?.longitude,

      'distanceKm':
          _totalDistanceKm,

      'distanceMeters':
          totalDistanceMeters,

      'durationSeconds':
          durationSeconds,

      'steps':
          _steps,

      'peeCount':
          _peeCount,

      'poopCount':
          _poopCount,

      'startedAt':
          _startedAt,

      // COMPLETE ROUTE.
      'routeCoordinates':
          List<Map<String, double>>.from(
        _routeCoordinates,
      ),

      'startLocation':
          _routeCoordinates.isNotEmpty
              ? _routeCoordinates.first
              : null,

      'status':
          _running
              ? 'active'
              : 'stopped',
    };
  }

  // ============================================================
  // STOP
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
  // RECOVER
  //
  // REAL SESSION ID ONLY.
  //
  // NEVER:
  // session-{walkId}
  // ============================================================

  Future<bool> recover() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _walkRequests
              .where(
                'walkerUid',
                isEqualTo: user.uid,
              )
              .where(
                'status',
                whereIn: <String>[
                  'active',
                  'accepted',
                ],
              )
              .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      // --------------------------------------------------------
      // SELECT REQUEST
      // --------------------------------------------------------

      DocumentSnapshot<Map<String, dynamic>>
          selected =
          snapshot.docs.first;

      // Prefer active.
      for (final DocumentSnapshot<
              Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic>? data =
            doc.data();

        final String status =
            data?['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (status == 'active') {
          selected = doc;
          break;
        }
      }

      final Map<String, dynamic>? selectedData =
          selected.data();

      if (selectedData == null) {
        return false;
      }

      // walk_requests/{walkId}
      final String resolvedWalkId =
          selected.id;

      // --------------------------------------------------------
      // REAL SESSION ID
      // --------------------------------------------------------

      final String sessionId =
          selectedData['liveWalkSessionId']
                  ?.toString()
                  .trim() ??
              '';

      if (sessionId.isEmpty) {
        return false;
      }

      // --------------------------------------------------------
      // VERIFY REAL SESSION
      // --------------------------------------------------------

      final DocumentSnapshot<Map<String, dynamic>>
          sessionSnapshot =
          await _liveWalkSessions
              .doc(sessionId)
              .get();

      if (!sessionSnapshot.exists) {
        return false;
      }

      final Map<String, dynamic> sessionData =
          sessionSnapshot.data() ??
              <String, dynamic>{};

      // --------------------------------------------------------
      // VERIFY WALK ID
      // --------------------------------------------------------

      final String sessionWalkId =
          sessionData['walkId']
                  ?.toString()
                  .trim() ??
              '';

      if (sessionWalkId.isNotEmpty &&
          sessionWalkId != resolvedWalkId) {
        return false;
      }

      // --------------------------------------------------------
      // DISTANCE
      // --------------------------------------------------------

      final double initialDistance =
          _toDouble(
                sessionData['distanceKm'],
              ) ??
              _toDouble(
                selectedData['distanceKm'],
              ) ??
              0.0;

      // --------------------------------------------------------
      // STEPS
      // --------------------------------------------------------

      final int initialSteps =
          _toInt(
                sessionData['steps'],
              ) ??
              _toInt(
                selectedData['steps'],
              ) ??
              0;

      // --------------------------------------------------------
      // PEE
      // --------------------------------------------------------

      final int initialPee =
          _toInt(
                sessionData['peeCount'],
              ) ??
              _toInt(
                selectedData['peeCount'],
              ) ??
              0;

      // --------------------------------------------------------
      // POOP
      // --------------------------------------------------------

      final int initialPoop =
          _toInt(
                sessionData['poopCount'],
              ) ??
              _toInt(
                selectedData['poopCount'],
              ) ??
              0;

      // --------------------------------------------------------
      // START TIME
      // --------------------------------------------------------

      DateTime? initialStartedAt =
          _readDateTime(
        sessionData['startedAt'],
      );

      initialStartedAt ??=
          _readDateTime(
        selectedData['startedAt'],
      );

      // --------------------------------------------------------
      // ROUTE
      // --------------------------------------------------------

      final List<Map<String, dynamic>>
          initialRoute =
          <Map<String, dynamic>>[];

      final dynamic rawRoute =
          sessionData['routeCoordinates'] ??
              selectedData['routeCoordinates'];

      if (rawRoute is List) {
        for (final dynamic item in rawRoute) {
          if (item is Map) {
            initialRoute.add(
              Map<String, dynamic>.from(item),
            );
          }
        }
      }

      // --------------------------------------------------------
      // START GPS AGAIN
      // --------------------------------------------------------

      return await start(
        walkId: resolvedWalkId,
        sessionId: sessionId,
        initialDistanceKm: initialDistance,
        initialSteps: initialSteps,
        initialPeeCount: initialPee,
        initialPoopCount: initialPoop,
        initialStartedAt: initialStartedAt,
        initialRoute: initialRoute,
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  DateTime? _readDateTime(dynamic value) {
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

  double? _toDouble(dynamic value) {
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

  int? _toInt(dynamic value) {
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
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stop();

    if (!_locationController.isClosed) {
      await _locationController.close();
    }
  }
}
