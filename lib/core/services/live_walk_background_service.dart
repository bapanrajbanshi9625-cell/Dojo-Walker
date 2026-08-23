// File location:
// lib/core/services/live_walk_background_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// ============================================================
/// DOJO WALKER
/// LIVE WALK BACKGROUND SERVICE
///
/// Responsibilities:
/// - Single GPS tracking source
/// - Live location
/// - Distance calculation
/// - Route/polyline collection
/// - Duration calculation
/// - Steps / pee / poop sync
/// - Firestore live session sync
/// - Active walk sync
/// - Offline-safe Firebase writes
/// - Walk recovery
///
/// IMPORTANT:
/// This service is the single GPS owner for Live Walk.
/// LiveWalkScreen should NOT create another GPS stream.
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
  // PUBLIC LOCATION STREAM
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
  // ============================================================

  final List<Map<String, double>> _routeCoordinates =
      <Map<String, double>>[];

  List<Map<String, double>> get routeCoordinates =>
      List.unmodifiable(_routeCoordinates);

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
        DateTime.now()
            .difference(started)
            .inSeconds;

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

    unawaited(
      _syncCurrentState(),
    );
  }

  // ============================================================
  // ACTIVITY COUNTS
  // ============================================================

  int _peeCount = 0;

  int _poopCount = 0;

  int get peeCount => _peeCount;

  int get poopCount => _poopCount;

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

    unawaited(
      _syncCurrentState(),
    );
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
    // SAME WALK ALREADY RUNNING
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

    final User? user =
        _auth.currentUser;

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
    // INITIAL STATE
    // ----------------------------------------------------------

    _walkId = walkId;

    _sessionId = sessionId;

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
            DateTime.now();

    _lastPosition = null;

    _routeCoordinates.clear();

    // ----------------------------------------------------------
    // RESTORE ROUTE
    // ----------------------------------------------------------

    if (initialRoute != null) {
      for (final Map<String, dynamic> item
          in initialRoute) {
        final double? lat =
            _toDouble(
          item['lat'] ??
              item['latitude'],
        );

        final double? lng =
            _toDouble(
          item['lng'] ??
              item['longitude'],
        );

        if (lat == null ||
            lng == null) {
          continue;
        }

        if (!_validCoordinate(
          lat,
          lng,
        )) {
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

    // ----------------------------------------------------------
    // LIMIT RESTORED ROUTE
    // ----------------------------------------------------------

    if (_routeCoordinates.length > 3000) {
      _routeCoordinates.removeRange(
        0,
        _routeCoordinates.length - 3000,
      );
    }

    _running = true;

    // ==========================================================
    // GPS SETTINGS
    //
    // IMPORTANT:
    // This project uses the older Geolocator API.
    // Therefore:
    //
    // LocationOptions
    // locationOptions:
    //
    // are intentionally used here.
    // ==========================================================

    const LocationOptions settings =
        LocationOptions(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    try {
      // --------------------------------------------------------
      // CANCEL OLD STREAM
      // --------------------------------------------------------

      await _positionSubscription?.cancel();

      _positionSubscription = null;

      // --------------------------------------------------------
      // START GPS STREAM
      // --------------------------------------------------------

      _positionSubscription =
          Geolocator.getPositionStream(
        locationOptions: settings,
      ).listen(
        (Position position) {
          if (!_running) {
            return;
          }

          unawaited(
            _processPosition(
              position,
            ),
          );
        },
        onError: (Object error) {
          // GPS stream errors must not stop the walk.
          //
          // The service remains alive and periodic sync
          // continues when a valid position is available.
        },
        cancelOnError: false,
      );

      // ========================================================
      // FIRST GPS FIX
      // ========================================================

      try {
        final Position position =
            await Geolocator.getCurrentPosition(
          desiredAccuracy:
              LocationAccuracy.high,
        );

        if (_running) {
          await _processPosition(
            position,
          );
        }
      } catch (_) {
        // GPS can temporarily be unavailable.
        // Do not terminate the walk.
      }

      // ========================================================
      // PERIODIC SYNC
      // ========================================================

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

      // ========================================================
      // INITIAL FIREBASE SYNC
      // ========================================================

      unawaited(
        _syncCurrentState(),
      );

      return true;
    } catch (_) {
      _running = false;

      await _positionSubscription?.cancel();

      _positionSubscription = null;

      _syncTimer?.cancel();

      _syncTimer = null;

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

    if (permission ==
        LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ============================================================
  // PROCESS POSITION
  // ============================================================

  Future<void> _processPosition(
    Position position,
  ) async {
    if (!_running) {
      return;
    }

    // ----------------------------------------------------------
    // VALID COORDINATES
    // ----------------------------------------------------------

    if (!_validCoordinate(
      position.latitude,
      position.longitude,
    )) {
      return;
    }

    // ----------------------------------------------------------
    // GPS ACCURACY
    //
    // Ignore very inaccurate points.
    // ----------------------------------------------------------

    if (position.accuracy > 100) {
      return;
    }

    // ----------------------------------------------------------
    // PREVIOUS LOCATION
    // ----------------------------------------------------------

    final Position? previous =
        _lastPosition;

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    if (previous != null) {
      final double meters =
          Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );

      // --------------------------------------------------------
      // Ignore zero movement.
      // Ignore impossible GPS jumps.
      // --------------------------------------------------------

      if (meters > 0 &&
          meters <= 500) {
        _totalDistanceKm +=
            meters / 1000.0;
      }
    }

    // ----------------------------------------------------------
    // SAVE LAST POSITION
    // ----------------------------------------------------------

    _lastPosition = position;

    // ----------------------------------------------------------
    // ADD ROUTE POINT
    // ----------------------------------------------------------

    _addRoutePoint(
      position,
    );

    // ----------------------------------------------------------
    // NOTIFY UI
    // ----------------------------------------------------------

    if (!_locationController.isClosed) {
      _locationController.add(
        position,
      );
    }

    // ----------------------------------------------------------
    // FIREBASE
    // ----------------------------------------------------------

    await _writeLocation(
      position,
    );
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
    // AVOID DUPLICATE / VERY CLOSE POINTS
    // ----------------------------------------------------------

    if (_routeCoordinates.isNotEmpty) {
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
    }

    _routeCoordinates.add(
      point,
    );

    // ----------------------------------------------------------
    // MEMORY LIMIT
    // ----------------------------------------------------------

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
    final String? walkId =
        _walkId;

    final String? sessionId =
        _sessionId;

    if (!_running ||
        walkId == null ||
        sessionId == null) {
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    // ==========================================================
    // CURRENT LOCATION
    // ==========================================================

    final Map<String, dynamic>
        currentLocation =
        <String, dynamic>{
      'lat': position.latitude,
      'lng': position.longitude,
    };

    // ==========================================================
    // ROUTE
    // ==========================================================

    final List<Map<String, double>>
        route =
        List<Map<String, double>>.from(
      _routeCoordinates,
    );

    // ==========================================================
    // DURATION
    // ==========================================================

    final int currentDuration =
        durationSeconds;

    // ==========================================================
    // ACTIVE WALK DATA
    // ==========================================================

    final Map<String, dynamic>
        activeData =
        <String, dynamic>{
      'walkerUid':
          user.uid,

      'walkId':
          walkId,

      'sessionId':
          sessionId,

      // --------------------------------------------------------
      // LOCATION
      // --------------------------------------------------------

      'currentLat':
          position.latitude,

      'currentLng':
          position.longitude,

      'currentLocation':
          currentLocation,

      // --------------------------------------------------------
      // DISTANCE
      // --------------------------------------------------------

      'distance':
          '${_totalDistanceKm.toStringAsFixed(2)} km',

      'distanceKm':
          _totalDistanceKm,

      'distanceMeters':
          totalDistanceMeters,

      // --------------------------------------------------------
      // DURATION
      // --------------------------------------------------------

      'durationSeconds':
          currentDuration,

      // --------------------------------------------------------
      // ACTIVITY
      // --------------------------------------------------------

      'steps':
          _steps,

      'peeCount':
          _peeCount,

      'poopCount':
          _poopCount,

      // --------------------------------------------------------
      // ROUTE
      // --------------------------------------------------------

      'routeCoordinates':
          route,

      'startLocation':
          route.isNotEmpty
              ? route.first
              : currentLocation,

      // --------------------------------------------------------
      // START TIME
      // --------------------------------------------------------

      'startedAt':
          _startedAt == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(
                  _startedAt!,
                ),

      // --------------------------------------------------------
      // GPS
      // --------------------------------------------------------

      'gpsAccuracy':
          position.accuracy,

      'gpsHeading':
          position.heading,

      'gpsSpeed':
          position.speed,

      'gpsUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      'status':
          'active',
    };

    // ==========================================================
    // LIVE SESSION DATA
    // ==========================================================

    final Map<String, dynamic>
        sessionData =
        <String, dynamic>{
      'walkerUid':
          user.uid,

      'walkId':
          walkId,

      'sessionId':
          sessionId,

      // --------------------------------------------------------
      // LOCATION
      // --------------------------------------------------------

      'currentLocation':
          currentLocation,

      'currentLat':
          position.latitude,

      'currentLng':
          position.longitude,

      // --------------------------------------------------------
      // DISTANCE
      // --------------------------------------------------------

      'distanceKm':
          _totalDistanceKm,

      'distanceMeters':
          totalDistanceMeters,

      // --------------------------------------------------------
      // DURATION
      // --------------------------------------------------------

      'durationSeconds':
          currentDuration,

      // --------------------------------------------------------
      // ACTIVITY
      // --------------------------------------------------------

      'steps':
          _steps,

      'peeCount':
          _peeCount,

      'poopCount':
          _poopCount,

      // --------------------------------------------------------
      // ROUTE
      // --------------------------------------------------------

      'routeCoordinates':
          route,

      'startLocation':
          route.isNotEmpty
              ? route.first
              : currentLocation,

      // --------------------------------------------------------
      // START TIME
      // --------------------------------------------------------

      'startedAt':
          _startedAt == null
              ? FieldValue.serverTimestamp()
              : Timestamp.fromDate(
                  _startedAt!,
                ),

      // --------------------------------------------------------
      // GPS
      // --------------------------------------------------------

      'gpsAccuracy':
          position.accuracy,

      'gpsHeading':
          position.heading,

      'gpsSpeed':
          position.speed,

      'gpsUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      'status':
          'ACTIVE',
    };

    // ==========================================================
    // FIRESTORE BATCH
    // ==========================================================

    try {
      final WriteBatch batch =
          _firestore.batch();

      // --------------------------------------------------------
      // ACTIVE WALK
      // --------------------------------------------------------

      batch.set(
        _activeWalks.doc(
          walkId,
        ),
        activeData,
        SetOptions(
          merge: true,
        ),
      );

      // --------------------------------------------------------
      // LIVE SESSION
      // --------------------------------------------------------

      batch.set(
        _liveWalkSessions.doc(
          sessionId,
        ),
        sessionData,
        SetOptions(
          merge: true,
        ),
      );

      await batch.commit();
    } catch (_) {
      // --------------------------------------------------------
      // IMPORTANT
      //
      // Never stop GPS because Firebase/network failed.
      //
      // Firestore mobile SDK can queue writes locally when
      // offline and synchronize them when connection returns.
      // --------------------------------------------------------
    }
  }

  // ============================================================
  // PERIODIC SYNC
  // ============================================================

  Future<void> _syncCurrentState() async {
    if (!_running) {
      return;
    }

    final Position? position =
        _lastPosition;

    if (position == null) {
      return;
    }

    await _writeLocation(
      position,
    );
  }

  // ============================================================
  // CURRENT SESSION DATA
  // ============================================================

  Map<String, dynamic>
      getCurrentSessionData() {
    return <String, dynamic>{
      'walkId':
          _walkId,

      'sessionId':
          _sessionId,

      'currentLocation':
          _lastPosition == null
              ? null
              : <String, double>{
                  'lat':
                      _lastPosition!
                          .latitude,
                  'lng':
                      _lastPosition!
                          .longitude,
                },

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

      'routeCoordinates':
          List<Map<String, double>>.from(
        _routeCoordinates,
      ),

      'status':
          _running
              ? 'ACTIVE'
              : 'STOPPED',
    };
  }

  // ============================================================
  // STOP
  // ============================================================

  Future<void> stop() async {
    _running = false;

    // ----------------------------------------------------------
    // TIMER
    // ----------------------------------------------------------

    _syncTimer?.cancel();

    _syncTimer = null;

    // ----------------------------------------------------------
    // GPS
    // ----------------------------------------------------------

    await _positionSubscription?.cancel();

    _positionSubscription = null;

    // ----------------------------------------------------------
    // MEMORY STATE
    // ----------------------------------------------------------

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
  // RECOVER EXISTING WALK
  // ============================================================

  Future<bool> recover() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      // --------------------------------------------------------
      // FIND ACTIVE / ACCEPTED WALK
      // --------------------------------------------------------

      final QuerySnapshot<
              Map<String, dynamic>>
          snapshot =
          await _walkRequests
              .where(
                'walkerUid',
                isEqualTo:
                    user.uid,
              )
              .where(
                'status',
                whereIn:
                    <String>[
                  'active',
                  'accepted',
                ],
              )
              .get();

      if (snapshot.docs.isEmpty) {
        return false;
      }

      // --------------------------------------------------------
      // DEFAULT FIRST WALK
      // --------------------------------------------------------

      DocumentSnapshot<
              Map<String, dynamic>>
          selected =
          snapshot.docs.first;

      // --------------------------------------------------------
      // PREFER ACTIVE
      // --------------------------------------------------------

      for (final DocumentSnapshot<
              Map<String, dynamic>>
          doc in snapshot.docs) {
        final Map<String, dynamic>?
            docData =
            doc.data();

        if (docData != null &&
            docData['status'] ==
                'active') {
          selected = doc;
          break;
        }
      }

      // --------------------------------------------------------
      // SELECTED DATA
      // --------------------------------------------------------

      final Map<String, dynamic>?
          selectedData =
          selected.data();

      if (selectedData == null) {
        return false;
      }

      final Map<String, dynamic>
          data =
          Map<String, dynamic>.from(
        selectedData,
      );

      // --------------------------------------------------------
      // WALK ID
      // --------------------------------------------------------

      final String resolvedWalkId =
          selected.id;

      // --------------------------------------------------------
      // SESSION ID
      // --------------------------------------------------------

      final dynamic rawSessionId =
          data['liveWalkSessionId'];

      final String sessionValue =
          rawSessionId
                  ?.toString()
                  .trim() ??
              '';

      final String resolvedSessionId =
          sessionValue.isNotEmpty
              ? sessionValue
              : 'session-$resolvedWalkId';

      // ========================================================
      // DISTANCE
      // ========================================================

      final double initialDistance =
          _toDouble(
                data['distanceKm'],
              ) ??
              0.0;

      // ========================================================
      // STEPS
      // ========================================================

      final int initialSteps =
          _toInt(
                data['steps'],
              ) ??
              0;

      // ========================================================
      // PEE
      // ========================================================

      final int initialPee =
          _toInt(
                data['peeCount'],
              ) ??
              0;

      // ========================================================
      // POOP
      // ========================================================

      final int initialPoop =
          _toInt(
                data['poopCount'],
              ) ??
              0;

      // ========================================================
      // START TIME
      // ========================================================

      DateTime? initialStartedAt;

      final dynamic started =
          data['startedAt'];

      if (started is Timestamp) {
        initialStartedAt =
            started.toDate();
      } else if (started is DateTime) {
        initialStartedAt =
            started;
      } else if (started is String) {
        initialStartedAt =
            DateTime.tryParse(
          started,
        );
      }

      // ========================================================
      // ROUTE
      // ========================================================

      final List<Map<String, dynamic>>
          initialRoute =
          <Map<String, dynamic>>[];

      final dynamic rawRoute =
          data['routeCoordinates'];

      if (rawRoute is List) {
        for (final dynamic item
            in rawRoute) {
          if (item is Map) {
            initialRoute.add(
              Map<String, dynamic>.from(
                item,
              ),
            );
          }
        }
      }

      // ========================================================
      // START RECOVERED WALK
      // ========================================================

      return await start(
        walkId:
            resolvedWalkId,

        sessionId:
            resolvedSessionId,

        initialDistanceKm:
            initialDistance,

        initialSteps:
            initialSteps,

        initialPeeCount:
            initialPee,

        initialPoopCount:
            initialPoop,

        initialStartedAt:
            initialStartedAt,

        initialRoute:
            initialRoute,
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // HELPERS
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
