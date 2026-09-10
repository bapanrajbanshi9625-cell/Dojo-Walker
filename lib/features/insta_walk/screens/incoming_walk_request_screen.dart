import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../services/walker_location_service.dart';
import '../../live_walk/screens/live_walk_start_screen.dart';
import '../models/insta_walk_request.dart';
import '../services/insta_walk_accept_service.dart';
import '../services/insta_walk_reach_service.dart';
import '../services/insta_walk_reject_service.dart';
import '../services/walker_route_service.dart';
import '../widgets/incoming_walk_bottom_panel.dart';
import '../widgets/incoming_walk_map.dart';
import '../widgets/incoming_walk_top_bar.dart';

class IncomingWalkRequestScreen extends StatefulWidget {
  const IncomingWalkRequestScreen({
    super.key,
    required this.request,
  });

  final InstaWalkRequest request;

  @override
  State<IncomingWalkRequestScreen> createState() =>
      _IncomingWalkRequestScreenState();
}

class _IncomingWalkRequestScreenState
    extends State<IncomingWalkRequestScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final InstaWalkAcceptService _acceptService =
      InstaWalkAcceptService.instance;

  final InstaWalkRejectService _rejectService =
      InstaWalkRejectService.instance;

  final InstaWalkReachService _reachService =
      InstaWalkReachService.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  final WalkerRouteService _routeService =
      WalkerRouteService.instance;

  StreamSubscription<Position>? _locationSubscription;

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  Position? _walkerPosition;

  bool _loadingLocation = true;
  bool _accepting = false;
  bool _rejecting = false;
  bool _accepted = false;
  bool _reaching = false;
  bool _requestUnavailable = false;
  bool _leavingScreen = false;

  double _distanceMeters = 0;

  // ============================================================
  // ROAD ROUTE
  // ============================================================

  List<LatLng> _routePoints =
      <LatLng>[];

  LatLng? _lastRouteStart;

  bool _routeLoading = false;

  // Refresh road route after approximately 50m movement.
  static const double _routeRefreshDistanceMeters =
      50;

  // ============================================================
  // OWNER DATA
  // ============================================================

  double? get _ownerLatitude {
    return widget.request.latitude;
  }

  double? get _ownerLongitude {
    return widget.request.longitude;
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

    return value.isEmpty
        ? 'Owner'
        : value;
  }

  String get _ownerPhone {
    return widget.request.ownerPhone.trim();
  }

  // ============================================================
  // CURRENT WALKER
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
  // DOG DATA
  // ============================================================

  String get _dogName {
    final String value =
        widget.request.dogName.trim();

    return value.isEmpty
        ? 'Your Pet'
        : value;
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

    _accepted =
        widget.request.status
                .trim()
                .toLowerCase() ==
            'accepted';

    _listenToCanonicalLocation();

    _startRequestMonitoring();

    // ----------------------------------------------------------
    // IMPORTANT:
    //
    // When the Accepted strip reopens this screen, the canonical
    // GPS service may already be tracking but its cached position
    // can be temporarily unavailable.
    //
    // Restore the current position without starting/stopping
    // canonical GPS tracking from this screen.
    // ----------------------------------------------------------
    if (_accepted) {
      unawaited(
        _restoreLocationOnReopen(),
      );
    }

    if (!_accepted && mounted) {
      _loadingLocation = false;
    }
  }

  // ============================================================
  // CANONICAL LOCATION LISTENER
  // ============================================================

  void _listenToCanonicalLocation() {
    _locationSubscription?.cancel();

    _locationSubscription =
        _locationService.locationStream.listen(
      _updateWalkerLocation,
      onError: (Object error) {
        debugPrint(
          'Incoming walk canonical GPS error: $error',
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
    } else if (_accepted && mounted) {
      _loadingLocation = true;
    }
  }

  // ============================================================
  // RESTORE LOCATION ON SCREEN REOPEN
  // ============================================================

  Future<void> _restoreLocationOnReopen() async {
    if (!_accepted ||
        _leavingScreen ||
        !mounted) {
      return;
    }

    // ----------------------------------------------------------
    // First use the canonical cached position if available.
    // This avoids an unnecessary GPS request.
    // ----------------------------------------------------------

    final Position? cachedPosition =
        _locationService.currentPosition;

    if (cachedPosition != null) {
      _updateWalkerLocation(
        cachedPosition,
      );
      return;
    }

    // ----------------------------------------------------------
    // No cached position:
    //
    // Ask the canonical location service for one fresh position.
    // This does NOT start/stop WalkerLocationService tracking.
    // ----------------------------------------------------------

    if (mounted) {
      setState(() {
        _loadingLocation = true;
      });
    }

    final Position? freshPosition =
        await _locationService.refreshLocation();

    if (!mounted ||
        _leavingScreen) {
      return;
    }

    if (freshPosition != null) {
      _updateWalkerLocation(
        freshPosition,
      );
    } else {
      setState(() {
        _loadingLocation = false;
      });
    }
  }

  // ============================================================
  // FIRESTORE REQUEST MONITOR
  // ============================================================

  void _startRequestMonitoring() {
    final String requestId =
        _requestId;

    if (requestId.isEmpty) {
      debugPrint(
        'IncomingWalkRequestScreen: request ID is empty.',
      );
      return;
    }

    final DocumentReference<
        Map<String, dynamic>> requestRef =
        _firestore
            .collection('walk_request')
            .doc(requestId);

    _requestSubscription =
        requestRef.snapshots().listen(
      (
        DocumentSnapshot<
            Map<String, dynamic>> snapshot,
      ) {
        if (!mounted ||
            _leavingScreen) {
          return;
        }

        if (!snapshot.exists) {
          _handleRequestUnavailable(
            'This walk request is no longer available.',
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

        final String walkerUid =
            data['walkerUid']
                    ?.toString()
                    .trim() ??
                '';

        if (status == 'accepted' &&
            _isCurrentWalker(walkerUid)) {
          if (!_accepted) {
            setState(() {
              _accepted = true;
              _loadingLocation =
                  _locationService.currentPosition ==
                      null;
            });

            // --------------------------------------------------
            // If the screen becomes accepted through the
            // canonical Firestore listener, restore location too.
            // --------------------------------------------------
            unawaited(
              _restoreLocationOnReopen(),
            );
          }

          return;
        }

        if (status == 'searching') {
          return;
        }

        if (!_accepted &&
            status.isNotEmpty) {
          _handleRequestUnavailable(
            'This walk has already been accepted by another Walker.',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'Incoming walk monitor error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // CURRENT WALKER CHECK
  // ============================================================

  bool _isCurrentWalker(
    String walkerUid,
  ) {
    final String currentUid =
        _currentWalkerUid;

    final String incomingUid =
        walkerUid.trim();

    return currentUid.isNotEmpty &&
        incomingUid.isNotEmpty &&
        currentUid == incomingUid;
  }

  // ============================================================
  // REQUEST UNAVAILABLE
  // ============================================================

  void _handleRequestUnavailable(
    String message,
  ) {
    if (!mounted ||
        _leavingScreen ||
        _accepted) {
      return;
    }

    _leavingScreen = true;

    setState(() {
      _requestUnavailable = true;
    });

    _showMessage(message);

    Future<void>.delayed(
      const Duration(
        milliseconds: 900,
      ),
      () {
        if (!mounted) {
          return;
        }

        Navigator.of(context).pop();
      },
    );
  }

  // ============================================================
  // UPDATE WALKER LOCATION
  // ============================================================

  void _updateWalkerLocation(
    Position position,
  ) {
    final double? ownerLatitude =
        _ownerLatitude;

    final double? ownerLongitude =
        _ownerLongitude;

    double distance = 0;

    if (ownerLatitude != null &&
        ownerLongitude != null) {
      distance =
          Geolocator.distanceBetween(
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
      _loadingLocation = false;
    });

    // ----------------------------------------------------------
    // ROAD ROUTE REFRESH
    // ----------------------------------------------------------

    if (_accepted) {
      _maybeRefreshRoute(
        position,
      );
    }
  }

  // ============================================================
  // ROAD ROUTE
  // ============================================================

  Future<void> _maybeRefreshRoute(
    Position position,
  ) async {
    final double? ownerLatitude =
        _ownerLatitude;

    final double? ownerLongitude =
        _ownerLongitude;

    if (ownerLatitude == null ||
        ownerLongitude == null) {
      return;
    }

    final LatLng newStart =
        LatLng(
      position.latitude,
      position.longitude,
    );

    final LatLng destination =
        LatLng(
      ownerLatitude,
      ownerLongitude,
    );

    final LatLng? previousStart =
        _lastRouteStart;

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

      if (moved <
          _routeRefreshDistanceMeters) {
        return;
      }
    }

    _lastRouteStart =
        newStart;

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
              List<LatLng>.unmodifiable(
            route,
          );
        });
      }
    } catch (error) {
      debugPrint(
        'Incoming walk road route error: $error',
      );

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // Do NOT replace a valid road route with a straight line.
      //
      // If the next route request fails, the previous valid route
      // remains visible.
      // --------------------------------------------------------
    } finally {
      _routeLoading = false;
    }
  }

  // ============================================================
  // MAP LOCATIONS
  // ============================================================

  LatLng? get _walkerLocation {
    final Position? position =
        _walkerPosition;

    if (position == null) {
      return null;
    }

    return LatLng(
      position.latitude,
      position.longitude,
    );
  }

  LatLng? get _ownerLocation {
    final double? latitude =
        _ownerLatitude;

    final double? longitude =
        _ownerLongitude;

    if (latitude == null ||
        longitude == null) {
      return null;
    }

    return LatLng(
      latitude,
      longitude,
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
  // ETA
  // ============================================================

  String get _etaText {
    if (widget.request.durationMinutes > 0) {
      return '${widget.request.durationMinutes} min';
    }

    if (_distanceMeters <= 0) {
      return '—';
    }

    const double walkingSpeedKmH =
        5;

    final double minutes =
        (_distanceMeters / 1000) /
            walkingSpeedKmH *
            60;

    final int rounded =
        math.max(
      1,
      minutes.ceil(),
    );

    return '$rounded min';
  }

  // ============================================================
  // PAYMENT
  // ============================================================

  String get _paymentText {
    return 'After acceptance';
  }

  // ============================================================
  // REACH CONDITION
  // ============================================================

  bool get _canReachOwner {
    return _accepted &&
        !_requestUnavailable &&
        !_reaching &&
        !_leavingScreen &&
        _ownerLatitude != null &&
        _ownerLongitude != null &&
        _walkerPosition != null &&
        _distanceMeters <= 100;
  }

  // ============================================================
  // ACCEPT WALK
  // ============================================================

  Future<void> _acceptWalk() async {
    if (_accepting ||
        _rejecting ||
        _accepted ||
        _requestUnavailable ||
        _leavingScreen) {
      return;
    }

    final String requestId =
        _requestId;

    if (requestId.isEmpty) {
      _showMessage(
        'Walk request ID is missing.',
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

    setState(() {
      _accepting = true;
    });

    try {
      await _acceptService.acceptWalk(
        requestId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _accepted = true;
        _loadingLocation =
            _locationService.currentPosition ==
                null;
      });

      final Position? currentPosition =
          _locationService.currentPosition;

      if (currentPosition != null) {
        _updateWalkerLocation(
          currentPosition,
        );
      } else {
        // ------------------------------------------------------
        // If acceptance happened before the canonical GPS cache
        // became available, request one fresh location.
        // ------------------------------------------------------
        unawaited(
          _restoreLocationOnReopen(),
        );
      }

      _showMessage(
        'Walk accepted. Please reach the owner.',
      );
    } catch (error) {
      debugPrint(
        'Accept walk error: $error',
      );

      if (mounted) {
        _showMessage(
          _cleanException(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _accepting = false;
        });
      }
    }
  }

  // ============================================================
  // REJECT WALK
  // ============================================================

  Future<void> _rejectWalk() async {
    if (_accepting ||
        _rejecting ||
        _accepted ||
        _requestUnavailable ||
        _leavingScreen) {
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Reject Walk?',
            style: TextStyle(
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content: const Text(
            'You will not be able to accept this request again.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false);
              },
              child:
                  const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true);
              },
              child: const Text(
                'REJECT',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted ||
        confirm != true) {
      return;
    }

    final String requestId =
        _requestId;

    if (requestId.isEmpty) {
      _showMessage(
        'Walk request ID is missing.',
      );
      return;
    }

    setState(() {
      _rejecting = true;
    });

    try {
      await _rejectService.rejectWalk(
        requestId,
      );

      if (!mounted) {
        return;
      }

      _leavingScreen = true;

      Navigator.of(context).pop();
    } catch (error) {
      debugPrint(
        'Reject walk error: $error',
      );

      if (mounted) {
        _showMessage(
          _cleanException(error),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _rejecting = false;
        });
      }
    }
  }

  // ============================================================
  // REACH OWNER
  // ============================================================

  Future<void> _reachOwner() async {
    if (!_accepted ||
        _reaching ||
        _requestUnavailable ||
        _leavingScreen) {
      return;
    }

    final double? ownerLatitude =
        _ownerLatitude;

    final double? ownerLongitude =
        _ownerLongitude;

    if (ownerLatitude == null ||
        ownerLongitude == null) {
      _showMessage(
        'Owner location is unavailable.',
      );
      return;
    }

    if (_walkerPosition == null) {
      _showMessage(
        'Your current location is unavailable.',
      );
      return;
    }

    if (_distanceMeters > 100) {
      _showMessage(
        'Please reach within 100 m of the owner.',
      );
      return;
    }

    final String requestId =
        _requestId;

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
      await _reachService
          .createLiveWalkSession(
        walkRequestId: requestId,
        walkerUid: walkerUid,
        walkerId: walkerId,
      );

      if (!mounted) {
        return;
      }

      await _requestSubscription?.cancel();

      _requestSubscription = null;

      // --------------------------------------------------------
      // Cancel only this screen's listener.
      //
      // Canonical GPS remains ON.
      // --------------------------------------------------------

      await _locationSubscription?.cancel();

      _locationSubscription = null;

      if (!mounted) {
        return;
      }

      _leavingScreen = true;

      await Navigator.of(context)
          .pushReplacement(
        MaterialPageRoute<void>(
          builder:
              (BuildContext context) {
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
      _leavingScreen = false;

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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFE9EEF3),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IncomingWalkMap(
              walkerLocation:
                  _walkerLocation,
              ownerLocation:
                  _ownerLocation,
              routePoints:
                  _routePoints,
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: IncomingWalkTopBar(
              accepted: _accepted,
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
            child:
                IncomingWalkBottomPanel(
              dogName:
                  _dogName,
              dogBreed:
                  _dogBreed,
              ownerName:
                  _ownerName,
              ownerPhone:
                  _ownerPhone,
              distanceText:
                  _distanceText,
              etaText:
                  _etaText,
              paymentText:
                  _paymentText,
              address:
                  _address,
              accepted:
                  _accepted,
              canReachOwner:
                  _canReachOwner,
              onAccept:
                  _acceptWalk,
              onReject:
                  _rejectWalk,
              onReach:
                  _reachOwner,
              onChat:
                  null,
              accepting:
                  _accepting,
              rejecting:
                  _rejecting,
              reaching:
                  _reaching,
            ),
          ),

          // ----------------------------------------------------
          // IMPORTANT:
          //
          // Do not lock the entire screen while waiting for GPS.
          // GPS may take a few seconds to provide the first fix.
          // The user can still see/use the accepted screen.
          // ----------------------------------------------------

          if (_loadingLocation &&
              _accepted)
            const Positioned(
              top: 86,
              right: 14,
              child: _LocationLoadingBadge(),
            ),

          if (_requestUnavailable)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.white70,
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CLEAN ERROR
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
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(14),
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    unawaited(
      _locationSubscription?.cancel(),
    );

    unawaited(
      _requestSubscription?.cancel(),
    );

    super.dispose();
  }
}

class _LocationLoadingBadge
    extends StatelessWidget {
  const _LocationLoadingBadge();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 4,
      borderRadius:
          BorderRadius.circular(18),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 13,
              height: 13,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
                color: const Color(
                  0xFF1976D2,
                ),
              ),
            ),
            const SizedBox(width: 7),
            const Text(
              'Getting location',
              style: TextStyle(
                fontSize: 11,
                fontWeight:
                    FontWeight.w800,
                color: Color(
                  0xFF374151,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
