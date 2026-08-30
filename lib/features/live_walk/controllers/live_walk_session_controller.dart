import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/live_walk_background_service.dart';
import '../../../core/services/live_walk_session_service.dart';
import '../../../services/walk_request_service.dart';

class LiveWalkSessionController extends ChangeNotifier {
  LiveWalkSessionController({
    required this.walkId,
    required this.ownerUid,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    this.ownerPhone,
    String? sessionId,
  }) : sessionId = _cleanSessionId(
          sessionId,
          walkId,
        );

  // ============================================================
  // DATA
  // ============================================================

  final String walkId;
  final String ownerUid;
  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  final String sessionId;

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
  // STATE
  // ============================================================

  bool _walkStarted = false;
  bool _startingWalk = false;
  bool _endingWalk = false;
  bool _gpsReady = false;

  double _distanceKm = 0.0;
  int _steps = 0;

  StreamSubscription<
          DocumentSnapshot<Map<String, dynamic>>>?
      _sessionSubscription;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get walkStarted => _walkStarted;

  bool get startingWalk => _startingWalk;

  bool get endingWalk => _endingWalk;

  bool get busy =>
      _startingWalk || _endingWalk;

  bool get gpsReady => _gpsReady;

  double get distanceKm => _distanceKm;

  // Compatibility with existing screen.
  double get totalDistanceKm => _distanceKm;

  int get steps => _steps;

  // ============================================================
  // SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get sessionStream {
    return _sessionService
        .sessionRef(sessionId)
        .snapshots();
  }

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    try {
      _gpsReady = true;

      syncDistance();

      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await _sessionService
              .sessionRef(sessionId)
              .get();

      final Map<String, dynamic> data =
          snapshot.data() ??
              <String, dynamic>{};

      if (data.isNotEmpty) {
        updateFromSession(data);
      }

      _listenToSession();

      notifyListeners();
    } catch (e) {
      debugPrint(
        'LiveWalkSessionController.initialize: $e',
      );

      _gpsReady = true;

      _listenToSession();

      notifyListeners();
    }
  }

  // ============================================================
  // SESSION LISTENER
  // ============================================================

  void _listenToSession() {
    _sessionSubscription?.cancel();

    _sessionSubscription =
        sessionStream.listen(
      (
        DocumentSnapshot<
                Map<String, dynamic>>
            snapshot,
      ) {
        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        if (data.isEmpty) {
          return;
        }

        updateFromSession(data);
      },
      onError: (Object error) {
        debugPrint(
          'LiveWalkSessionController.sessionStream: $error',
        );
      },
    );
  }

  // ============================================================
  // UPDATE FROM SESSION
  // ============================================================

  void updateFromSession(
    Map<String, dynamic> data,
  ) {
    final String status =
        data['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    // ----------------------------------------------------------
    // STATUS
    // ----------------------------------------------------------

    if (status == 'active' ||
        status == 'started' ||
        status == 'live') {
      _walkStarted = true;
    }

    if (status == 'completed' ||
        status == 'ended') {
      _walkStarted = false;
      _endingWalk = false;
    }

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double? firestoreDistance =
        _readDouble(
      data['distanceKm'],
    );

    if (firestoreDistance != null &&
        firestoreDistance >= 0) {
      _distanceKm = firestoreDistance;
    } else {
      syncDistance();
    }

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final int? firestoreSteps =
        _readInt(
      data['steps'],
    );

    if (firestoreSteps != null &&
        firestoreSteps >= 0) {
      _steps = firestoreSteps;
    }

    // ----------------------------------------------------------
    // GPS
    // ----------------------------------------------------------

    if (data['currentLocation'] != null ||
        data['routePoints'] != null ||
        data['routeCoordinates'] != null) {
      _gpsReady = true;
    }

    notifyListeners();
  }

  // ============================================================
  // DISTANCE SYNC
  // ============================================================

  void syncDistance() {
    final double distance =
        _backgroundService.totalDistanceKm;

    if (distance < 0) {
      return;
    }

    if (_distanceKm == distance) {
      return;
    }

    _distanceKm = distance;

    notifyListeners();
  }

  // ============================================================
  // START WALK
  //
  // IMPORTANT:
  //
  // यह method GPS start नहीं करता.
  //
  // GPS पहले से Insta Walk / Reach flow में चल सकता है.
  //
  // यह केवल Live Walk session को ACTIVE करता है.
  // ============================================================

  Future<void> startWalk() async {
    if (_walkStarted ||
        _startingWalk ||
        _endingWalk) {
      return;
    }

    _startingWalk = true;

    notifyListeners();

    try {
      await _sessionService.startWalk(
        sessionId: sessionId,
        walkId: walkId,
        ownerUid: ownerUid,
        ownerName: ownerName,
        dogName: dogName,
        dogBreed: dogBreed,
        walkerUid: '',
        walkerId: '',
        walkerName: '',
        walkerPhone: '',
      );

      _walkStarted = true;
    } catch (e) {
      debugPrint(
        'LiveWalkSessionController.startWalk: $e',
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
  // 1. liveWalkSessions -> completed
  // 2. active_walks -> completed
  // 3. walk request -> ended
  // 4. GPS -> STOP
  //
  // GPS completion से पहले STOP नहीं होगा.
  // ============================================================

  Future<void> endWalk() async {
    if (_endingWalk) {
      return;
    }

    if (!_walkStarted) {
      throw Exception(
        'Please start the walk first.',
      );
    }

    _endingWalk = true;

    notifyListeners();

    try {
      // --------------------------------------------------------
      // 1. COMPLETE LIVE SESSION
      // --------------------------------------------------------

      await _sessionService.completeWalk(
        sessionId: sessionId,
        walkId: walkId,
      );

      // --------------------------------------------------------
      // 2. END WALK REQUEST
      // --------------------------------------------------------

      await _walkRequestService.endLiveWalk(
        walkId,
        sessionId: sessionId,
      );

      // --------------------------------------------------------
      // 3. ONLY NOW STOP GPS
      // --------------------------------------------------------

      await _stopGps();

      _walkStarted = false;
      _gpsReady = false;
    } catch (e) {
      debugPrint(
        'LiveWalkSessionController.endWalk: $e',
      );

      // GPS intentionally remains running
      // if any completion operation fails.

      rethrow;
    } finally {
      _endingWalk = false;

      notifyListeners();
    }
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> _stopGps() async {
    try {
      await _backgroundService.stop();

      _gpsReady = false;
    } catch (e) {
      debugPrint(
        'Live GPS stop error: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // FIRESTORE STATUS SYNC
  // ============================================================

  void syncFirestoreStatus(
    String? status,
  ) {
    final String value =
        status?.trim().toLowerCase() ?? '';

    if (value == 'active' ||
        value == 'started' ||
        value == 'live') {
      if (!_walkStarted) {
        _walkStarted = true;
        notifyListeners();
      }

      return;
    }

    if (value == 'completed' ||
        value == 'ended') {
      if (_walkStarted) {
        _walkStarted = false;
        notifyListeners();
      }
    }
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    _walkStarted = false;
    _startingWalk = false;
    _endingWalk = false;
    _gpsReady = false;

    _distanceKm = 0.0;
    _steps = 0;

    notifyListeners();
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double? _readDouble(
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

  int? _readInt(
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
  // SESSION ID CLEANER
  // ============================================================

  static String _cleanSessionId(
    String? value,
    String walkId,
  ) {
    final String clean =
        value?.trim() ?? '';

    if (clean.isNotEmpty) {
      return clean;
    }

    return 'session-${walkId.trim()}';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    _sessionSubscription = null;

    super.dispose();
  }
}
