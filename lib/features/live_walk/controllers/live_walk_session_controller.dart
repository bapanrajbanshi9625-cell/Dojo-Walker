import 'dart:async';

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

  double _distanceKm = 0.0;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get walkStarted => _walkStarted;

  bool get startingWalk => _startingWalk;

  bool get endingWalk => _endingWalk;

  bool get busy =>
      _startingWalk || _endingWalk;

  double get distanceKm => _distanceKm;

  // ============================================================
  // INITIAL DISTANCE
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
  // यह GPS START नहीं करता.
  //
  // GPS Insta Walk Active/Search phase से पहले
  // ही चल रहा है.
  //
  // Slider complete होने पर केवल WALK SESSION
  // active किया जाता है.
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
  // 1. Firestore session -> completed
  // 2. Walk request -> ended
  // 3. GPS -> STOP
  //
  // GPS completed होने से पहले कभी stop नहीं होगा.
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
      // ========================================================
      // 1. COMPLETE LIVE SESSION
      // ========================================================

      await _sessionService.completeWalk(
        sessionId: sessionId,
      );

      // ========================================================
      // 2. END WALK REQUEST
      // ========================================================

      await _walkRequestService.endLiveWalk(
        walkId,
        sessionId: sessionId,
      );

      // ========================================================
      // 3. ONLY NOW STOP GPS
      // ========================================================

      await _stopGps();

      _walkStarted = false;
    } catch (e) {
      debugPrint(
        'LiveWalkSessionController.endWalk: $e',
      );

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // अगर completion fail हुआ तो GPS बंद नहीं होगा.
      // --------------------------------------------------------

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
        value == 'started') {
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
    _distanceKm = 0.0;

    notifyListeners();
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

    return 'session-$walkId';
  }
}
