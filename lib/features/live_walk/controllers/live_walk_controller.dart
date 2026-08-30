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

  StreamSubscription<Position>?
      _locationSubscription;

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
  bool get startingWalk =>
      _startingWalk;
  bool get walkStarted =>
      _walkStarted;
  bool get gpsReady =>
      _gpsReady;

  double get totalDistanceKm =>
      _totalDistanceKm;

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
    final String value =
        sessionId?.trim() ?? '';

    if (value.isNotEmpty) {
      return value;
    }

    return 'session-$walkId';
  }

  // ============================================================
  // SESSION REF
  // ============================================================

  DocumentReference<
          Map<String, dynamic>>
      get sessionRef {
    return _firestore
        .collection('liveWalkSessions')
        .doc(cleanSessionId);
  }

  // ============================================================
  // SESSION STREAM
  // ============================================================

  Stream<
          DocumentSnapshot<
              Map<String, dynamic>>>
      get sessionStream {
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

      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await sessionRef.get();

      if (snapshot.exists) {
        final Map<String, dynamic>?
            data =
            snapshot.data();

        if (data != null) {
          updateFromSession(data);
        }
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
      await _locationSubscription
          ?.cancel();

      _locationSubscription =
          _backgroundService
              .locationStream
              .listen(
        _handlePosition,
        onError: (Object error) {
          debugPrint(
            'Live GPS stream error: $error',
          );
        },
        cancelOnError: false,
      );

      final Position? position =
          _backgroundService
              .lastPosition;

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
  // DISTANCE / STEPS
  // ============================================================

  void _updateDistance() {
    final double distance =
        _backgroundService
            .totalDistanceKm;

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
  // FIRESTORE SESSION UPDATE
  // ============================================================

  void updateFromSession(
    Map<String, dynamic> data,
  ) {
    final dynamic rawDistance =
        data['distanceKm'];

    if (rawDistance is num) {
      _totalDistanceKm =
          rawDistance.toDouble();
    }

    final dynamic rawSteps =
        data['steps'];

    if (rawSteps is num) {
      _steps = rawSteps.toInt();
    }

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

    final dynamic currentLocation =
        data['currentLocation'];

    if (currentLocation is Map) {
      final dynamic lat =
          currentLocation['lat'] ??
              currentLocation[
                  'latitude'];

      final dynamic lng =
          currentLocation['lng'] ??
              currentLocation[
                  'longitude'];

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
      final String walkerUid =
          currentWalkerUid;

      if (walkerUid.isEmpty) {
        throw Exception(
          'Walker UID is missing.',
        );
      }

      await _sessionService.startWalk(
        sessionId: cleanSessionId,
        walkId: walkId,
        ownerUid: ownerUid,
        ownerName: ownerName,
        dogName: dogName,
        dogBreed: dogBreed,
        walkerUid: walkerUid,
      );

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
      _updateDistance();

      // --------------------------------------------------------
      // 1. COMPLETE SESSION + ACTIVE WALK
      // --------------------------------------------------------

      await _sessionService.completeWalk(
        sessionId: cleanSessionId,
        walkId: walkId,
      );

      // --------------------------------------------------------
      // 2. COMPLETE WALK REQUEST
      // --------------------------------------------------------

      await _walkRequestService.endLiveWalk(
        walkId,
        sessionId: cleanSessionId,
      );

      // --------------------------------------------------------
      // 3. STOP GPS
      // --------------------------------------------------------

      await _stopGps();

      _walkStarted = false;
      _gpsReady = false;

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Live walk end error: $e',
      );

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
    await _locationSubscription
        ?.cancel();

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
  // ============================================================

  @override
  void dispose() {
    _locationSubscription
        ?.cancel();

    _locationSubscription = null;

    super.dispose();
  }
}
