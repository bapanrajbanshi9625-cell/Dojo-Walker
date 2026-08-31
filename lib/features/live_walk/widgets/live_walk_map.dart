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

  // ============================================================
  // GPS
  // ============================================================

  StreamSubscription<Position>? _positionSubscription;

  LatLng? _currentLocation;

  bool _gpsReady = false;
  bool _loading = true;
  bool _followingUser = true;
  bool _mapReady = false;
  bool _centeringLocation = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _startLocationTracking();
  }

  // ============================================================
  // LOCATION TRACKING
  //
  // Uses the existing background GPS service.
  // No second continuous Geolocator stream is created.
  // ============================================================

  Future<void> _startLocationTracking() async {
    try {
      // --------------------------------------------------------
      // LOCATION SERVICE
      // --------------------------------------------------------

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _setGpsState(
          ready: false,
          loading: false,
        );
        return;
      }

      // --------------------------------------------------------
      // PERMISSION
      // --------------------------------------------------------

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setGpsState(
          ready: false,
          loading: false,
        );
        return;
      }

      // --------------------------------------------------------
      // LAST BACKGROUND POSITION
      // --------------------------------------------------------

      final Position? lastPosition =
          _backgroundService.lastPosition;

      if (lastPosition != null) {
        _updatePosition(lastPosition);
      }

      // --------------------------------------------------------
      // EXISTING BACKGROUND GPS STREAM
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // ONE-TIME INITIAL GPS REQUEST
      // --------------------------------------------------------

      if (_currentLocation == null) {
        try {
          final Position position =
              await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          _updatePosition(position);
        } catch (error) {
          debugPrint(
            'LiveWalkMap initial GPS error: $error',
          );
        }
      }

      // --------------------------------------------------------
      // FINISH LOADING
      // --------------------------------------------------------

      if (mounted && _currentLocation == null) {
        setState(() {
          _loading = false;
        });
      }
    } catch (error) {
      debugPrint(
        'LiveWalkMap location error: $error',
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

  void _updatePosition(Position position) {
    final double latitude = position.latitude;
    final double longitude = position.longitude;

    // ----------------------------------------------------------
    // VALIDATE POSITION
    // ----------------------------------------------------------

    if (!_isValidCoordinate(
      latitude,
      longitude,
    )) {
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
    // FOLLOW USER
    // ----------------------------------------------------------

    if (_followingUser && _mapReady) {
      _moveToLocation(location);
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

    final LatLng? currentLocation =
        _currentLocation;

    if (currentLocation != null) {
      _moveToLocation(currentLocation);
      return;
    }

    // ----------------------------------------------------------
    // FALLBACK TO SESSION LOCATION
    // ----------------------------------------------------------

    final LatLng? sessionLocation =
        _readSessionLocation();

    if (sessionLocation != null) {
      _moveToLocation(sessionLocation);
    }
  }

  // ============================================================
  // MOVE MAP
  // ============================================================

  void _moveToLocation(
    LatLng location, {
    double zoom = 17,
  }) {
    if (!_mapReady) {
      return;
    }

    try {
      _mapController.move(
        location,
        zoom,
      );
    } catch (error) {
      debugPrint(
        'LiveWalkMap move error: $error',
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
    if (!hasGesture) {
      return;
    }

    if (_followingUser && mounted) {
      setState(() {
        _followingUser = false;
      });
    }
  }

  // ============================================================
  // MY LOCATION
  //
  // Real working location button.
  // ============================================================

  Future<void> _goToMyLocation() async {
    if (_centeringLocation) {
      return;
    }

    // ----------------------------------------------------------
    // ALREADY HAVE CURRENT GPS
    // ----------------------------------------------------------

    final LatLng? currentLocation =
        _currentLocation;

    if (currentLocation != null) {
      _followingUser = true;

      if (mounted) {
        setState(() {
          _centeringLocation = true;
        });
      }

      _moveToLocation(
        currentLocation,
        zoom: 17,
      );

      await Future<void>.delayed(
        const Duration(
          milliseconds: 250,
        ),
      );

      if (mounted) {
        setState(() {
          _centeringLocation = false;
        });
      }

      return;
    }

    // ----------------------------------------------------------
    // GPS POSITION NOT AVAILABLE
    //
    // Ask for one fresh location.
    // ----------------------------------------------------------

    if (mounted) {
      setState(() {
        _centeringLocation = true;
      });
    }

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showLocationMessage(
          'Please turn on location services.',
        );
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        _showLocationMessage(
          'Location permission is required.',
        );
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        _showLocationMessage(
          'Location permission is disabled. '
          'Enable it from Settings.',
        );
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _updatePosition(position);

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      _followingUser = true;

      _moveToLocation(
        location,
        zoom: 17,
      );
    } catch (error) {
      debugPrint(
        'My Location error: $error',
      );

      _showLocationMessage(
        'Unable to get your current location.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _centeringLocation = false;
        });
      }
    }
  }

  // ============================================================
  // LOCATION MESSAGE
  // ============================================================

  void _showLocationMessage(
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
          duration: const Duration(
            seconds: 2,
          ),
        ),
      );
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

    if (!_isValidCoordinate(
      latitude,
      longitude,
    )) {
      return null;
    }

    return LatLng(
      latitude,
      longitude,
    );
  }

  // ============================================================
  // COORDINATE VALIDATION
  // ============================================================

  bool _isValidCoordinate(
    double latitude,
    double longitude,
  ) {
    return latitude.isFinite &&
        longitude.isFinite &&
        latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 && longitude == 0);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    // ----------------------------------------------------------
    // MAP CENTER PRIORITY
    //
    // 1. Current GPS
    // 2. Firestore session location
    // 3. India fallback
    // ----------------------------------------------------------

    final LatLng? location =
        _currentLocation ??
            _readSessionLocation();

    return Stack(
      children: [
        // ========================================================
        // MAP
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
            // OPEN STREET MAP
            // ====================================================

            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/'
                  '{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.doojowalker.app',
              maxZoom: 19,
            ),

            // ====================================================
            // CURRENT LOCATION
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
        // MY LOCATION BUTTON
        // ========================================================

        Positioned(
          right: 14,
          bottom: 24,
          child: _myLocationButton(),
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
                        AlwaysStoppedAnimation<Color>(
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
  // MY LOCATION BUTTON
  // ============================================================

  Widget _myLocationButton() {
    final bool active =
        _gpsReady || _currentLocation != null;

    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: _centeringLocation
            ? null
            : _goToMyLocation,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Center(
            child: _centeringLocation
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child:
                        CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  )
                : Icon(
                    Icons.my_location_rounded,
                    color: active
                        ? AppColors.primary
                        : Colors.grey,
                    size: 23,
                  ),
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
// CURRENT LOCATION MARKER
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
        // LOCATION ACCURACY / PULSE AREA
        // ========================================================

        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(
              alpha: .16,
            ),
            shape: BoxShape.circle,
          ),
        ),

        // ========================================================
        // WHITE BORDER
        // ========================================================

        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),

        // ========================================================
        // LOCATION MARKER
        // ========================================================

        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 3),
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
