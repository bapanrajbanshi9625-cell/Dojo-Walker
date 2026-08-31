import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../live_walk/screens/live_walk_screen.dart';
import '../models/insta_walk_request.dart';
import '../services/insta_walk_accept_service.dart';
import '../services/insta_walk_reject_service.dart';
import '../widgets/active_walk_map.dart';
import '../widgets/active_walk_top_bar.dart';
import '../widgets/incoming_walk_bottom_sheet.dart';

class IncomingWalkRequestScreen extends StatefulWidget {
  final InstaWalkRequest request;

  const IncomingWalkRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<IncomingWalkRequestScreen> createState() =>
      _IncomingWalkRequestScreenState();
}

class _IncomingWalkRequestScreenState
    extends State<IncomingWalkRequestScreen> {
  // =============================================================
  // CONTROLLERS
  // =============================================================

  final MapController _mapController = MapController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final InstaWalkAcceptService _acceptService =
      InstaWalkAcceptService.instance;

  final InstaWalkRejectService _rejectService =
      InstaWalkRejectService.instance;

  // =============================================================
  // SUBSCRIPTIONS
  // =============================================================

  StreamSubscription<Position>? _locationSubscription;

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  // =============================================================
  // STATE
  // =============================================================

  Position? _walkerPosition;

  bool _loadingLocation = true;
  bool _accepting = false;
  bool _rejecting = false;
  bool _accepted = false;
  bool _reaching = false;
  bool _requestUnavailable = false;
  bool _leavingScreen = false;

  double _distanceMeters = 0;

  // =============================================================
  // REQUEST DATA
  // =============================================================

  double? get _ownerLatitude =>
      widget.request.latitude;

  double? get _ownerLongitude =>
      widget.request.longitude;

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

  String get _ownerPhone =>
      widget.request.ownerPhone.trim();

  String get _dogName {
    final String value =
        widget.request.dogName.trim();

    return value.isEmpty ? 'Dog' : value;
  }

  String get _dogBreed =>
      widget.request.dogBreed.trim();

  String get _address {
    final String pickup =
        widget.request.pickupAddress.trim();

    if (pickup.isNotEmpty) {
      return pickup;
    }

    return widget.request.address.trim();
  }

  String get _sessionId =>
      widget.request.liveWalkSessionId.trim();

  String get _walkId =>
      widget.request.id.trim();

  // =============================================================
  // INIT
  // =============================================================

  @override
  void initState() {
    super.initState();

    _accepted =
        widget.request.status.trim().toLowerCase() ==
            'accepted';

    unawaited(
      _startLocationTracking(),
    );

    _startRequestMonitoring();
  }

  // =============================================================
  // FIRESTORE REALTIME MONITOR
  // =============================================================

  void _startRequestMonitoring() {
    if (_walkId.isEmpty) {
      return;
    }

    final DocumentReference<
        Map<String, dynamic>> walkRef =
        _firestore
            .collection('walk_request')
            .doc(_walkId);

    _requestSubscription =
        walkRef.snapshots().listen(
      (
        DocumentSnapshot<Map<String, dynamic>>
            snapshot,
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

        if (status == 'accepted' &&
            _isCurrentWalker(walkerUid)) {
          if (!_accepted) {
            setState(() {
              _accepted = true;
            });
          }

          return;
        }

        if (!_accepted &&
            status.isNotEmpty &&
            status != 'searching') {
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
    );
  }

  // =============================================================
  // CURRENT WALKER
  // =============================================================

  bool _isCurrentWalker(
    String walkerUid,
  ) {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return false;
    }

    final String currentUid =
        user.uid.trim();

    final String incomingUid =
        walkerUid.trim();

    return currentUid.isNotEmpty &&
        incomingUid.isNotEmpty &&
        currentUid == incomingUid;
  }

  // =============================================================
  // REQUEST UNAVAILABLE
  // =============================================================

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

        Navigator.pop(context);
      },
    );
  }

  // =============================================================
  // LOCATION
  // =============================================================

  Future<void> _startLocationTracking() async {
    try {
      final bool serviceEnabled =
          await Geolocator
              .isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Please turn on Location/GPS.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is required.',
        );
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );

      if (!mounted) {
        return;
      }

      _updateWalkerLocation(position);

      _locationSubscription =
          Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        _updateWalkerLocation,
        onError: (Object error) {
          debugPrint(
            'Incoming walk GPS error: $error',
          );
        },
      );
    } catch (error) {
      debugPrint(
        'Incoming walk location error: $error',
      );

      _showMessage(
        'Unable to get your location.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
        });
      }
    }
  }

  void _updateWalkerLocation(
    Position position,
  ) {
    final double? latitude =
        _ownerLatitude;

    final double? longitude =
        _ownerLongitude;

    double distance = 0;

    if (latitude != null &&
        longitude != null) {
      distance =
          Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _walkerPosition = position;
      _distanceMeters = distance;
    });

    _fitMap();
  }

  // =============================================================
  // MAP FIT
  // =============================================================

  void _fitMap() {
    final Position? walker =
        _walkerPosition;

    final double? latitude =
        _ownerLatitude;

    final double? longitude =
        _ownerLongitude;

    if (walker == null ||
        latitude == null ||
        longitude == null) {
      return;
    }

    try {
      final LatLng walkerPoint =
          LatLng(
        walker.latitude,
        walker.longitude,
      );

      final LatLng ownerPoint =
          LatLng(
        latitude,
        longitude,
      );

      final LatLngBounds bounds =
          LatLngBounds.fromPoints(
        [
          walkerPoint,
          ownerPoint,
        ],
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding:
              const EdgeInsets.fromLTRB(
            45,
            120,
            45,
            390,
          ),
          maxZoom: 16,
        ),
      );
    } catch (error) {
      debugPrint(
        'Map fit error: $error',
      );
    }
  }

  // =============================================================
  // ACCEPT
  // =============================================================

  Future<void> _acceptWalk() async {
    if (_accepting ||
        _rejecting ||
        _accepted ||
        _requestUnavailable) {
      return;
    }

    if (_walkId.isEmpty) {
      _showMessage(
        'Walk request ID is missing.',
      );
      return;
    }

    setState(() {
      _accepting = true;
    });

    try {
      await _acceptService.acceptWalk(
        _walkId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _accepted = true;
      });

      _showMessage(
        'Walk accepted. Please reach the owner.',
      );
    } catch (error) {
      debugPrint(
        'Accept walk error: $error',
      );

      _showMessage(
        _cleanException(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _accepting = false;
        });
      }
    }
  }

  // =============================================================
  // REJECT
  // =============================================================

  Future<void> _rejectWalk() async {
    if (_accepting ||
        _rejecting ||
        _accepted ||
        _requestUnavailable) {
      return;
    }

    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
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
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'CANCEL',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
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

    if (confirm != true ||
        !mounted) {
      return;
    }

    if (_walkId.isEmpty) {
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
        _walkId,
      );

      if (!mounted) {
        return;
      }

      _leavingScreen = true;

      Navigator.pop(context);
    } catch (error) {
      debugPrint(
        'Reject walk error: $error',
      );

      _showMessage(
        _cleanException(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _rejecting = false;
        });
      }
    }
  }

  // =============================================================
  // REACH OWNER
  // =============================================================

  Future<void> _reachOwner() async {
    if (!_accepted ||
        _reaching ||
        _requestUnavailable) {
      return;
    }

    if (!_canReachOwner) {
      _showMessage(
        'Please reach within 100 m of the owner.',
      );
      return;
    }

    if (_walkId.isEmpty) {
      _showMessage(
        'Walk ID is missing.',
      );
      return;
    }

    if (_sessionId.isEmpty) {
      _showMessage(
        'Live Walk session is not ready yet.',
      );
      return;
    }

    setState(() {
      _reaching = true;
    });

    try {
      _leavingScreen = true;

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (
            BuildContext context,
          ) {
            return LiveWalkScreen(
              ownerUid: _ownerUid,
              ownerName: _ownerName,
              walkId: _walkId,
              dogName: _dogName,
              dogBreed: _dogBreed,
              ownerPhone:
                  _ownerPhone.isEmpty
                      ? null
                      : _ownerPhone,
              sessionId: _sessionId,
            );
          },
        ),
      );
    } catch (error) {
      _leavingScreen = false;

      debugPrint(
        'Live Walk navigation error: $error',
      );

      _showMessage(
        _cleanException(error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _reaching = false;
        });
      }
    }
  }

  // =============================================================
  // MAP DATA
  // =============================================================

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

  LatLng? get _pickupLocation {
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

  // =============================================================
  // DISTANCE
  // =============================================================

  String get _distanceText {
    if (_walkerPosition == null ||
        _pickupLocation == null) {
      return '—';
    }

    if (_distanceMeters < 1000) {
      return '${_distanceMeters.round()} m';
    }

    return '${(_distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  // =============================================================
  // ETA
  // =============================================================

  String get _etaText {
    if (widget.request.durationMinutes > 0) {
      return '${widget.request.durationMinutes} min';
    }

    if (_distanceMeters <= 0) {
      return '—';
    }

    const double speedKmH = 5;

    final double minutes =
        (_distanceMeters / 1000) /
            speedKmH *
            60;

    final int rounded =
        math.max(1, minutes.ceil());

    return '$rounded min';
  }

  // =============================================================
  // PAYMENT
  // =============================================================

  String get _paymentText =>
      'After acceptance';

  // =============================================================
  // REACH CONDITION
  // =============================================================

  bool get _canReachOwner {
    return _accepted &&
        !_requestUnavailable &&
        _ownerLatitude != null &&
        _ownerLongitude != null &&
        _distanceMeters <= 100;
  }

  // =============================================================
  // ERROR
  // =============================================================

  String _cleanException(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        );
  }

  // =============================================================
  // MESSAGE
  // =============================================================

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
          behavior:
              SnackBarBehavior.floating,
          margin:
              const EdgeInsets.all(14),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      );
  }

  // =============================================================
  // DISPOSE
  // =============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _requestSubscription?.cancel();

    super.dispose();
  }

  // =============================================================
  // BUILD
  // =============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Stack(
        children: [
          // =======================================================
          // PREMIUM MAP
          // =======================================================

          Positioned.fill(
            child: ActiveWalkMap(
              mapController: _mapController,
              walkerLocation: _walkerLocation,
              pickupLocation: _pickupLocation,
            ),
          ),

          // =======================================================
          // TOP BAR
          // =======================================================

          ActiveWalkTopBar(
            status: _accepted
                ? 'active'
                : 'incoming',
            onBack: () {
              if (!_leavingScreen) {
                Navigator.pop(context);
              }
            },
          ),

          // =======================================================
          // INCOMING REQUEST SHEET
          // =======================================================

          IncomingWalkBottomSheet(
            request: widget.request,
            ownerName: _ownerName,
            dogName: _dogName,
            dogBreed: _dogBreed,
            address: _address,
            distanceText: _distanceText,
            etaText: _etaText,
            paymentText: _paymentText,
            accepted: _accepted,
            accepting: _accepting,
            rejecting: _rejecting,
            reaching: _reaching,
            canReachOwner: _canReachOwner,
            onAccept: _acceptWalk,
            onReject: _rejectWalk,
            onReachOwner: _reachOwner,
          ),

          // =======================================================
          // LOCATION LOADING
          // =======================================================

          if (_loadingLocation)
            const Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Colors.white70,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            ),

          // =======================================================
          // REQUEST UNAVAILABLE
          // =======================================================

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
}
