// File location:
// lib/core/services/live_walk_background_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

/// ============================================================
/// DOJO WALKER
/// LIVE WALK BACKGROUND SERVICE
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
  //
  // LiveWalkScreen इसे listen कर सकता है.
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
  // LAST LOCATION
  // ============================================================

  Position? _lastPosition;

  Position? get lastPosition => _lastPosition;

  // ============================================================
  // DISTANCE
  // ============================================================

  double _totalDistanceKm = 0.0;

  double get totalDistanceKm => _totalDistanceKm;

  // ============================================================
  // START
  // ============================================================

  Future<bool> start({
    required String walkId,
    required String sessionId,
    double initialDistanceKm = 0.0,
  }) async {
    if (_running) {
      if (_walkId == walkId &&
          _sessionId == sessionId) {
        return true;
      }

      await stop();
    }

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
    // SAVE WALK
    // ----------------------------------------------------------

    _walkId = walkId;
    _sessionId = sessionId;

    _totalDistanceKm = initialDistanceKm;

    // Important:
    // New walk starts without an old GPS point.
    _lastPosition = null;

    _running = true;

    // ----------------------------------------------------------
    // GPS SETTINGS
    // ----------------------------------------------------------

    const LocationSettings settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    try {
      await _positionSubscription?.cancel();

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (Position position) {
          if (!_running) {
            return;
          }

          unawaited(
            _processPosition(position),
          );
        },
        onError: (Object error) {
          // GPS stream error should not kill the service.
        },
        cancelOnError: false,
      );

      // --------------------------------------------------------
      // FIRST LOCATION
      // --------------------------------------------------------

      try {
        final Position position =
            await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );

        if (_running) {
          await _processPosition(position);
        }
      } catch (_) {
        // First GPS fix can temporarily fail.
      }

      // --------------------------------------------------------
      // PERIODIC FIREBASE SYNC
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
        permission == LocationPermission.deniedForever) {
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
    // PREVIOUS POSITION
    // ----------------------------------------------------------

    final Position? previous = _lastPosition;

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

      // Ignore impossible GPS jumps.
      if (meters > 0 && meters <= 500) {
        _totalDistanceKm += meters / 1000.0;
      }
    }

    // ----------------------------------------------------------
    // SAVE CURRENT POSITION
    // ----------------------------------------------------------

    _lastPosition = position;

    // ----------------------------------------------------------
    // NOTIFY UI
    // ----------------------------------------------------------

    if (!_locationController.isClosed) {
      _locationController.add(position);
    }

    // ----------------------------------------------------------
    // FIREBASE
    // ----------------------------------------------------------

    await _writeLocation(position);
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

    final Map<String, dynamic> currentLocation = {
      'lat': position.latitude,
      'lng': position.longitude,
    };

    // ==========================================================
    // ACTIVE WALK
    // ==========================================================

    final Map<String, dynamic> activeData = {
      'currentLat': position.latitude,
      'currentLng': position.longitude,

      'distance':
          '${_totalDistanceKm.toStringAsFixed(1)} km',

      'distanceKm': _totalDistanceKm,

      'gpsAccuracy': position.accuracy,

      'gpsHeading': position.heading,

      'gpsSpeed': position.speed,

      'gpsUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      'status': 'active',
    };

    // ==========================================================
    // LIVE SESSION
    // ==========================================================

    final Map<String, dynamic> sessionData = {
      'currentLocation': currentLocation,

      'currentLat': position.latitude,

      'currentLng': position.longitude,

      'distanceKm': _totalDistanceKm,

      'gpsAccuracy': position.accuracy,

      'gpsHeading': position.heading,

      'gpsSpeed': position.speed,

      'gpsUpdatedAt':
          FieldValue.serverTimestamp(),

      'updatedAt':
          FieldValue.serverTimestamp(),

      'status': 'ACTIVE',
    };

    try {
      final WriteBatch batch =
          _firestore.batch();

      batch.set(
        _activeWalks.doc(walkId),
        activeData,
        SetOptions(
          merge: true,
        ),
      );

      batch.set(
        _liveWalkSessions.doc(sessionId),
        sessionData,
        SetOptions(
          merge: true,
        ),
      );

      await batch.commit();
    } catch (_) {
      // Firebase/network failure must not stop GPS.
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

    await _writeLocation(position);
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

    _totalDistanceKm = 0.0;
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

      DocumentSnapshot<Map<String, dynamic>> selected =
          snapshot.docs.first;

      // --------------------------------------------------------
      // Prefer ACTIVE walk.
      // --------------------------------------------------------

      for (final DocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic>? docData =
            doc.data();

        if (docData != null &&
            docData['status'] == 'active') {
          selected = doc;
          break;
        }
      }

      // --------------------------------------------------------
      // FIX:
      // selected.data() is nullable.
      // --------------------------------------------------------

      final Map<String, dynamic>? selectedData =
          selected.data();

      if (selectedData == null) {
        return false;
      }

      final Map<String, dynamic> data =
          Map<String, dynamic>.from(
        selectedData,
      );

      final String resolvedWalkId =
          selected.id;

      final String resolvedSessionId =
          data['liveWalkSessionId']
                  ?.toString()
                  .trim() ??
              'session-$resolvedWalkId';

      // --------------------------------------------------------
      // INITIAL DISTANCE
      // --------------------------------------------------------

      double initialDistance = 0.0;

      final dynamic distance =
          data['distanceKm'];

      if (distance is num) {
        initialDistance =
            distance.toDouble();
      } else if (distance != null) {
        final double? parsed =
            double.tryParse(
          distance.toString().trim(),
        );

        if (parsed != null &&
            parsed >= 0) {
          initialDistance = parsed;
        }
      }

      // --------------------------------------------------------
      // START RECOVERED WALK
      // --------------------------------------------------------

      return await start(
        walkId: resolvedWalkId,
        sessionId: resolvedSessionId,
        initialDistanceKm: initialDistance,
      );
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stop();

    await _locationController.close();
  }
}
