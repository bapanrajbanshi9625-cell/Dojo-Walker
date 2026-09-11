import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/walker_location_service.dart';
import '../../insta_walk/models/insta_walk_request.dart';
import '../../live_walk/screens/live_walk_start_screen.dart';
import '../services/accept_walk_reach_service.dart';
import '../services/walker_route_service.dart';
import '../widgets/accept_walk_bottom_panel.dart';
import '../widgets/accept_walk_map.dart';
import '../widgets/accept_walk_top_bar.dart';

class AcceptWalkScreen extends StatefulWidget {
  const AcceptWalkScreen({
    super.key,
    required this.request,
  });

  final InstaWalkRequest request;

  @override
  State<AcceptWalkScreen> createState() =>
      _AcceptWalkScreenState();
}

class _AcceptWalkScreenState
    extends State<AcceptWalkScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  final WalkerRouteService _routeService =
      WalkerRouteService.instance;

  final AcceptWalkReachService _reachService =
      AcceptWalkReachService.instance;

  StreamSubscription<Position>? _locationSubscription;

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  Position? _walkerPosition;

  bool _reaching = false;
  bool _requestUnavailable = false;
  bool _leavingScreen = false;

  double _distanceMeters = 0;

  List<LatLng> _routePoints = <LatLng>[];

  LatLng? _lastRouteStart;

  bool _routeLoading = false;

  static const double _routeRefreshDistanceMeters = 50;

  // ============================================================
  // OWNER
  // ============================================================

  double? get _ownerLatitude {
    return widget.request.latitude;
  }

  double? get _ownerLongitude {
    return widget.request.longitude;
  }

  LatLng? get _ownerLocation {
    final double? latitude = _ownerLatitude;
    final double? longitude = _ownerLongitude;

    if (latitude == null || longitude == null) {
      return null;
    }

    return LatLng(
      latitude,
      longitude,
    );
  }

  String get _ownerUid {
    final String authUid =
        widget.request.ownerAuthUid.trim();

    if (authUid.isNotEmpty) {
      return authUid;
    }

    final String uid =
        widget.request.ownerUid.trim();

    if (uid.isNotEmpty) {
      return uid;
    }

    return widget.request.ownerId.trim();
  }

  String get _ownerName {
    final String value =
        widget.request.ownerName.trim();

    return value.isEmpty ? 'Owner' : value;
  }

  String get _ownerPhone {
    return widget.request.ownerPhone.trim();
  }

  // ============================================================
  // WALKER
  // ============================================================

  String get _currentWalkerUid {
    return _auth.currentUser?.uid.trim() ?? '';
  }

  String get _walkerId {
    final String requestWalkerId =
        widget.request.walkerId.trim();

    if (requestWalkerId.isNotEmpty) {
      return requestWalkerId;
    }

    return _currentWalkerUid;
  }

  // ============================================================
  // DOG
  // ============================================================

  String get _dogName {
    final String value =
        widget.request.dogName.trim();

    return value.isEmpty ? 'Your Pet' : value;
  }

  String get _dogBreed {
    return widget.request.dogBreed.trim();
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  String get _address {
    final String pickup =
        widget.request.pickupAddress.trim();

    if (pickup.isNotEmpty) {
      return pickup;
    }

    return widget.request.address.trim();
  }

  // ============================================================
  // REQUEST ID
  // ============================================================

  String get _requestId {
    return widget.request.requestId.trim();
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _listenToCanonicalLocation();
    _startRequestMonitoring();

    unawaited(
      _restoreLocationOnReopen(),
    );
  }

  // ============================================================
  // CANONICAL LOCATION
  // ============================================================

  void _listenToCanonicalLocation() {
    _locationSubscription?.cancel();

    _locationSubscription =
        _locationService.locationStream.listen(
      _updateWalkerLocation,
      onError: (Object error) {
        debugPrint(
          'Accept walk canonical GPS error: $error',
        );
      },
      cancelOnError: false,
    );

    final Position? currentPosition =
        _locationService.currentPosition;

    if (currentPosition != null) {
      _updateWalkerLocation(
        currentPosition,
      );
    }
  }

  Future<void> _restoreLocationOnReopen() async {
    if (_leavingScreen || !mounted) {
      return;
    }

    final Position? cachedPosition =
        _locationService.currentPosition;

    if (cachedPosition != null) {
      _updateWalkerLocation(
        cachedPosition,
      );
      return;
    }

    final Position? freshPosition =
        await _locationService.refreshLocation();

    if (!mounted || _leavingScreen) {
      return;
    }

    if (freshPosition != null) {
      _updateWalkerLocation(
        freshPosition,
      );
    }
  }

  // ============================================================
  // REQUEST MONITOR
  // ============================================================

  void _startRequestMonitoring() {
    final String requestId = _requestId;

    if (requestId.isEmpty) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> requestRef =
        _firestore
            .collection('walk_request')
            .doc(requestId);

    _requestSubscription =
        requestRef.snapshots().listen(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!mounted || _leavingScreen) {
          return;
        }

        if (!snapshot.exists) {
          _handleUnavailable(
            'This accepted walk is no longer available.',
          );
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (status == 'accepted') {
          return;
        }

        if (status == 'completed' ||
            status == 'complete' ||
            status == 'finished' ||
            status == 'closed' ||
            status == 'cancelled') {
          _handleUnavailable(
            'This walk is no longer active.',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'Accept walk monitor error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // LOCATION
  // ============================================================

  void _updateWalkerLocation(
    Position position,
  ) {
    final double? ownerLatitude = _ownerLatitude;
    final double? ownerLongitude = _ownerLongitude;

    double distance = 0;

    if (ownerLatitude != null &&
        ownerLongitude != null) {
      distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        ownerLatitude,
        ownerLongitude,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _walkerPosition = position;
      _distanceMeters = distance;
    });

    _maybeRefreshRoute(position);
  }

  // ============================================================
  // ROAD ROUTE
  // ============================================================

  Future<void> _maybeRefreshRoute(
    Position position,
  ) async {
    final double? ownerLatitude = _ownerLatitude;
    final double? ownerLongitude = _ownerLongitude;

    if (ownerLatitude == null ||
        ownerLongitude == null) {
      return;
    }

    final LatLng newStart = LatLng(
      position.latitude,
      position.longitude,
    );

    final LatLng destination = LatLng(
      ownerLatitude,
      ownerLongitude,
    );

    final LatLng? previousStart = _lastRouteStart;

    if (_routeLoading) {
      return;
    }

    if (previousStart != null) {
      final double moved =
          Geolocator.distanceBetween(
        previousStart.latitude,
        previousStart.longitude,
        newStart.latitude,
        newStart.longitude,
      );

      if (moved < _routeRefreshDistanceMeters) {
        return;
      }
    }

    _lastRouteStart = newStart;
    _routeLoading = true;

    try {
      final List<LatLng> route =
          await _routeService.getRoute(
        start: newStart,
        destination: destination,
      );

      if (!mounted) {
        return;
      }

      if (route.length >= 2) {
        setState(() {
          _routePoints =
              List<LatLng>.unmodifiable(route);
        });
      }
    } catch (error) {
      debugPrint(
        'Accept walk road route error: $error',
      );

      // Keep previous valid road route.
    } finally {
      _routeLoading = false;
    }
  }

  // ============================================================
  // MAP
  // ============================================================

  LatLng? get _walkerLocation {
    final Position? position = _walkerPosition;

    if (position == null) {
      return null;
    }

    return LatLng(
      position.latitude,
      position.longitude,
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  String get _distanceText {
    if (_walkerPosition == null ||
        _ownerLocation == null) {
      return '—';
    }

    if (_distanceMeters < 1000) {
      return '${_distanceMeters.round()} m';
    }

    return '${(_distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  // ============================================================
  // TIME
  // ============================================================

  String get _timeText {
    if (_distanceMeters <= 0) {
      return '—';
    }

    const double walkingSpeedKmH = 5;

    final double minutes =
        (_distanceMeters / 1000) /
            walkingSpeedKmH *
            60;

    if (minutes < 1) {
      final int seconds =
          (minutes * 60).ceil();

      return '${seconds.clamp(1, 59)} sec';
    }

    return '${minutes.ceil()} min';
  }

  // ============================================================
  // REACH
  // ============================================================

  bool get _canReachOwner {
    return !_requestUnavailable &&
        !_reaching &&
        !_leavingScreen &&
        _walkerPosition != null &&
        _ownerLatitude != null &&
        _ownerLongitude != null &&
        _distanceMeters <= 100;
  }

  Future<void> _reachOwner() async {
    if (!_canReachOwner) {
      return;
    }

    final String requestId = _requestId;

    if (requestId.isEmpty) {
      _showMessage(
        'Walk ID is missing from the accepted walk request.',
      );
      return;
    }

    final User? currentUser =
        _auth.currentUser;

    if (currentUser == null) {
      _showMessage(
        'Walker authentication is unavailable.',
      );
      return;
    }

    final String walkerUid =
        currentUser.uid.trim();

    if (walkerUid.isEmpty) {
      _showMessage(
        'Walker UID is missing.',
      );
      return;
    }

    final String walkerId =
        _walkerId;

    if (walkerId.isEmpty) {
      _showMessage(
        'Walker ID is missing.',
      );
      return;
    }

    setState(() {
      _reaching = true;
    });

    try {
      await _reachService.createLiveWalkSession(
        walkRequestId: requestId,
        walkerUid: walkerUid,
        walkerId: walkerId,
      );

      if (!mounted) {
        return;
      }

      await _requestSubscription?.cancel();
      _requestSubscription = null;

      await _locationSubscription?.cancel();
      _locationSubscription = null;

      _leavingScreen = true;

      if (!mounted) {
        return;
      }

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return LiveWalkStartScreen(
              ownerUid: _ownerUid,
              ownerName: _ownerName,
              requestId: requestId,
              dogName: _dogName,
              dogBreed: _dogBreed,
              ownerPhone:
                  _ownerPhone.isEmpty
                      ? null
                      : _ownerPhone,
            );
          },
        ),
      );
    } catch (error) {
      debugPrint(
        'Reach owner error: $error',
      );

      if (mounted) {
        _showMessage(
          _cleanException(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _reaching = false;
        });
      }
    }
  }

  // ============================================================
  // UNAVAILABLE
  // ============================================================

  void _handleUnavailable(
    String message,
  ) {
    if (!mounted ||
        _leavingScreen ||
        _requestUnavailable) {
      return;
    }

    _leavingScreen = true;

    setState(() {
      _requestUnavailable = true;
    });

    _showMessage(message);

    Future<void>.delayed(
      const Duration(milliseconds: 900),
      () {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pop();
      },
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final LatLng? ownerLocation =
        _ownerLocation;

    final LatLng? walkerLocation =
        _walkerLocation;

    return Scaffold(
      backgroundColor: const Color(0xFFE9EEF3),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ownerLocation != null &&
                    walkerLocation != null
                ? AcceptWalkMap(
                    walkerLocation: walkerLocation,
                    ownerLocation: ownerLocation,
                    routePoints: _routePoints,
                  )
                : const ColoredBox(
                    color: Color(0xFFE9EEF3),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AcceptWalkTopBar(
              onBack: () {
                if (_leavingScreen) {
                  return;
                }

                Navigator.of(context).pop();
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AcceptWalkBottomPanel(
              dogName: _dogName,
              dogBreed: _dogBreed,
              ownerName: _ownerName,
              ownerPhone: _ownerPhone,
              distanceText: _distanceText,
              timeText: _timeText,
              address: _address,
              canReachOwner: _canReachOwner,
              reaching: _reaching,
              onReach: _reachOwner,
            ),
          ),
          if (_requestUnavailable)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white70,
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  String _cleanException(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _leavingScreen = true;

    _locationSubscription?.cancel();
    _requestSubscription?.cancel();

    super.dispose();
  }
}
