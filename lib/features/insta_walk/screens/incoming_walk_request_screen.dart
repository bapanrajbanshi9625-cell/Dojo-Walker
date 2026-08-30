// File:
// lib/features/insta_walk/screens/incoming_walk_request_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../models/insta_walk_request.dart';
import '../services/insta_walk_accept_service.dart';
import '../../live_walk/screens/live_walk_screen.dart';

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
  // ============================================================
  // MAP
  // ============================================================

  final MapController _mapController = MapController();

  // ============================================================
  // SERVICE
  // ============================================================

  final InstaWalkAcceptService _acceptService =
      InstaWalkAcceptService.instance;

  // ============================================================
  // LOCATION
  // ============================================================

  StreamSubscription<Position>? _locationSubscription;

  Position? _walkerPosition;

  bool _loading = true;
  bool _reaching = false;
  bool _canReach = false;

  double _distanceMeters = 0;

  // ============================================================
  // PICKUP LOCATION
  //
  // InstaWalkRequest already parses these fields.
  // Do NOT use request.data here.
  // ============================================================

  double? get _pickupLat {
    return widget.request.latitude;
  }

  double? get _pickupLng {
    return widget.request.longitude;
  }

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    unawaited(
      _startLocationTracking(),
    );
  }

  // ============================================================
  // LOCATION TRACKING
  //
  // Compatible with Geolocator versions where
  // locationSettings is not available.
  // ============================================================

  Future<void> _startLocationTracking() async {
    try {
      // --------------------------------------------------------
      // GPS SERVICE
      // --------------------------------------------------------

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Please turn on Location/GPS.',
        );

        return;
      }

      // --------------------------------------------------------
      // PERMISSION
      // --------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is required.',
        );

        return;
      }

      // --------------------------------------------------------
      // CURRENT LOCATION
      //
      // Old/current Geolocator-compatible API.
      // --------------------------------------------------------

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) {
        return;
      }

      _updateWalkerLocation(position);

      // --------------------------------------------------------
      // CONTINUOUS LOCATION
      // --------------------------------------------------------

      _locationSubscription =
          Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ).listen(
        _updateWalkerLocation,
        onError: (Object error) {
          debugPrint(
            'Location stream error: $error',
          );
        },
      );
    } catch (e) {
      debugPrint(
        'Incoming request location error: $e',
      );

      if (mounted) {
        _showMessage(
          'Unable to get your location.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // ============================================================
  // UPDATE WALKER LOCATION
  // ============================================================

  void _updateWalkerLocation(
    Position position,
  ) {
    final double? pickupLat = _pickupLat;
    final double? pickupLng = _pickupLng;

    double distance = 0;

    if (pickupLat != null && pickupLng != null) {
      distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        pickupLat,
        pickupLng,
      );
    }

    // ==========================================================
    // REACH RADIUS
    //
    // Walker is considered reached within 100 meters.
    // ==========================================================

    final bool reachable =
        pickupLat != null &&
            pickupLng != null &&
            distance <= 100;

    if (!mounted) {
      return;
    }

    setState(() {
      _walkerPosition = position;
      _distanceMeters = distance;
      _canReach = reachable;
    });

    // ==========================================================
    // CENTER MAP ON WALKER
    // ==========================================================

    try {
      _mapController.move(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        15.5,
      );
    } catch (_) {
      // MapController may not be ready yet.
    }
  }

  // ============================================================
  // REACH PICKUP
  // ============================================================

  Future<void> _onReach() async {
    if (!_canReach || _reaching) {
      return;
    }

    final String walkId =
        widget.request.id.trim();

    if (walkId.isEmpty) {
      _showMessage(
        'Walk ID is missing.',
      );

      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _reaching = true;
    });

    try {
      // --------------------------------------------------------
      // CONFIRM ACCEPTED STATUS
      //
      // Incoming screen normally opens after acceptance.
      // This is only a safety check.
      // --------------------------------------------------------

      try {
        await _acceptService.acceptWalk(
          walkId,
        );
      } catch (e) {
        debugPrint(
          'Accept confirmation: $e',
        );
      }

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // OPEN LIVE WALK
      //
      // Start Walk slider will be inside LiveWalkScreen.
      // --------------------------------------------------------

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) {
            return LiveWalkScreen(
              ownerUid: _ownerUid,
              ownerName: _ownerName,
              walkId: walkId,
              dogName: _dogName,
              dogBreed: _dogBreed,
              ownerPhone: _ownerPhone,
              sessionId: 'session-$walkId',
            );
          },
        ),
      );
    } catch (e) {
      debugPrint(
        'Reach error: $e',
      );

      if (mounted) {
        _showMessage(
          e.toString().replaceFirst(
            'Exception: ',
            '',
          ),
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
  // OWNER
  //
  // Directly from InstaWalkRequest.
  // ============================================================

  String get _ownerUid {
    final String value =
        widget.request.ownerAuthUid.trim().isNotEmpty
            ? widget.request.ownerAuthUid.trim()
            : widget.request.ownerUid.trim().isNotEmpty
                ? widget.request.ownerUid.trim()
                : widget.request.ownerId.trim();

    return value;
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
  // DOG
  // ============================================================

  String get _dogName {
    final String value =
        widget.request.dogName.trim();

    return value.isEmpty ? 'Dog' : value;
  }

  String get _dogBreed {
    return widget.request.dogBreed.trim();
  }

  // ============================================================
  // ADDRESS
  // ============================================================

  String get _pickupAddress {
    final String pickup =
        widget.request.pickupAddress.trim();

    if (pickup.isNotEmpty) {
      return pickup;
    }

    final String address =
        widget.request.address.trim();

    return address;
  }

  // ============================================================
  // OPENSTREETMAP MAP
  // ============================================================

  Widget _buildMap() {
    final double? pickupLat = _pickupLat;
    final double? pickupLng = _pickupLng;

    final List<Marker> markers =
        <Marker>[];

    // ==========================================================
    // WALKER MARKER
    // ==========================================================

    if (_walkerPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            _walkerPosition!.latitude,
            _walkerPosition!.longitude,
          ),
          width: 54,
          height: 54,
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
                  blurRadius: 10,
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

    // ==========================================================
    // OWNER / PICKUP MARKER
    // ==========================================================

    if (pickupLat != null && pickupLng != null) {
      markers.add(
        Marker(
          point: LatLng(
            pickupLat,
            pickupLng,
          ),
          width: 58,
          height: 65,
          child: Container(
            alignment: Alignment.topCenter,
            child: Container(
              width: 45,
              height: 45,
              decoration: const BoxDecoration(
                color: Color(0xFFF4511E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 27,
              ),
            ),
          ),
        ),
      );
    }

    // ==========================================================
    // MAP CENTER
    // ==========================================================

    final LatLng center =
        pickupLat != null && pickupLng != null
            ? LatLng(
                pickupLat,
                pickupLng,
              )
            : _walkerPosition != null
                ? LatLng(
                    _walkerPosition!.latitude,
                    _walkerPosition!.longitude,
                  )
                : const LatLng(
                    20.5937,
                    78.9629,
                  );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        interactionOptions:
            const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: <Widget>[
        // ======================================================
        // OPENSTREETMAP
        // ======================================================

        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        // ======================================================
        // MARKERS
        // ======================================================

        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }

  // ============================================================
  // MAP TOP OVERLAY
  // ============================================================

  Widget _buildMapOverlay() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          14,
          12,
          14,
          0,
        ),
        child: Row(
          children: <Widget>[
            _roundButton(
              icon: Icons.arrow_back_rounded,
              onTap: () {
                Navigator.pop(context);
              },
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
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
                children: <Widget>[
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFFF4511E),
                    size: 18,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _distanceText,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
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

  // ============================================================
  // BOTTOM REQUEST CARD
  // ============================================================

  Widget _buildBottomCard() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            14,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 18,
                offset: Offset(
                  0,
                  -5,
                ),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              // =================================================
              // DOG + OWNER
              // =================================================

              Row(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration:
                        const BoxDecoration(
                      color: Color(0xFFFFE7DE),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Color(0xFFF4511E),
                      size: 29,
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
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        if (_dogBreed.isNotEmpty)
                          Text(
                            _dogBreed,
                            style:
                                const TextStyle(
                              fontSize: 13,
                              color:
                                  Colors.black54,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.person_rounded,
                    size: 19,
                    color: Colors.black45,
                  ),

                  const SizedBox(width: 4),

                  Text(
                    _ownerName,
                    style: const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // =================================================
              // PICKUP
              // =================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFF7F7F7),
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on,
                      color: Color(0xFFF4511E),
                    ),

                    const SizedBox(width: 9),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _canReach
                                ? 'Pickup location reached'
                                : 'Go to owner pickup location',
                            style:
                                const TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  FontWeight.w700,
                            ),
                          ),

                          if (_pickupAddress
                              .isNotEmpty) ...<Widget>[
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              _pickupAddress,
                              maxLines: 2,
                              overflow:
                                  TextOverflow.ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 11,
                                color:
                                    Colors.black45,
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 13),

              // =================================================
              // REACH BUTTON
              // =================================================

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _canReach && !_reaching
                          ? _onReach
                          : null,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFFF4511E),
                    disabledBackgroundColor:
                        Colors.black12,
                    disabledForegroundColor:
                        Colors.black38,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(16),
                    ),
                  ),
                  child: _reaching
                      ? const SizedBox(
                          width: 24,
                          height: 24,
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
                      : Text(
                          _canReach
                              ? 'REACHED PICKUP'
                              : 'REACH PICKUP',
                          style:
                              const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: .4,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 7),

              // =================================================
              // DISTANCE MESSAGE
              // =================================================

              Center(
                child: Text(
                  _canReach
                      ? 'You are within 100 m of pickup'
                      : 'Reach the pickup location to continue',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // ROUND BUTTON
  // ============================================================

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(11),
          child: Icon(
            Icons.arrow_back_rounded,
            size: 23,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISTANCE TEXT
  // ============================================================

  String get _distanceText {
    if (_pickupLat == null ||
        _pickupLng == null) {
      return 'Pickup unavailable';
    }

    if (_distanceMeters < 1000) {
      return '${_distanceMeters.round()} m away';
    }

    return '${(_distanceMeters / 1000).toStringAsFixed(1)} km away';
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
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _locationSubscription?.cancel();
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
      body: Stack(
        children: <Widget>[
          // ====================================================
          // OPENSTREETMAP FULL SCREEN
          // ====================================================

          Positioned.fill(
            child: _buildMap(),
          ),

          // ====================================================
          // TOP CONTROLS
          // ====================================================

          _buildMapOverlay(),

          // ====================================================
          // BOTTOM REQUEST DETAILS
          // ====================================================

          _buildBottomCard(),

          // ====================================================
          // LOCATION LOADING
          // ====================================================

          if (_loading)
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
