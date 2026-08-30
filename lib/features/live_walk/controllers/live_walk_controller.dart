import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/live_walk_background_service.dart';
import '../../../core/services/live_walk_session_service.dart';
import '../../../services/walk_request_service.dart';

class LiveWalkController extends ChangeNotifier {
  LiveWalkController({
    required this.ownerUid,
    required this.ownerName,
    required this.walkId,
    required this.dogName,
    required this.dogBreed,
    this.ownerPhone,
    this.sessionId,
  });

  // ============================================================
  // DATA
  // ============================================================

  final String ownerUid;
  final String ownerName;
  final String walkId;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;
  final String? sessionId;

  // ============================================================
  // SERVICES
  // ============================================================

  final WalkRequestService _walkRequestService =
      WalkRequestService.instance;

  final LiveWalkBackgroundService _backgroundService =
      LiveWalkBackgroundService.instance;

  final LiveWalkSessionService _sessionService =
      LiveWalkSessionService.instance;

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // GPS
  // ============================================================

  StreamSubscription<Position>? _locationSubscription;

  // ============================================================
  // STATE
  // ============================================================

  bool _initialized = false;
  bool _ending = false;
  bool _startingWalk = false;
  bool _walkStarted = false;
  bool _gpsReady = false;

  double _totalDistanceKm = 0.0;
  int _steps = 0;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get initialized => _initialized;

  bool get ending => _ending;

  bool get startingWalk => _startingWalk;

  bool get walkStarted => _walkStarted;

  bool get gpsReady => _gpsReady;

  double get totalDistanceKm => _totalDistanceKm;

  int get steps => _steps;

  // ============================================================
  // WALKER UID
  // ============================================================

  String get currentWalkerUid {
    return _auth.currentUser?.uid.trim() ?? '';
  }

  // ============================================================
  // SESSION ID
  // ============================================================

  String get cleanSessionId {
    final String value = sessionId?.trim() ?? '';

    if (value.isNotEmpty) {
      return value;
    }

    return 'session-$walkId';
  }

  // ============================================================
  // SESSION REF
  // ============================================================

  DocumentReference<Map<String, dynamic>> get sessionRef {
    return _firestore
        .collection('liveWalkSessions')
        .doc(cleanSessionId);
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
    if (_initialized) {
      return;
    }

    try {
      await _attachExistingGps();

      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await sessionRef.get();

      if (snapshot.exists) {
        final Map<String, dynamic>? data = snapshot.data();

        if (data != null) {
          updateFromSession(
            data,
            notify: false,
          );
        }
      }
    } catch (e) {
      debugPrint(
        'LiveWalkController initialize error: $e',
      );
    }

    _initialized = true;
    _safeNotify();
  }

  // ============================================================
  // ATTACH EXISTING GPS
  //
  // IMPORTANT:
  // Controller uses ONLY background service GPS.
  // No second Geolocator stream is created here.
  // ============================================================

  Future<void> _attachExistingGps() async {
    try {
      await _locationSubscription?.cancel();

      _locationSubscription = _backgroundService.locationStream.listen(
        _handlePosition,
        onError: (Object error) {
          debugPrint(
            'Live GPS stream error: $error',
          );
        },
        cancelOnError: false,
      );

      final Position? position = _backgroundService.lastPosition;

      if (position != null) {
        _gpsReady = true;
        _updateDistance();
      }
    } catch (e) {
      debugPrint(
        'Attach existing GPS error: $e',
      );
    }

    _safeNotify();
  }

  // ============================================================
  // POSITION
  // ============================================================

  void _handlePosition(Position position) {
    _gpsReady = true;

    _updateDistance();

    _safeNotify();
  }

  // ============================================================
  // DISTANCE / STEPS
  // ============================================================

  void _updateDistance() {
    final double distance = _backgroundService.totalDistanceKm;

    if (distance.isFinite && distance >= 0) {
      _totalDistanceKm = distance;
    }

    final int currentSteps = _backgroundService.steps;

    if (currentSteps >= 0) {
      _steps = currentSteps;
    }
  }

  // ============================================================
  // FIRESTORE SESSION UPDATE
  // ============================================================

  void updateFromSession(
    Map<String, dynamic> data, {
    bool notify = true,
  }) {
    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final dynamic rawDistance = data['distanceKm'];

    if (rawDistance is num) {
      final double distance = rawDistance.toDouble();

      if (distance.isFinite && distance >= 0) {
        _totalDistanceKm = distance;
      }
    }

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final dynamic rawSteps = data['steps'];

    if (rawSteps is num) {
      final int steps = rawSteps.toInt();

      if (steps >= 0) {
        _steps = steps;
      }
    }

    // ----------------------------------------------------------
    // STATUS
    // ----------------------------------------------------------

    final String status =
        data['status']?.toString().trim().toLowerCase() ?? '';

    if (status == 'active' ||
        status == 'started' ||
        status == 'live') {
      _walkStarted = true;
    }

    if (status == 'completed' ||
        status == 'ended' ||
        status == 'cancelled') {
      _walkStarted = false;
    }

    // ----------------------------------------------------------
    // CURRENT LOCATION
    // ----------------------------------------------------------

    final dynamic currentLocation = data['currentLocation'];

    if (currentLocation is Map) {
      final dynamic lat =
          currentLocation['lat'] ?? currentLocation['latitude'];

      final dynamic lng =
          currentLocation['lng'] ?? currentLocation['longitude'];

      if (lat is num && lng is num) {
        final double latitude = lat.toDouble();
        final double longitude = lng.toDouble();

        if (latitude != 0 &&
            longitude != 0 &&
            latitude.isFinite &&
            longitude.isFinite) {
          _gpsReady = true;
        }
      }
    }

    if (notify) {
      _safeNotify();
    }
  }

  // ============================================================
  // START WALK
  // ============================================================

  Future<bool> startWalk() async {
    if (_startingWalk ||
        _ending ||
        _walkStarted) {
      return _walkStarted;
    }

    _startingWalk = true;
    _safeNotify();

    try {
      final String walkerUid = currentWalkerUid;

      if (walkerUid.isEmpty) {
        debugPrint(
          'Live walk start skipped: Walker UID is missing.',
        );

        return false;
      }

      // --------------------------------------------------------
      // START BACKGROUND GPS
      //
      // If service is already running, this should remain safe.
      // --------------------------------------------------------

      try {
        await _backgroundService.start();
      } catch (e) {
        debugPrint(
          'Background GPS start warning: $e',
        );
        // Do not crash the walk UI.
      }

      // --------------------------------------------------------
      // MAKE SURE CONTROLLER IS LISTENING
      // --------------------------------------------------------

      await _ensureGpsListener();

      // --------------------------------------------------------
      // START FIRESTORE SESSION
      // --------------------------------------------------------

      final String liveSessionId = cleanSessionId;
      final String liveWalkId = walkId.trim();

      if (liveSessionId.isEmpty) {
        debugPrint(
          'Live walk start failed: session ID is missing.',
        );

        _walkStarted = false;
        return false;
      }

      if (liveWalkId.isEmpty) {
        debugPrint(
          'Live walk start failed: walk ID is missing.',
        );

        _walkStarted = false;
        return false;
      }

      await _sessionService.startWalk(
        sessionId: liveSessionId,
        walkId: liveWalkId,
        ownerUid: ownerUid.trim(),
        ownerName: ownerName.trim(),
        dogName: dogName.trim(),
        dogBreed: dogBreed.trim(),
        walkerUid: walkerUid,
      );

  // ============================================================
  // ENSURE GPS LISTENER
  // ============================================================

  Future<void> _ensureGpsListener() async {
    if (_locationSubscription != null) {
      return;
    }

    try {
      _locationSubscription =
          _backgroundService.locationStream.listen(
        _handlePosition,
        onError: (Object error) {
          debugPrint(
            'Live GPS stream error: $error',
          );
        },
        cancelOnError: false,
      );

      final Position? position =
          _backgroundService.lastPosition;

      if (position != null) {
        _gpsReady = true;
        _updateDistance();
      }
    } catch (e) {
      debugPrint(
        'GPS listener setup error: $e',
      );
    }
  }

  // ============================================================
  // END WALK
  // ============================================================

  Future<bool> endWalk() async {
    if (_ending) {
      return false;
    }

    // ----------------------------------------------------------
    // If already stopped, do nothing.
    // ----------------------------------------------------------

    if (!_walkStarted) {
      debugPrint(
        'Live walk end ignored: walk is not active.',
      );

      return false;
    }

    _ending = true;
    _safeNotify();

    bool sessionCompleted = false;
    bool requestCompleted = false;

    try {
      // --------------------------------------------------------
      // GET FINAL LOCAL STATS
      // --------------------------------------------------------

      _updateDistance();

      // --------------------------------------------------------
      // 1. COMPLETE LIVE SESSION
      // --------------------------------------------------------

      try {
        await _sessionService.completeWalk(
          sessionId: cleanSessionId,
          walkId: walkId,
        );

        sessionCompleted = true;
      } catch (e) {
        debugPrint(
          'Live session completion error: $e',
        );
      }

      // --------------------------------------------------------
      // 2. COMPLETE WALK REQUEST
      // --------------------------------------------------------

      try {
        await _walkRequestService.endLiveWalk(
          walkId,
          sessionId: cleanSessionId,
        );

        requestCompleted = true;
      } catch (e) {
        debugPrint(
          'Walk request completion error: $e',
        );
      }

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // Even if one backend operation has an issue,
      // always stop local GPS and reset UI state.
      // --------------------------------------------------------

      await _stopGps();

      _walkStarted = false;
      _gpsReady = false;

      _safeNotify();

      // --------------------------------------------------------
      // Consider local walk completion successful once the
      // completion flow has been attempted and local state
      // has been safely stopped.
      // --------------------------------------------------------

      return sessionCompleted || requestCompleted;
    } catch (e) {
      debugPrint(
        'Live walk end error: $e',
      );

      // --------------------------------------------------------
      // Never leave GPS running because of an unexpected error.
      // --------------------------------------------------------

      await _stopGps();

      _walkStarted = false;
      _gpsReady = false;

      return false;
    } finally {
      _ending = false;
      _safeNotify();
    }
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> _stopGps() async {
    try {
      await _locationSubscription?.cancel();
    } catch (e) {
      debugPrint(
        'GPS subscription stop error: $e',
      );
    }

    _locationSubscription = null;

    try {
      await _backgroundService.stop();
    } catch (e) {
      debugPrint(
        'GPS background service stop error: $e',
      );
    }
  }

  // ============================================================
  // SAFE NOTIFY
  // ============================================================

  void _safeNotify() {
    if (!hasListeners) {
      return;
    }

    notifyListeners();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _locationSubscription = null;

    super.dispose();
  }
}
