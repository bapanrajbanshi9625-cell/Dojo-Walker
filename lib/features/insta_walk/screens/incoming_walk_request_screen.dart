// File:
// lib/features/insta_walk/screens/incoming_walk_request_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

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
  final MapController _mapController =
      MapController();

  final InstaWalkAcceptService _acceptService =
      InstaWalkAcceptService.instance;

  StreamSubscription<Position>?
      _locationSubscription;

  Position? _walkerPosition;

  bool _loading = true;
  bool _reaching = false;
  bool _canReach = false;

  double _distanceMeters = 0;

  // ------------------------------------------------------------
  // PICKUP LOCATION
  //
  // Supports common field names.
  // ------------------------------------------------------------

  double? get _pickupLat {
    final dynamic value =
        widget.request.data['pickupLat'] ??
            widget.request.data['ownerLat'] ??
            widget.request.data['latitude'] ??
            widget.request.data['lat'];

    return _toDouble(value);
  }

  double? get _pickupLng {
    final dynamic value =
        widget.request.data['pickupLng'] ??
            widget.request.data['ownerLng'] ??
            widget.request.data['longitude'] ??
            widget.request.data['lng'];

    return _toDouble(value);
  }

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    unawaited(
      _startLocationTracking(),
    );
  }

  // ------------------------------------------------------------
  // LOCATION
  // ------------------------------------------------------------

  Future<void> _startLocationTracking() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

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
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      _updateWalkerLocation(position);

      _locationSubscription =
          Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        _updateWalkerLocation,
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

  // ------------------------------------------------------------
  // UPDATE LOCATION
  // ------------------------------------------------------------

  void _updateWalkerLocation(
    Position position,
  ) {
    final double? pickupLat =
        _pickupLat;

    final double? pickupLng =
        _pickupLng;

    double distance = 0;

    if (pickupLat != null &&
        pickupLng != null) {
      distance =
          Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        pickupLat,
        pickupLng,
      );
    }

    // Reach radius:
    // 100 meters
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

    // Keep map centered on walker.
    try {
      _mapController.move(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        15.5,
      );
    } catch (_) {}
  }

  // ------------------------------------------------------------
  // ACCEPT
  //
  // Request was already accepted before this screen opened
  // in the current flow.
  //
  // This method is kept here as a safety fallback.
  // ------------------------------------------------------------

  Future<void> _acceptRequest() async {
    if (_reaching) {
      return;
    }

    setState(() {
      _reaching = true;
    });

    try {
      await _acceptService.acceptWalk(
        widget.request.id,
      );

      if (!mounted) {
        return;
      }

      _showMessage(
        'Walk request accepted.',
      );
    } catch (e) {
      debugPrint(
        'Accept incoming request error: $e',
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

  // ------------------------------------------------------------
  // REACH
  //
  // IMPORTANT:
  // Reach works ONLY when Walker is within 100m
  // of pickup location.
  // ------------------------------------------------------------

  Future<void> _onReach() async {
    if (!_canReach ||
        _reaching) {
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

    setState(() {
      _reaching = true;
    });

    try {
      // --------------------------------------------------------
      // ACCEPT / CONFIRM REQUEST
      // --------------------------------------------------------

      try {
        await _acceptService.acceptWalk(
          walkId,
        );
      } catch (e) {
        // If already accepted, don't block Reach.
        debugPrint(
          'Accept confirmation: $e',
        );
      }

      if (!mounted) {
        return;
      }

      // --------------------------------------------------------
      // NEXT SCREEN
      //
      // LiveWalkScreen will be the actual live-walk screen.
      // Start Walk slider belongs there.
      // --------------------------------------------------------

      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) {
            return LiveWalkScreen(
              ownerUid:
                  _ownerUid,
              ownerName:
                  _ownerName,
              walkId:
                  walkId,
              dogName:
                  _dogName,
              dogBreed:
                  _dogBreed,
              ownerPhone:
                  _ownerPhone,
              sessionId:
                  'session-$walkId',
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

  // ------------------------------------------------------------
  // REQUEST DATA
  // ------------------------------------------------------------

  Map<String, dynamic> get _data =>
      widget.request.data;

  String get _ownerUid {
    return (
          _data['ownerAuthUid'] ??
              _data['ownerUid'] ??
              _data['ownerId'] ??
              ''
        )
        .toString()
        .trim();
  }

  String get _ownerName {
    final String value =
        (_data['ownerName'] ?? '')
            .toString()
            .trim();

    return value.isEmpty
        ? 'Owner'
        : value;
  }

  String get _ownerPhone {
    final String value =
        (_data['ownerPhone'] ??
                _data['phone'] ??
                '')
            .toString()
            .trim();

    return value;
  }

  String get _dogName {
    final String value =
        (_data['dogName'] ??
                _data['petName'] ??
                '')
            .toString()
            .trim();

    return value.isEmpty
        ? 'Dog'
        : value;
  }

  String get _dogBreed {
    return (_data['dogBreed'] ??
            _data['breed'] ??
            '')
        .toString()
        .trim();
  }

  // ------------------------------------------------------------
  // MAP
  // ------------------------------------------------------------

  Widget _buildMap() {
    final double? pickupLat =
        _pickupLat;

    final double? pickupLng =
        _pickupLng;

    final List<Marker> markers =
        <Marker>[];

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
              boxShadow:
                  const <BoxShadow>[
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

    if (pickupLat != null &&
        pickupLng != null) {
      markers.add(
        Marker(
          point: LatLng(
            pickupLat,
            pickupLng,
          ),
          width: 58,
          height: 65,
          child: Column(
            children: <Widget>[
              Container(
                width: 45,
                height: 45,
                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFF4511E),
                  shape:
                      BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final LatLng center =
        pickupLat != null &&
                pickupLng != null
            ? LatLng(
                pickupLat,
                pickupLng,
              )
            : _walkerPosition != null
                ? LatLng(
                    _walkerPosition!
                        .latitude,
                    _walkerPosition!
                        .longitude,
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
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        // Route line can be added later
        // using OSRM/Google Directions.

        MarkerLayer(
          markers: markers,
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // TOP MAP OVERLAY
  // ------------------------------------------------------------

  Widget _buildMapOverlay() {
    return SafeArea(
      child: Padding(
        padding:
            const EdgeInsets.fromLTRB(
          14,
          12,
          14,
          0,
        ),
        child: Row(
          children: <Widget>[
            _roundButton(
              icon:
                  Icons.arrow_back_rounded,
              onTap: () {
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 9,
              ),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  22,
                ),
                boxShadow:
                    const <BoxShadow>[
                  BoxShadow(
                    color:
                        Colors.black18,
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.location_on,
                    color:
                        Color(0xFFF4511E),
                    size: 18,
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Text(
                    _distanceText,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w800,
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

  // ------------------------------------------------------------
  // BOTTOM REQUEST CARD
  // ------------------------------------------------------------

  Widget _buildBottomCard() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding:
              const EdgeInsets.fromLTRB(
            18,
            18,
            18,
            14,
          ),
          decoration:
              const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow:
                <BoxShadow>[
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
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFFFE7DE),
                      shape:
                          BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color:
                          Color(0xFFF4511E),
                      size: 29,
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: <Widget>[
                        Text(
                          _dogName,
                          style:
                              const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                        if (_dogBreed
                            .isNotEmpty)
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
                    color:
                        Colors.black45,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Text(
                    _ownerName,
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                height: 16,
              ),

              // PICKUP
              Container(
                width:
                    double.infinity,
                padding:
                    const EdgeInsets.all(
                  13,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFF7F7F7,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.location_on,
                      color:
                          Color(0xFFF4511E),
                    ),
                    const SizedBox(
                      width: 9,
                    ),
                    Expanded(
                      child: Text(
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
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 13,
              ),

              // REACH BUTTON
              SizedBox(
                width:
                    double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      _canReach &&
                              !_reaching
                          ? _onReach
                          : null,
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFF4511E,
                    ),
                    disabledBackgroundColor:
                        Colors.black12,
                    disabledForegroundColor:
                        Colors.black38,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        16,
                      ),
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
                            color:
                                Colors.white,
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing:
                                .4,
                          ),
                        ),
                ),
              ),

              const SizedBox(
                height: 7,
              ),

              Center(
                child: Text(
                  _canReach
                      ? 'You are within 100 m of pickup'
                      : 'Reach the pickup location to continue',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        Colors.black45,
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

  // ------------------------------------------------------------
  // ROUND BUTTON
  // ------------------------------------------------------------

  Widget _roundButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 4,
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.all(11),
          child: Icon(
            icon,
            size: 23,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DISTANCE
  // ------------------------------------------------------------

  String get _distanceText {
    if (_pickupLat == null ||
        _pickupLng == null) {
      return 'Pickup location unavailable';
    }

    if (_distanceMeters < 1000) {
      return '${_distanceMeters.round()} m away';
    }

    return '${(_distanceMeters / 1000).toStringAsFixed(1)} km away';
  }

  // ------------------------------------------------------------
  // DOUBLE PARSER
  // ------------------------------------------------------------

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
      value.toString(),
    );
  }

  // ------------------------------------------------------------
  // MESSAGE
  // ------------------------------------------------------------

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

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _locationSubscription?.cancel();

    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: _buildMap(),
          ),

          _buildMapOverlay(),

          _buildBottomCard(),

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
