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
  // Controller uses ONLY background service GPS.
  // No second Geolocator stream is created here.
  // ============================================================

  Future<void> _attachExistingGps() async {
    try {
      await _locationSubscription?.cancel();

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
    final double distance =
        _backgroundService.totalDistanceKm;

    if (distance.isFinite && distance >= 0) {
      _totalDistanceKm = distance;
    }

    final int currentSteps =
        _backgroundService.steps;

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

    final dynamic rawDistance =
        data['distanceKm'];

    if (rawDistance is num) {
      final double distance =
          rawDistance.toDouble();

      if (distance.isFinite && distance >= 0) {
        _totalDistanceKm = distance;
      }
    }

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final dynamic rawSteps =
        data['steps'];

    if (rawSteps is num) {
      final int steps =
          rawSteps.toInt();

      if (steps >= 0) {
        _steps = steps;
      }
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

    final dynamic currentLocation =
        data['currentLocation'];

    if (currentLocation is Map) {
      final dynamic lat =
          currentLocation['lat'] ??
              currentLocation['latitude'];

      final dynamic lng =
          currentLocation['lng'] ??
              currentLocation['longitude'];

      if (lat is num && lng is num) {
        final double latitude =
            lat.toDouble();

        final double longitude =
            lng.toDouble();

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
  //
  // Flow:
  //
  // Start background GPS
  //       ↓
  // Attach GPS listener
  //       ↓
  // Create liveWalkSessions document
  //       ↓
  // Create/update active_walks document
  //       ↓
  // Mark walk as started
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
      // --------------------------------------------------------
      // WALKER UID
      // --------------------------------------------------------

      final String walkerUid =
          currentWalkerUid;

      if (walkerUid.isEmpty) {
        debugPrint(
          'Live walk start failed: Walker UID is missing.',
        );

        return false;
      }

      // --------------------------------------------------------
      // VALIDATE SESSION ID
      // --------------------------------------------------------

      final String liveSessionId =
          cleanSessionId;

      if (liveSessionId.isEmpty) {
        debugPrint(
          'Live walk start failed: session ID is missing.',
        );

        return false;
      }

      // --------------------------------------------------------
      // VALIDATE WALK ID
      // --------------------------------------------------------

      final String liveWalkId =
          walkId.trim();

      if (liveWalkId.isEmpty) {
        debugPrint(
          'Live walk start failed: walk ID is missing.',
        );

        return false;
      }

      // --------------------------------------------------------
      // START BACKGROUND GPS
      //
      // If GPS service is already running,
      // the service should safely handle it.
      // --------------------------------------------------------

      try {
       await _backgroundService.start();
     } catch (e) {
       debugPrint(
       'Background GPS start warning: $e',
      );
     }   
      
      // --------------------------------------------------------
      // MAKE SURE CONTROLLER IS LISTENING
      // --------------------------------------------------------

      await _ensureGpsListener();

      // --------------------------------------------------------
      // START FIRESTORE LIVE SESSION
      // --------------------------------------------------------

      await _sessionService.startWalk(
        sessionId: liveSessionId,
        walkId: liveWalkId,
        ownerUid: ownerUid.trim(),
        ownerName: ownerName.trim(),
        dogName: dogName.trim(),
        dogBreed: dogBreed.trim(),
        walkerUid: walkerUid,
      );

      // --------------------------------------------------------
      // LOCAL STATE
      // --------------------------------------------------------

      _walkStarted = true;

      _updateDistance();

      return true;
    } catch (e) {
      debugPrint(
        'Live walk start error: $e',
      );

      _walkStarted = false;

      return false;
    } finally {
      _startingWalk = false;
      _safeNotify();
    }
  }

  // ============================================================
  // ENSURE GPS LISTENER
  //
  // IMPORTANT:
  // Only background service GPS is used.
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
  //
  // Flow:
  //
  // Complete liveWalkSessions
  //       ↓
  // Complete active_walks
  //       ↓
  // Complete walk request
  //       ↓
  // Stop GPS
  //       ↓
  // Reset local state
  // ============================================================

  Future<bool> endWalk() async {
    if (_ending) {
      return false;
    }

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
      // FINAL LOCAL STATS
      // --------------------------------------------------------

      _updateDistance();

      // --------------------------------------------------------
      // 1. COMPLETE LIVE SESSION
      // --------------------------------------------------------

      try {
        await _sessionService.completeWalk(
          sessionId: cleanSessionId,
          walkId: walkId.trim(),
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
          walkId.trim(),
          sessionId: cleanSessionId,
        );

        requestCompleted = true;
      } catch (e) {
        debugPrint(
          'Walk request completion error: $e',
        );
      }

      // --------------------------------------------------------
      // 3. STOP GPS
      // --------------------------------------------------------

      await _stopGps();

      // --------------------------------------------------------
      // 4. RESET LOCAL STATE
      // --------------------------------------------------------

      _walkStarted = false;
      _gpsReady = false;

      _safeNotify();

      return sessionCompleted || requestCompleted;
    } catch (e) {
      debugPrint(
        'Live walk end error: $e',
      );

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
