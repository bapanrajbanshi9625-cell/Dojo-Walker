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

  // ============================================================
  // CANONICAL GPS SERVICE
  //
  // IMPORTANT:
  // This screen NEVER starts or stops GPS.
  //
  // GPS lifecycle:
  //
  // ACCEPT  -> GPS ON
  // REACHED -> GPS stays ON
  // LIVE    -> GPS stays ON
  // COMPLETE -> GPS OFF
  //
  // The actual GPS owner is:
  // WalkerLocationService.instance
  // ============================================================

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  // ============================================================
  // LOCAL LOCATION SUBSCRIPTION
  //
  // This subscription only listens to the canonical GPS stream.
  // It does NOT control GPS lifecycle.
  // ============================================================

  StreamSubscription<Position>? _locationSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
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

    return value.isEmpty ? 'Owner' : value;
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
  // CANONICAL WALK REQUEST ID
  //
  // walk_request/{requestId}
  //
  // Example:
  // walk_request/DW000001
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
        widget.request.status.trim().toLowerCase() ==
            'accepted';

    // ----------------------------------------------------------
    // IMPORTANT:
    //
    // We only LISTEN to the canonical GPS service.
    //
    // We do NOT call startTracking() here.
    //
    // AcceptService is the ONLY GPS ON guard.
    // ----------------------------------------------------------

    _listenToCanonicalLocation();

    _startRequestMonitoring();

    // ----------------------------------------------------------
    // Before acceptance, GPS is intentionally not required.
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // If GPS is already running and a position is available,
    // immediately use it.
    //
    // This is especially useful when this screen is restored
    // after acceptance.
    // ----------------------------------------------------------

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
  // FIRESTORE REQUEST MONITOR
  // ============================================================

  void _startRequestMonitoring() {
    final String requestId = _requestId;

    if (requestId.isEmpty) {
      debugPrint(
        'IncomingWalkRequestScreen: request ID is empty.',
      );
      return;
    }

    final DocumentReference<Map<String, dynamic>> requestRef =
        _firestore
            .collection('walk_request')
            .doc(requestId);

    _requestSubscription = requestRef.snapshots().listen(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!mounted || _leavingScreen) {
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

        // --------------------------------------------------------
        // CURRENT WALKER ACCEPTED
        // --------------------------------------------------------

        if (status == 'accepted' &&
            _isCurrentWalker(walkerUid)) {
          if (!_accepted) {
            setState(() {
              _accepted = true;
              _loadingLocation = true;
            });

            // ----------------------------------------------------
            // IMPORTANT:
            //
            // Do NOT start GPS here.
            //
            // acceptWalk() already started canonical GPS.
            // ----------------------------------------------------
          }

          return;
        }

        // --------------------------------------------------------
        // REQUEST IS STILL SEARCHING
        // --------------------------------------------------------

        if (status == 'searching') {
          return;
        }

        // --------------------------------------------------------
        // SOMEONE ELSE ACCEPTED / REQUEST CHANGED
        // --------------------------------------------------------

        if (!_accepted && status.isNotEmpty) {
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
  // UPDATE WALKER LOCATION
  //
  // This receives locations from the ONE canonical GPS stream.
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

    const double walkingSpeedKmH = 5;

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
  //
  // ACCEPT = GPS ON
  //
  // InstaWalkAcceptService is responsible for starting the
  // canonical WalkerLocationService.
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
      // --------------------------------------------------------
      // ACCEPT SERVICE
      //
      // This is the GPS ON guard.
      // --------------------------------------------------------

      await _acceptService.acceptWalk(
        requestId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _accepted = true;
        _loadingLocation = true;
      });

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
  //
  // Reject is BEFORE acceptance, so GPS has not been started
  // by this screen.
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
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'You will not be able to accept this request again.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  false,
                );
              },
              child: const Text(
                'CANCEL',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  true,
                );
              },
              child: const Text(
                'REJECT',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w900,
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
  //
  // IMPORTANT:
  //
  // REACHED DOES NOT TURN GPS OFF.
  //
  // GPS remains owned by WalkerLocationService.
  //
  // Flow:
  //
  // ACCEPT
  //   ↓
  // GPS ON
  //   ↓
  // WALK TO OWNER
  //   ↓
  // WITHIN 100m
  //   ↓
  // REACHED
  //   ↓
  // GPS STILL ON
  //   ↓
  // LIVE WALK
  // ============================================================

  Future<void> _reachOwner() async {
    if (!_accepted ||
        _reaching ||
        _requestUnavailable ||
        _leavingScreen) {
      return;
    }

    // ----------------------------------------------------------
    // OWNER LOCATION
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // WALKER LOCATION
    // ----------------------------------------------------------

    if (_walkerPosition == null) {
      _showMessage(
        'Your current location is unavailable.',
      );
      return;
    }

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    if (_distanceMeters > 100) {
      _showMessage(
        'Please reach within 100 m of the owner.',
      );
      return;
    }

    // ----------------------------------------------------------
    // CANONICAL REQUEST ID
    // ----------------------------------------------------------

    final String requestId =
        _requestId;

    if (requestId.isEmpty) {
      debugPrint(
        'REACH ERROR: requestId is empty.',
      );

      _showMessage(
        'Walk ID is missing from the accepted walk request.',
      );
      return;
    }

    // ----------------------------------------------------------
    // FIREBASE AUTH USER
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // WALKER ID
    // ----------------------------------------------------------

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
      // --------------------------------------------------------
      // CREATE LIVE WALK SESSION
      //
      // liveWalkSessions/{requestId}
      //
      // SAME CANONICAL WALK ID.
      // --------------------------------------------------------

      await _reachService.createLiveWalkSession(
        walkRequestId: requestId,
        walkerUid: walkerUid,
        walkerId: walkerId,
      );

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // STOP REQUEST MONITOR
      // --------------------------------------------------------

      await _requestSubscription?.cancel();

      _requestSubscription = null;

      // --------------------------------------------------------
      // IMPORTANT:
      //
      // DO NOT STOP GPS HERE.
      //
      // The old code cancelled the local GPS stream because
      // LiveWalkScreen was expected to manage GPS.
      //
      // That architecture is now removed.
      //
      // Canonical GPS continues running.
      //
      // We only cancel THIS SCREEN'S local listener.
      // WalkerLocationService itself remains ON.
      // --------------------------------------------------------

      await _locationSubscription?.cancel();

      _locationSubscription = null;

      if (!mounted) {
        return;
      }

      _leavingScreen = true;

      // --------------------------------------------------------
      // OPEN LIVE WALK
      //
      // LiveWalkScreen will attach to the same canonical GPS
      // service through LiveWalkBackgroundService.
      // --------------------------------------------------------

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (
            BuildContext context,
          ) {
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
          // ======================================================
          // MAP
          // ======================================================

          Positioned.fill(
            child: IncomingWalkMap(
              walkerLocation:
                  _walkerLocation,
              ownerLocation:
                  _ownerLocation,
            ),
          ),

          // ======================================================
          // TOP BAR
          // ======================================================

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

          // ======================================================
          // BOTTOM PANEL
          // ======================================================

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IncomingWalkBottomPanel(
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

          // ======================================================
          // LOCATION LOADING
          // ======================================================

          if (_loadingLocation && _accepted)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.white70,
                  child: Center(
                    child:
                        CircularProgressIndicator(),
                  ),
                ),
              ),
            ),

          // ======================================================
          // REQUEST UNAVAILABLE
          // ======================================================

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
  //
  // IMPORTANT:
  //
  // We cancel only this screen's subscription.
  //
  // We DO NOT call:
  //
  // _locationService.stopTracking()
  //
  // because GPS must remain ON until Complete.
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
