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
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final MapController _mapController = MapController();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final InstaWalkAcceptService _acceptService =
      InstaWalkAcceptService.instance;

  final InstaWalkRejectService _rejectService =
      InstaWalkRejectService.instance;

  // ============================================================
  // SUBSCRIPTIONS
  // ============================================================

  StreamSubscription<Position>? _locationSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  // ============================================================
  // STATE
  // ============================================================

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
  // REQUEST DATA
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

  String get _dogName {
  final String value =
      widget.request.dogName.trim();

  return value.isEmpty ? 'Your Pet' : value;
  }
  
  String get _dogBreed {
    return widget.request.dogBreed.trim();
  }

  String get _address {
    final String pickup =
        widget.request.pickupAddress.trim();

    if (pickup.isNotEmpty) {
      return pickup;
    }

    return widget.request.address.trim();
  }

  String get _sessionId {
    return widget.request.liveWalkSessionId.trim();
  }

  String get _walkId {
    return widget.request.id.trim();
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

    unawaited(
      _startLocationTracking(),
    );

    _startRequestMonitoring();
  }

  // ============================================================
  // FIRESTORE MONITOR
  // ============================================================

  void _startRequestMonitoring() {
    if (_walkId.isEmpty) {
      return;
    }

    final DocumentReference<Map<String, dynamic>> walkRef =
        _firestore
            .collection('walk_request')
            .doc(_walkId);

    _requestSubscription =
        walkRef.snapshots().listen(
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

  // ============================================================
  // CURRENT WALKER
  // ============================================================

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
  // LOCATION
  // ============================================================

  Future<void> _startLocationTracking() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (mounted) {
          _showMessage(
            'Please turn on Location/GPS.',
          );
        }
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showMessage(
            'Location permission is required.',
          );
        }
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) {
        return;
      }

      _updateWalkerLocation(position);

      _locationSubscription =
          Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
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

      if (mounted) {
        _showMessage(
          'Unable to get your location.',
        );
      }
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

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (mounted) {
          _fitMap();
        }
      },
    );
  }

  // ============================================================
  // MAP
  // ============================================================

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
      final LatLng walkerPoint = LatLng(
        walker.latitude,
        walker.longitude,
      );

      final LatLng ownerPoint = LatLng(
        latitude,
        longitude,
      );

      final LatLngBounds bounds =
          LatLngBounds.fromPoints(
        <LatLng>[
          walkerPoint,
          ownerPoint,
        ],
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(
            45,
            130,
            45,
            400,
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

  LatLng get _mapCenter {
    final Position? walker =
        _walkerPosition;

    if (walker != null) {
      return LatLng(
        walker.latitude,
        walker.longitude,
      );
    }

    final double? latitude =
        _ownerLatitude;

    final double? longitude =
        _ownerLongitude;

    if (latitude != null &&
        longitude != null) {
      return LatLng(
        latitude,
        longitude,
      );
    }

    return const LatLng(
      20.5937,
      78.9629,
    );
  }

  Widget _buildMap() {
    final List<Marker> markers =
        <Marker>[];

    final LatLng? walker =
        _walkerLocation;

    final LatLng? owner =
        _pickupLocation;

    if (walker != null) {
      markers.add(
        Marker(
          point: walker,
          width: 58,
          height: 58,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      );
    }

    if (owner != null) {
      markers.add(
        Marker(
          point: owner,
          width: 62,
          height: 70,
          child: Column(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration: const BoxDecoration(
                  color: Color(0xFFF4511E),
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.person_pin_circle_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: ColoredBox(
            color: const Color(0xFFE9EEF3),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _mapCenter,
                initialZoom: 14,
                interactionOptions:
                    const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: <Widget>[
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.doojowalker.app',
                ),
                if (markers.isNotEmpty)
                  MarkerLayer(
                    markers: markers,
                  ),
                if (walker != null &&
                    owner != null)
                  PolylineLayer(
                    polylines: <Polyline>[
                      Polyline(
                        points: <LatLng>[
                          walker,
                          owner,
                        ],
                        strokeWidth: 4,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 105,
          left: 14,
          child: _mapStatusBadge(),
        ),
      ],
    );
  }

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

  Widget _mapStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'LIVE LOCATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

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
  // REACH
  // ============================================================

  bool get _canReachOwner {
    return _accepted &&
        !_requestUnavailable &&
        _ownerLatitude != null &&
        _ownerLongitude != null &&
        _distanceMeters <= 100;
  }

  // ============================================================
  // ACCEPT
  // ============================================================

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
  // REJECT
  // ============================================================

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
        _requestUnavailable) {
      return;
    }

    if (_ownerLatitude == null ||
        _ownerLongitude == null) {
      _showMessage(
        'Owner location is unavailable.',
      );
      return;
    }

    if (_distanceMeters > 100) {
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
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          14,
          10,
          14,
          0,
        ),
        child: Row(
          children: <Widget>[
            _circleButton(
              icon: Icons.arrow_back_rounded,
              onTap: () {
                if (!_leavingScreen) {
                  Navigator.of(context).pop();
                }
              },
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(25),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    _accepted
                        ? Icons.check_circle_rounded
                        : Icons.notifications_active_rounded,
                    color: _accepted
                        ? Colors.green
                        : const Color(0xFFF4511E),
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _accepted
                        ? 'WALK ACCEPTED'
                        : 'INCOMING WALK',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Center(
            child: Icon(
              Icons.arrow_back_rounded,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM PANEL
  // ============================================================

  Widget _buildBottomPanel() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxHeight: 455,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 25,
                offset: Offset(0, -7),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),

                const SizedBox(height: 15),

                _buildDogHeader(),

                const SizedBox(height: 14),

                _buildStats(),

                if (_address.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildAddress(),
                ],

                const SizedBox(height: 14),

                if (_accepted)
                  _buildReachButton()
                else
                  _buildActionButtons(),

                const SizedBox(height: 7),

                Text(
                  _accepted
                      ? _canReachOwner
                          ? 'You are within 100 m of the owner.'
                          : 'Reach the owner to open Live Walk.'
                      : 'Review the location before accepting.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DOG HEADER
  // ============================================================

  Widget _buildDogHeader() {
    return Row(
      children: <Widget>[
        Container(
          width: 58,
          height: 58,
          decoration: const BoxDecoration(
            color: Color(0xFFFFE7DE),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.pets_rounded,
            color: Color(0xFFF4511E),
            size: 30,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _dogName,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF17202A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _dogBreed.isEmpty
                    ? _ownerName
                    : '$_dogBreed • $_ownerName',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATS
  // ============================================================

  Widget _buildStats() {
    return Row(
      children: <Widget>[
        Expanded(
          child: _statBox(
            Icons.location_on_rounded,
            _distanceText,
            'FROM YOU',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            Icons.schedule_rounded,
            _etaText,
            'ARRIVAL',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _statBox(
            Icons.payments_rounded,
            _paymentText,
            'PAYMENT',
          ),
        ),
      ],
    );
  }

  Widget _statBox(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Column(
        children: <Widget>[
          Icon(
            icon,
            color: const Color(0xFFF4511E),
            size: 19,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  Widget _buildAddress() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F8),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE7DE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFF4511E),
              size: 19,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _address,
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACCEPT / REJECT
  // ============================================================

  Widget _buildActionButtons() {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed:
                  _accepting || _rejecting
                      ? null
                      : _rejectWalk,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(
                  color: Colors.red,
                  width: 1.3,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              child: _rejecting
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'REJECT',
                      style: TextStyle(
                        fontWeight:
                            FontWeight.w900,
                        letterSpacing: .3,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed:
                  _accepting || _rejecting
                      ? null
                      : _acceptWalk,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    const Color(0xFFF4511E),
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    Colors.black12,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
              child: _accepting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child:
                          CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.check_rounded,
                          size: 22,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ACCEPT WALK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: .3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // REACH OWNER
  // ============================================================

  Widget _buildReachButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed:
            _canReachOwner && !_reaching
                ? _reachOwner
                : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              const Color(0xFFF4511E),
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              Colors.black12,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
        ),
        child: _reaching
            ? const SizedBox(
                width: 23,
                height: 23,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<
                          Color>(
                    Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    _canReachOwner
                        ? Icons
                            .location_on_rounded
                        : Icons
                            .directions_walk_rounded,
                    size: 23,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _canReachOwner
                        ? 'REACHED OWNER'
                        : 'REACH OWNER',
                    style:
                        const TextStyle(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
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
    _locationSubscription?.cancel();
    _requestSubscription?.cancel();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFE9EEF3),
      body: Stack(
        children: <Widget>[
          // ------------------------------------------------------
          // MAP
          // ------------------------------------------------------

          Positioned.fill(
            child: _buildMap(),
          ),

          // ------------------------------------------------------
          // TOP BAR
          // ------------------------------------------------------

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopBar(),
          ),

          // ------------------------------------------------------
          // BOTTOM PANEL
          // ------------------------------------------------------

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomPanel(),
          ),

          // ------------------------------------------------------
          // GPS LOADING
          // ------------------------------------------------------

          if (_loadingLocation)
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

          // ------------------------------------------------------
          // REQUEST UNAVAILABLE
          // ------------------------------------------------------

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
}
