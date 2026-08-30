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

  double _distanceKm = 0.0;
  int _steps = 0;

  Map<String, dynamic> _sessionData =
      <String, dynamic>{};

  StreamSubscription<
          DocumentSnapshot<Map<String, dynamic>>>?
      _sessionSubscription;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get walkStarted => _walkStarted;

  bool get startingWalk => _startingWalk;

  bool get endingWalk => _endingWalk;

  // ------------------------------------------------------------
  // IMPORTANT COMPATIBILITY GETTER
  //
  // LiveWalkScreen "ending" use karta hai.
  // Isliye ending alias provide kiya gaya hai.
  // ------------------------------------------------------------

  bool get ending => _endingWalk;

  bool get busy =>
      _startingWalk || _endingWalk;

  double get distanceKm => _distanceKm;

  // ------------------------------------------------------------
  // LiveWalkScreen compatibility
  // ------------------------------------------------------------

  double get totalDistanceKm => _distanceKm;

  int get steps => _steps;

  Map<String, dynamic> get sessionData =>
      Map<String, dynamic>.unmodifiable(
        _sessionData,
      );

  // ------------------------------------------------------------
  // GPS READY
  //
  // GPS background service already runs independently.
  // Actual map readiness is determined from session data.
  // ------------------------------------------------------------

  bool get gpsReady {
    final dynamic location =
        _sessionData['currentLocation'];

    return location != null;
  }

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
  //
  // Live Walk screen open hone par:
  //
  // 1. Existing session read
  // 2. Existing state restore
  // 3. Distance / steps restore
  // 4. Firestore listener start
  //
  // GPS ko yahan start nahi kiya jata.
  // ============================================================

  Future<void> initialize() async {
    try {
      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await _sessionService
              .sessionRef(sessionId)
              .get();

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() ??
                <String, dynamic>{};

        updateFromSession(data);
      }

      syncDistance();

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
            'LiveWalkSessionController session stream error: $error',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'LiveWalkSessionController.initialize: $e',
      );
    }
  }

  // ============================================================
  // UPDATE FROM FIRESTORE
  // ============================================================

  void updateFromSession(
    Map<String, dynamic> data,
  ) {
    if (data.isEmpty) {
      return;
    }

    _sessionData =
        Map<String, dynamic>.from(data);

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double? firestoreDistance =
        _readDouble(
      data['distanceKm'],
    );

    if (firestoreDistance != null &&
        firestoreDistance >= 0) {
      _distanceKm =
          firestoreDistance;
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
    } else if (status == 'completed' ||
        status == 'ended') {
      _walkStarted = false;
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
  // GPS START YAHAN NAHI HOTA.
  //
  // GPS Insta Walk / Active Walk phase mein already
  // available ho sakta hai.
  //
  // Slider complete hone par sirf Live Walk session
  // active hota hai.
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

      // --------------------------------------------------------
      // Local state
      // --------------------------------------------------------

      _sessionData = <String, dynamic>{
        ..._sessionData,
        'walkId': walkId,
        'ownerUid': ownerUid,
        'ownerName': ownerName,
        'dogName': dogName,
        'dogBreed': dogBreed,
        'status': 'active',
        'walkStarted': true,
      };
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
  // 2. walk request -> ended
  // 3. GPS -> stop
  //
  // Agar step 1 ya 2 fail hua:
  // GPS stop nahi hoga.
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
        walkId: walkId,
      );

      // ========================================================
      // 2. END WALK REQUEST
      // ========================================================

      await _walkRequestService.endLiveWalk(
        walkId,
        sessionId: sessionId,
      );

      // ========================================================
      // 3. ONLY AFTER FIRESTORE COMPLETION
      //    STOP GPS
      // ========================================================

      await _stopGps();

      _walkStarted = false;

      _sessionData = <String, dynamic>{
        ..._sessionData,
        'status': 'completed',
        'walkStarted': false,
        'walkEnded': true,
        'trackingEnded': true,
      };
    } catch (e) {
      debugPrint(
        'LiveWalkSessionController.endWalk: $e',
      );

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // Failure hone par GPS intentionally running rahega.
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

    _distanceKm = 0.0;
    _steps = 0;

    _sessionData =
        <String, dynamic>{};

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
