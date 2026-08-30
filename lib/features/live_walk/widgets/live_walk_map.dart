import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/live_walk_background_service.dart';

class LiveWalkMap extends StatefulWidget {
  const LiveWalkMap({
    super.key,
    required this.sessionData,
  });

  final Map<String, dynamic> sessionData;

  @override
  State<LiveWalkMap> createState() => _LiveWalkMapState();
}

class _LiveWalkMapState extends State<LiveWalkMap> {
  final MapController _mapController = MapController();

  final LiveWalkBackgroundService _backgroundService =
      LiveWalkBackgroundService.instance;

  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentLocation;

  bool _gpsReady = false;
  bool _loading = true;
  bool _followingUser = true;
  bool _mapReady = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();
    _startLocationTracking();
  }

  // ============================================================
  // START LOCATION TRACKING
  //
  // IMPORTANT:
  // This map uses the SAME background GPS source as the
  // LiveWalkController.
  //
  // No second Geolocator.getPositionStream() is created.
  // ============================================================

  Future<void> _startLocationTracking() async {
    try {
      // ----------------------------------------------------------
      // CHECK LOCATION SERVICE
      // ----------------------------------------------------------

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _setGpsState(
          ready: false,
          loading: false,
        );

        return;
      }

      // ----------------------------------------------------------
      // CHECK PERMISSION
      //
      // Controller/background service may already have permission.
      // We only request it if necessary.
      // ----------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setGpsState(
          ready: false,
          loading: false,
        );

        return;
      }

      // ----------------------------------------------------------
      // USE EXISTING BACKGROUND GPS POSITION
      // ----------------------------------------------------------

      final Position? lastPosition =
          _backgroundService.lastPosition;

      if (lastPosition != null) {
        _updatePosition(
          lastPosition,
        );
      }

      // ----------------------------------------------------------
      // ATTACH TO EXISTING GPS STREAM
      // ----------------------------------------------------------

      await _positionSubscription?.cancel();

      _positionSubscription =
          _backgroundService.locationStream.listen(
        _updatePosition,
        onError: (Object error) {
          debugPrint(
            'LiveWalkMap GPS stream error: $error',
          );
        },
        cancelOnError: false,
      );

      // ----------------------------------------------------------
      // IF WE HAVE NO POSITION YET, GET ONE ONCE.
      //
      // This is NOT a continuous second stream.
      // ----------------------------------------------------------

      if (_currentLocation == null) {
        try {
          final Position position =
              await Geolocator.getCurrentPosition(
            locationSettings:
                const LocationSettings(
              accuracy: LocationAccuracy.high,
            ),
          );

          _updatePosition(position);
        } catch (e) {
          debugPrint(
            'Initial GPS position error: $e',
          );
        }
      }

      if (mounted && _currentLocation == null) {
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint(
        'LiveWalkMap location error: $e',
      );

      _setGpsState(
        ready: false,
        loading: false,
      );
    }
  }

  // ============================================================
  // POSITION UPDATE
  // ============================================================

  void _updatePosition(
    Position position,
  ) {
    final double latitude = position.latitude;
    final double longitude = position.longitude;

    // ----------------------------------------------------------
    // INVALID GPS DATA
    // ----------------------------------------------------------

    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (latitude == 0 && longitude == 0)) {
      return;
    }

    final LatLng location = LatLng(
      latitude,
      longitude,
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

    if (_followingUser && _mapReady) {
      _moveToLocation(
        location,
      );
    }
  }

  // ============================================================
  // GPS STATE
  // ============================================================

  void _setGpsState({
    required bool ready,
    required bool loading,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _gpsReady = ready;
      _loading = loading;
    });
  }

  // ============================================================
  // MAP READY
  // ============================================================

  void _onMapReady() {
    _mapReady = true;

    final LatLng? location = _currentLocation;

    if (location == null) {
      // --------------------------------------------------------
      // Try session location if local GPS isn't ready yet.
      // --------------------------------------------------------

      final LatLng? sessionLocation =
          _readSessionLocation();

      if (sessionLocation != null) {
        _moveToLocation(
          sessionLocation,
        );
      }

      return;
    }

    _moveToLocation(
      location,
    );
  }

  // ============================================================
  // MOVE MAP
  // ============================================================

  void _moveToLocation(
    LatLng location,
  ) {
    if (!_mapReady) {
      return;
    }

    try {
      _mapController.move(
        location,
        17,
      );
    } catch (e) {
      debugPrint(
        'Map move error: $e',
      );
    }
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
  // FOLLOW CURRENT LOCATION
  // ============================================================

  void _followCurrentLocation() {
    final LatLng? location = _currentLocation;

    if (location == null) {
      return;
    }

    _followingUser = true;

    _moveToLocation(
      location,
    );

    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================
  // SESSION LOCATION
  // ============================================================

  LatLng? _readSessionLocation() {
    final dynamic currentLocation =
        widget.sessionData['currentLocation'];

    if (currentLocation is! Map) {
      return null;
    }

    final dynamic rawLat =
        currentLocation['lat'] ??
            currentLocation['latitude'];

    final dynamic rawLng =
        currentLocation['lng'] ??
            currentLocation['longitude'];

    if (rawLat is! num ||
        rawLng is! num) {
      return null;
    }

    final double latitude =
        rawLat.toDouble();

    final double longitude =
        rawLng.toDouble();

    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        (latitude == 0 &&
            longitude == 0)) {
      return null;
    }

    return LatLng(
      latitude,
      longitude,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final LatLng? location =
        _currentLocation ??
            _readSessionLocation();

    return Stack(
      children: [
        // ========================================================
        // OPENSTREETMAP
        // ========================================================

        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter:
                location ??
                    const LatLng(
                      20.5937,
                      78.9629,
                    ),
            initialZoom:
                location == null
                    ? 5
                    : 17,
            minZoom: 3,
            maxZoom: 19,
            onMapReady:
                _onMapReady,
            onPositionChanged:
                _onMapPositionChanged,
            interactionOptions:
                const InteractionOptions(
              flags:
                  InteractiveFlag.all,
            ),
          ),
          children: [
            // ====================================================
            // TILE LAYER
            // ====================================================

            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.doojowalker.app',
              maxZoom: 19,
            ),

            // ====================================================
            // CURRENT LOCATION MARKER
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
        // FOLLOW BUTTON
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
        // LOADING
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
        color:
            AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color:
                Color(0x26000000),
            blurRadius: 10,
            offset:
                Offset(0, 4),
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
      color:
          AppColors.cardBackground,
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
            color:
                AppColors.primary,
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
    _positionSubscription = null;

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
      alignment:
          Alignment.center,
      children: [
        // ========================================================
        // ACCURACY CIRCLE
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
        // GPS MARKER
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
