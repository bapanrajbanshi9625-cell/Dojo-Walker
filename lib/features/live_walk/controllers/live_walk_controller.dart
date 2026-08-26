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
    final String? value =
        sessionId?.trim();

    if (value != null &&
        value.isNotEmpty) {
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
  // यहां GPS START नहीं किया जाता.
  //
  // Insta Walk Active/Search flow से GPS पहले ही
  // शुरू हो चुका होगा.
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
  // DISTANCE
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

    if (status == 'active' ||
        status == 'started') {
      _walkStarted = true;
    }

    if (status == 'completed' ||
        status == 'ended') {
      _walkStarted = false;
    }

    // ----------------------------------------------------------
    // GPS
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
  // GPS पहले से RUNNING है.
  //
  // यहां सिर्फ Firestore/session को START किया जाएगा.
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
      await _sessionService.startWalk(
        sessionId: cleanSessionId,
        walkId: walkId,
        ownerUid: ownerUid,
        ownerName: ownerName,
        dogName: dogName,
        dogBreed: dogBreed,
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
  //
  // ORDER:
  //
  // 1. Firestore completed
  // 2. Walk request completed
  // 3. GPS STOP
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
      // COMPLETE SESSION
      // --------------------------------------------------------

      await _sessionService.completeWalk(
        sessionId: cleanSessionId,
      );

      // --------------------------------------------------------
      // END WALK REQUEST
      // --------------------------------------------------------

      await _walkRequestService.endLiveWalk(
        walkId,
        sessionId: cleanSessionId,
      );

      // --------------------------------------------------------
      // ONLY NOW STOP GPS
      // --------------------------------------------------------

      await _stopGps();

      _walkStarted = false;
      _gpsReady = false;

      notifyListeners();
    } catch (e) {
      debugPrint(
        'Live walk end error: $e',
      );

      // --------------------------------------------------------
      // ERROR:
      //
      // GPS चलता रहेगा.
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
  // यहां GPS STOP नहीं करना है.
  //
  // Screen बंद होने पर भी central GPS चलता रहेगा.
  // केवल successful endWalk() के बाद GPS stop होगा.
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();

    _locationSubscription = null;

    super.dispose();
  }
}
