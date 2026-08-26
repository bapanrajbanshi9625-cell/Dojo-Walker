import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';

class LiveWalkMap extends StatefulWidget {
  const LiveWalkMap({
    super.key,
    required this.sessionData,
  });

  final Map<String, dynamic> sessionData;

  @override
  State<LiveWalkMap> createState() =>
      _LiveWalkMapState();
}

class _LiveWalkMapState extends State<LiveWalkMap> {
  final MapController _mapController =
      MapController();

  StreamSubscription<Position>?
      _positionSubscription;

  LatLng? _currentLocation;

  bool _gpsReady = false;
  bool _loading = true;
  bool _followingUser = true;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  // ============================================================
  // START REAL GPS TRACKING
  // ============================================================

  Future<void> _startLocationTracking() async {
    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) {
          return;
        }

        setState(() {
          _gpsReady = false;
          _loading = false;
        });

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
        if (!mounted) {
          return;
        }

        setState(() {
          _gpsReady = false;
          _loading = false;
        });

        return;
      }

      // ----------------------------------------------------------
      // FIRST CURRENT POSITION
      // ----------------------------------------------------------

      final Position position =
         await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
       );
       
      _updatePosition(position);
      
      // ----------------------------------------------------------
      // CONTINUOUS CURRENT POSITION
      // ----------------------------------------------------------

      await _positionSubscription?.cancel();

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen(
        _updatePosition,
        onError: (_) {
          if (!mounted) {
            return;
          }

          setState(() {
            _gpsReady = false;
          });
        },
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _gpsReady = false;
        _loading = false;
      });
    }
  }

  // ============================================================
  // POSITION UPDATE
  // ============================================================

  void _updatePosition(
    Position position,
  ) {
    final LatLng location = LatLng(
      position.latitude,
      position.longitude,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentLocation = location;
      _gpsReady = true;
      _loading = false;
    });

    // ----------------------------------------------------------
    // FOLLOW CURRENT LOCATION
    // ----------------------------------------------------------

    if (_followingUser) {
      try {
        _mapController.move(
          location,
          17,
        );
      } catch (_) {
        // Map controller may not be ready yet.
      }
    }
  }

  // ============================================================
  // MAP CREATED
  // ============================================================

  void _onMapReady() {
    final LatLng? location =
        _currentLocation;

    if (location == null) {
      return;
    }

    try {
      _mapController.move(
        location,
        17,
      );
    } catch (_) {}
  }

  // ============================================================
  // MAP INTERACTION
  // ============================================================

  void _onMapPositionChanged(
    MapCamera camera,
    bool hasGesture,
  ) {
    if (hasGesture) {
      _followingUser = false;
    }
  }

  // ============================================================
  // FOLLOW BUTTON
  // ============================================================

  void _followCurrentLocation() {
    final LatLng? location =
        _currentLocation;

    if (location == null) {
      return;
    }

    _followingUser = true;

    try {
      _mapController.move(
        location,
        17,
      );
    } catch (_) {}
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final LatLng? location =
        _currentLocation;

    return Stack(
      children: [
        // ========================================================
        // REAL OPENSTREETMAP
        // ========================================================

        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                location ??
                    const LatLng(
                      0,
                      0,
                    ),
            initialZoom: 17,
            minZoom: 3,
            maxZoom: 19,
            onMapReady: _onMapReady,
            onPositionChanged:
                _onMapPositionChanged,
            interactionOptions:
                const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
          ),
          children: [
            // ====================================================
            // OPENSTREETMAP TILES
            // ====================================================

            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.doojowalker.app',
              maxZoom: 19,
            ),

            // ====================================================
            // CURRENT GPS MARKER
            // ====================================================

            if (location != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: location,
                    width: 64,
                    height: 64,
                    child:
                        const _CurrentLocationMarker(),
                  ),
                ],
              ),

            // ====================================================
            // OSM ATTRIBUTION
            // ====================================================

            const SimpleAttributionWidget(
              source: Text(
                'OpenStreetMap contributors',
              ),
            ),
          ],
        ),

        // ========================================================
        // GPS STATUS
        // ========================================================

        Positioned(
          top: 14,
          right: 14,
          child: _gpsStatus(),
        ),

        // ========================================================
        // FOLLOW CURRENT LOCATION
        // ========================================================

        if (_gpsReady &&
            !_followingUser)
          Positioned(
            right: 14,
            bottom: 24,
            child:
                _followLocationButton(),
          ),

        // ========================================================
        // GPS LOADING
        // ========================================================

        if (_loading)
          const Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // GPS STATUS
  // ============================================================

  Widget _gpsStatus() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: _gpsReady
                ? AppColors.success
                : AppColors.error,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            _gpsReady
                ? 'GPS LIVE'
                : 'GPS OFF',
            style: const TextStyle(
              color:
                  AppColors.secondary,
              fontSize: 9,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // FOLLOW LOCATION BUTTON
  // ============================================================

  Widget _followLocationButton() {
    return Material(
      color: AppColors.cardBackground,
      elevation: 5,
      borderRadius:
          BorderRadius.circular(16),
      child: InkWell(
        onTap:
            _followCurrentLocation,
        borderRadius:
            BorderRadius.circular(16),
        child: const Padding(
          padding:
              EdgeInsets.all(13),
          child: Icon(
            Icons.my_location_rounded,
            color: AppColors.primary,
            size: 23,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}

// ============================================================
// CURRENT GPS MARKER
// ============================================================

class _CurrentLocationMarker
    extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // ========================================================
        // GPS ACCURACY CIRCLE
        // ========================================================

        Container(
          width: 58,
          height: 58,
          decoration:
              BoxDecoration(
            color:
                AppColors.primary
                    .withValues(
              alpha: .16,
            ),
            shape:
                BoxShape.circle,
          ),
        ),

        // ========================================================
        // WHITE BORDER
        // ========================================================

        Container(
          width: 38,
          height: 38,
          decoration:
              const BoxDecoration(
            color: Colors.white,
            shape:
                BoxShape.circle,
          ),
        ),

        // ========================================================
        // CURRENT LOCATION
        // ========================================================

        Container(
          width: 30,
          height: 30,
          decoration:
              BoxDecoration(
            color:
                AppColors.primary,
            shape:
                BoxShape.circle,
            boxShadow:
                const [
              BoxShadow(
                color:
                    Color(0x33000000),
                blurRadius: 8,
                offset:
                    Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.navigation_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ],
    );
  }
}
