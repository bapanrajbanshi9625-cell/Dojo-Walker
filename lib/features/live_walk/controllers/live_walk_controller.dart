// File:
// lib/features/live_walk/controllers/live_walk_controller.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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

  // ============================================================
  // FIRESTORE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

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
  // SESSION ID
  // ============================================================

  String get cleanSessionId {
    final String? value = sessionId?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'session-$walkId';
  }

  // ============================================================
  // SESSION REFERENCE
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      get sessionRef {
    return _firestore
        .collection('liveWalkSessions')
        .doc(cleanSessionId);
  }

  // ============================================================
  // SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get sessionStream {
    return sessionRef.snapshots();
  }

  // ============================================================
  // INITIALIZE
  //
  // IMPORTANT:
  //
  // यहां नया GPS START नहीं किया जाता.
  //
  // अगर central GPS पहले से चल रहा है,
  // तो केवल उसका stream attach किया जाता है.
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    try {
      // --------------------------------------------------------
      // ATTACH EXISTING CENTRAL GPS
      // --------------------------------------------------------

      await _attachExistingGps();

      // --------------------------------------------------------
      // READ SESSION
      // --------------------------------------------------------

      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await sessionRef.get();

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data != null) {
        updateFromSession(data);
      }

      _initialized = true;

      notifyListeners();
    } catch (e) {
      debugPrint(
        'LiveWalkController initialize error: $e',
      );

      _initialized = true;
      notifyListeners();
    }
  }

  // ============================================================
  // ATTACH EXISTING GPS
  // ============================================================

  Future<void> _attachExistingGps() async {
    try {
      await _locationSubscription?.cancel();

      _locationSubscription =
          _backgroundService.locationStream.listen(
        (Position position) {
          _handlePosition(position);
        },
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

    notifyListeners();
  }

  // ============================================================
  // POSITION
  // ============================================================

  void _handlePosition(
    Position position,
  ) {
    _gpsReady = true;

    _updateDistance();

    notifyListeners();
  }

  // ============================================================
  // DISTANCE + STEPS
  // ============================================================

  void _updateDistance() {
    final double distance =
        _backgroundService.totalDistanceKm;

    if (distance >= 0) {
      _totalDistanceKm = distance;
    }

    final int currentSteps =
        _backgroundService.steps;

    if (currentSteps >= 0) {
      _steps = currentSteps;
    }
  }

  // ============================================================
  // UPDATE FROM FIRESTORE
  //
  // STATUS:
  //
  // READY
  //   → Walk screen opened but walk not started.
  //
  // ACTIVE / STARTED
  //   → Official walk is running.
  //
  // COMPLETED / ENDED
  //   → Walk finished.
  // ============================================================

  void updateFromSession(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final dynamic rawDistance =
        data['distanceKm'];

    if (rawDistance is num) {
      _totalDistanceKm =
          rawDistance.toDouble();
    }

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final dynamic rawSteps =
        data['steps'];

    if (rawSteps is num) {
      _steps = rawSteps.toInt();
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

    switch (status) {
      case 'active':
      case 'started':
        _walkStarted = true;
        break;

      case 'ready':
      case 'pending':
      case 'created':
        _walkStarted = false;
        break;

      case 'completed':
      case 'ended':
      case 'cancelled':
        _walkStarted = false;
        break;
    }

    // ----------------------------------------------------------
    // EXPLICIT WALK START FLAG
    //
    // This protects against status/flag mismatch.
    // ----------------------------------------------------------

    final dynamic walkStartedValue =
        data['walkStarted'];

    if (walkStartedValue is bool) {
      _walkStarted = walkStartedValue;
    }

    // ----------------------------------------------------------
    // GPS LOCATION
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

      if (lat is num &&
          lng is num &&
          lat != 0 &&
          lng != 0) {
        _gpsReady = true;
      }
    }

    notifyListeners();
  }

  // ============================================================
  // START WALK
  //
  // QR:
  // READY → ACTIVE
  //
  // INSTA:
  // Active Walk → Live Walk → ACTIVE
  //
  // GPS:
  // पहले से central service से चल रहा हो तो वही continue होगा.
  // यहां नया GPS START नहीं किया जाता.
  // ============================================================

  Future<void> startWalk() async {
    if (_startingWalk ||
        _ending ||
        _walkStarted) {
      return;
    }

    _startingWalk = true;

    notifyListeners();

    try {
      // --------------------------------------------------------
      // ACTUAL WALK START
      // --------------------------------------------------------

      await _sessionService.startWalk(
        sessionId: cleanSessionId,
        walkId: walkId,
        ownerUid: ownerUid,
        ownerName: ownerName,
        dogName: dogName,
        dogBreed: dogBreed,
      );

      // --------------------------------------------------------
      // LOCAL STATE
      // --------------------------------------------------------

      _walkStarted = true;

      _updateDistance();

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Live walk start error: $e',
      );

      rethrow;
    } finally {
      _startingWalk = false;

      notifyListeners();
    }
  }

  // ============================================================
  // END WALK
  //
  // ORDER:
  //
  // 1. Capture final GPS values
  // 2. Complete live session
  // 3. Complete walk request
  // 4. Stop GPS
  // 5. Clear local state
  // ============================================================

  Future<void> endWalk() async {
    if (_ending) {
      return;
    }

    if (!_walkStarted) {
      throw Exception(
        'Start the walk before ending it.',
      );
    }

    _ending = true;

    notifyListeners();

    try {
      // --------------------------------------------------------
      // FINAL GPS VALUES
      // --------------------------------------------------------

      _updateDistance();

      // --------------------------------------------------------
      // COMPLETE LIVE SESSION
      // --------------------------------------------------------

      await _sessionService.completeWalk(
        sessionId: cleanSessionId,
      );

      // --------------------------------------------------------
      // COMPLETE ORIGINAL WALK REQUEST
      // --------------------------------------------------------

      await _walkRequestService.endLiveWalk(
        walkId,
        sessionId: cleanSessionId,
      );

      // --------------------------------------------------------
      // STOP GPS ONLY AFTER SUCCESS
      // --------------------------------------------------------

      await _stopGps();

      // --------------------------------------------------------
      // LOCAL STATE
      // --------------------------------------------------------

      _walkStarted = false;

      _gpsReady = false;

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Live walk end error: $e',
      );

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // अगर completion fail हुआ तो GPS बंद नहीं होगा.
      // User retry कर सकता है.
      // --------------------------------------------------------

      rethrow;
    } finally {
      _ending = false;

      notifyListeners();
    }
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> _stopGps() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;

    try {
      await _backgroundService.stop();
    } catch (e) {
      debugPrint(
        'GPS stop error: $e',
      );
    }
  }

  // ============================================================
  // DISPOSE
  //
  // IMPORTANT:
  //
  // Screen close होने पर central GPS STOP नहीं होगा.
  //
  // केवल local listener detach होगा.
  // Actual GPS stop endWalk() में होगा.
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();

    _locationSubscription = null;

    super.dispose();
  }
}
