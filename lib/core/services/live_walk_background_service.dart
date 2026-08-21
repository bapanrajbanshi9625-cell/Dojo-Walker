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
///
/// यह service Live Walk के दौरान:
///
/// • GPS location लेती है
/// • Firebase active_walk update करती है
/// • Firebase liveWalkSessions update करती है
/// • App background में होने पर tracking जारी रखने में मदद करती है
/// • Network temporary unavailable होने पर local state नहीं मिटाती
///
/// IMPORTANT:
/// यह service existing ringtone / navigation / UI को control नहीं करती।
///
/// IMPORTANT:
/// फोन पूरी तरह POWER OFF होने पर कोई Android service execute
/// नहीं कर सकती। उस समय तक का data Firebase में सुरक्षित रहेगा।
/// फोन वापस ON होने पर app Firebase से active walk recover कर सकती है.
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

  CollectionReference<Map<String, dynamic>>
      get _activeWalks =>
          _firestore.collection('active_walk');

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  CollectionReference<Map<String, dynamic>>
      get _walkRequests =>
          _firestore.collection('walk_requests');

  // ============================================================
  // GPS
  // ============================================================

  StreamSubscription<Position>?
      _positionSubscription;

  Timer? _syncTimer;

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

  Position? get lastPosition =>
      _lastPosition;

  // ============================================================
  // DISTANCE
  // ============================================================

  double _totalDistanceKm = 0.0;

  double get totalDistanceKm =>
      _totalDistanceKm;

  // ============================================================
  // START
  // ============================================================

  Future<bool> start({
    required String walkId,
    required String sessionId,
    double initialDistanceKm = 0.0,
  }) async {
    if (_running) {
      // Same walk already running.
      if (_walkId == walkId &&
          _sessionId == sessionId) {
        return true;
      }

      await stop();
    }

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
    // SAVE WALK
    // ----------------------------------------------------------

    _walkId = walkId;

    _sessionId = sessionId;

    _totalDistanceKm =
        initialDistanceKm;

    _running = true;

    // ----------------------------------------------------------
    // START GPS
    // ----------------------------------------------------------

    const LocationSettings settings =
        LocationSettings(
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

          _lastPosition = position;

          unawaited(
            _processPosition(position),
          );
        },
        onError: (Object error) {
          // Do not kill the background service because
          // of one GPS stream error.
        },
        cancelOnError: false,
      );

      // --------------------------------------------------------
      // FIRST LOCATION
      // --------------------------------------------------------

      try {
        final Position position =
            await Geolocator.getCurrentPosition(
          desiredAccuracy:
              LocationAccuracy.high,
        );

        if (_running) {
          _lastPosition = position;

          await _processPosition(
            position,
          );
        }
      } catch (_) {
        // GPS first fix can fail temporarily.
        // Continuous stream will try again.
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

  Future<bool>
      _ensureLocationPermission() async {
    final bool serviceEnabled =
        await Geolocator
            .isLocationServiceEnabled();

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
    // DISTANCE
    // ----------------------------------------------------------

    final Position? previous =
        _lastPosition;

    if (previous != null) {
      final double meters =
          Geolocator.distanceBetween(
        previous.latitude,
        previous.longitude,
        position.latitude,
        position.longitude,
      );

      // Ignore impossible GPS jumps.
      if (meters > 0 &&
          meters <= 500) {
        _totalDistanceKm +=
            meters / 1000.0;
      }
    }

    _lastPosition = position;

    // ----------------------------------------------------------
    // FIREBASE
    // ----------------------------------------------------------

    await _writeLocation(
      position,
    );
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

    final Map<String, dynamic>
        currentLocation =
        <String, dynamic>{
      'lat': position.latitude,
      'lng': position.longitude,
    };

    // ----------------------------------------------------------
    // ACTIVE WALK
    // ----------------------------------------------------------

    final Map<String, dynamic>
        activeData =
        <String, dynamic>{
      'currentLat':
          position.latitude,
      'currentLng':
          position.longitude,

      'distance':
          '${_totalDistanceKm.toStringAsFixed(1)} km',

      'distanceKm':
          _totalDistanceKm,

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

      'status':
          'active',
    };

    // ----------------------------------------------------------
    // LIVE SESSION
    // ----------------------------------------------------------

    final Map<String, dynamic>
        sessionData =
        <String, dynamic>{
      'currentLocation':
          currentLocation,

      'currentLat':
          position.latitude,

      'currentLng':
          position.longitude,

      'distanceKm':
          _totalDistanceKm,

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

      'status':
          'ACTIVE',
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
      // Temporary network failure must NOT stop GPS.
      //
      // Firebase SDK can retry/sync cached writes when the
      // connection becomes available again.
      // --------------------------------------------------------
    }
  }

  // ============================================================
  // PERIODIC SYNC
  // ============================================================

  Future<void>
      _syncCurrentState() async {
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
  //
  // App restart/background recovery:
  //
  // Firebase → active walk → service restart
  // ============================================================

  Future<bool> recover() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

    try {
      final QuerySnapshot<
              Map<String, dynamic>>
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

      DocumentSnapshot<
              Map<String, dynamic>>
          selected =
          snapshot.docs.first;

      // Prefer active walk.
      for (final doc
          in snapshot.docs) {
        if (doc.data()['status'] ==
            'active') {
          selected = doc;
          break;
        }
      }

      final Map<String, dynamic>
          data =
          selected.data();

      final String resolvedWalkId =
          selected.id;

      final String resolvedSessionId =
          data['liveWalkSessionId']
                  ?.toString()
                  .trim() ??
              'session-$resolvedWalkId';

      double initialDistance = 0.0;

      final dynamic distance =
          data['distanceKm'];

      if (distance != null) {
        final double? parsed =
            double.tryParse(
          distance.toString(),
        );

        if (parsed != null &&
            parsed >= 0) {
          initialDistance =
              parsed;
        }
      }

      return await start(
        walkId: resolvedWalkId,
        sessionId:
            resolvedSessionId,
        initialDistanceKm:
            initialDistance,
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
  }
}
