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
    this.dogBreed = '',
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

  double _totalDistanceKm = 0.0;

  int _steps = 0;

  bool _gpsReady = false;

  // ============================================================
  // ROUTE
  // ============================================================

  final List<Map<String, dynamic>> routeCoordinates =
      <Map<String, dynamic>>[];

  bool _routeLoaded = false;

  // ============================================================
  // GETTERS
  // ============================================================

  bool get initialized => _initialized;

  bool get ending => _ending;

  bool get startingWalk => _startingWalk;

  bool get walkStarted => _walkStarted;

  double get totalDistanceKm => _totalDistanceKm;

  int get steps => _steps;

  bool get gpsReady => _gpsReady;

  List<Map<String, dynamic>> get route =>
      List.unmodifiable(routeCoordinates);

  // ============================================================
  // SESSION ID
  // ============================================================

  String get resolvedSessionId {
    final String? value = sessionId?.trim();

    if (value != null && value.isNotEmpty) {
      return value;
    }

    return 'session-$walkId';
  }

  // ============================================================
  // FIRESTORE SESSION
  // ============================================================

  DocumentReference<Map<String, dynamic>>
      get sessionRef {
    return FirebaseFirestore.instance
        .collection('liveWalkSessions')
        .doc(resolvedSessionId);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get sessionStream {
    return sessionRef.snapshots();
  }

  // ============================================================
  // INITIALIZE
  //
  // IMPORTANT:
  //
  // यहां GPS START नहीं होता.
  //
  // Active Insta Walk flow से GPS पहले से चालू होना चाहिए.
  // यहां सिर्फ उसी existing stream को attach किया जाता है.
  // ============================================================

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initialized = true;

    await _attachExistingGps();

    notifyListeners();
  }

  // ============================================================
  // ATTACH EXISTING GPS
  // ============================================================

  Future<void> _attachExistingGps() async {
    if (_ending) {
      return;
    }

    try {
      await _locationSubscription?.cancel();

      _locationSubscription =
          _backgroundService.locationStream.listen(
        _onPosition,
        onError: (Object error) {
          debugPrint(
            'LiveWalkController GPS error: $error',
          );

          _gpsReady = false;
          notifyListeners();
        },
        cancelOnError: false,
      );

      final Position? currentPosition =
          _backgroundService.lastPosition;

      if (currentPosition != null) {
        _onPosition(currentPosition);
      } else {
        _gpsReady = false;
        notifyListeners();
      }
    } catch (e) {
      debugPrint(
        'LiveWalkController attach GPS error: $e',
      );

      _gpsReady = false;
      notifyListeners();
    }
  }

  // ============================================================
  // GPS POSITION
  // ============================================================

  void _onPosition(Position position) {
    if (_ending) {
      return;
    }

    _gpsReady = true;

    final double distance =
        _backgroundService.totalDistanceKm;

    if (distance >= 0) {
      _totalDistanceKm = distance;
    }

    notifyListeners();
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

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double? firestoreDistance =
        _toDouble(
      data['distanceKm'],
    );

    if (firestoreDistance != null &&
        firestoreDistance >= 0) {
      _totalDistanceKm = firestoreDistance;
    }

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final int? firestoreSteps =
        _toInt(
      data['steps'],
    );

    if (firestoreSteps != null &&
        firestoreSteps >= 0) {
      _steps = firestoreSteps;
    }

    // ----------------------------------------------------------
    // ROUTE
    // ----------------------------------------------------------

    if (!_routeLoaded) {
      _loadRoute(data);

      _routeLoaded = true;
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
      _walkStarted = true;
    }

    notifyListeners();
  }

  // ============================================================
  // LOAD ROUTE
  // ============================================================

  void _loadRoute(
    Map<String, dynamic> data,
  ) {
    final dynamic rawRoute =
        data['routeCoordinates'];

    if (rawRoute is! List) {
      return;
    }

    routeCoordinates.clear();

    for (final dynamic item in rawRoute) {
      if (item is! Map) {
        continue;
      }

      final double? lat =
          _toDouble(
        item['lat'] ??
            item['latitude'],
      );

      final double? lng =
          _toDouble(
        item['lng'] ??
            item['longitude'],
      );

      if (lat == null || lng == null) {
        continue;
      }

      if (!_validCoordinate(
        lat,
        lng,
      )) {
        continue;
      }

      routeCoordinates.add(
        <String, dynamic>{
          'lat': lat,
          'lng': lng,
          if (item['timestamp'] != null)
            'timestamp': item['timestamp'],
        },
      );
    }
  }

  // ============================================================
  // START WALK
  //
  // IMPORTANT:
  //
  // START SLIDER के बाद सिर्फ WALK SESSION START होगा.
  //
  // GPS दोबारा START नहीं होगा.
  // ============================================================

  Future<void> startWalk() async {
    if (_walkStarted ||
        _startingWalk ||
        _ending) {
      return;
    }

    _startingWalk = true;

    notifyListeners();

    try {
      await _sessionService.startWalk(
        sessionId: resolvedSessionId,
        walkId: walkId,
        ownerUid: ownerUid,
        ownerName: ownerName,
        dogName: dogName,
        dogBreed: dogBreed,
      );

      _walkStarted = true;
      _startingWalk = false;

      notifyListeners();
    } catch (e) {
      _startingWalk = false;

      notifyListeners();

      rethrow;
    }
  }

  // ============================================================
  // END WALK
  //
  // ORDER:
  //
  // 1. Firestore session complete
  // 2. Walk request complete
  // 3. GPS STOP
  //
  // Error होने पर GPS चलता रहेगा.
  // ============================================================

  Future<void> endWalk() async {
    if (_ending) {
      return;
    }

    if (!_walkStarted) {
      throw Exception(
        'Please start the walk first.',
      );
    }

    _ending = true;

    notifyListeners();

    try {
      // --------------------------------------------------------
      // COMPLETE SESSION
      // --------------------------------------------------------

      await _sessionService.completeWalk(
        sessionId: resolvedSessionId,
      );

      // --------------------------------------------------------
      // COMPLETE WALK REQUEST
      // --------------------------------------------------------

      await _walkRequestService.endLiveWalk(
        walkId,
        sessionId: resolvedSessionId,
      );

      // --------------------------------------------------------
      // ONLY NOW STOP GPS
      // --------------------------------------------------------

      await _stopGps();

      _ending = false;

      notifyListeners();
    } catch (e) {
      debugPrint(
        'LiveWalkController end walk error: $e',
      );

      // --------------------------------------------------------
      // IMPORTANT
      //
      // Error होने पर GPS STOP नहीं होगा.
      // --------------------------------------------------------

      _ending = false;

      notifyListeners();

      rethrow;
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
        'LiveWalkController GPS stop error: $e',
      );
    }

    _gpsReady = false;

    notifyListeners();
  }

  // ============================================================
  // SAFE DOUBLE
  // ============================================================

  double? _toDouble(
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
  // SAFE INT
  // ============================================================

  int? _toInt(
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
  // VALID COORDINATE
  // ============================================================

  bool _validCoordinate(
    double lat,
    double lng,
  ) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();

    // IMPORTANT:
    //
    // यहां GPS STOP नहीं करना है.
    //
    // क्योंकि Screen dispose होने से walk खत्म नहीं माना जाता.
    //
    // GPS सिर्फ endWalk() के successful completion के बाद
    // _stopGps() से बंद होगा.

    super.dispose();
  }
}
