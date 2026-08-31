import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/live_walk_background_service.dart';

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

  StreamSubscription<dynamic>? _locationSubscription;

  LatLng? _currentLocation;

  final List<LatLng> _routePoints = <LatLng>[];

  bool _mapReady = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadInitialData();

    _locationSubscription =
        _backgroundService.locationStream.listen(
      _handleLiveLocation,
      onError: (_) {
        // GPS stream errors must not crash the map.
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // INITIAL DATA
  // ============================================================

  void _loadInitialData() {
    final LatLng? firestoreLocation =
        _readLocation(widget.sessionData['currentLocation']);

    if (firestoreLocation != null) {
      _currentLocation = firestoreLocation;
    }

    _loadFirestoreRoute(
      widget.sessionData['routeCoordinates'],
      replace: true,
    );

    // ----------------------------------------------------------
    // If there is no saved route but a current location exists,
    // that location becomes the START point.
    // ----------------------------------------------------------

    if (_routePoints.isEmpty &&
        _currentLocation != null) {
      _routePoints.add(_currentLocation!);
    }
  }

  // ============================================================
  // WIDGET UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant LiveWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final dynamic rawRoute =
        widget.sessionData['routeCoordinates'];

    if (rawRoute is List) {
      // IMPORTANT:
      // Merge Firestore route with local live route.
      //
      // Never blindly replace the local route because GPS points
      // may already have been added locally.
      _mergeFirestoreRoute(rawRoute);
    }

    final LatLng? location =
        _readLocation(
      widget.sessionData['currentLocation'],
    );

    if (location != null) {
      _setCurrentLocation(location);
    }
  }

  // ============================================================
  // LIVE GPS LOCATION
  // ============================================================

  void _handleLiveLocation(
    dynamic position,
  ) {
    final double? lat =
        _toDouble(position.latitude);

    final double? lng =
        _toDouble(position.longitude);

    if (lat == null || lng == null) {
      return;
    }

    if (!_validCoordinate(lat, lng)) {
      return;
    }

    final LatLng location =
        LatLng(lat, lng);

    if (!mounted) {
      return;
    }

    setState(() {
      _setCurrentLocation(location);

      // --------------------------------------------------------
      // Every real GPS movement becomes a route point.
      // --------------------------------------------------------

      _addRoutePoint(location);
    });

    _moveMapToLocation(location);
  }

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  void _setCurrentLocation(
    LatLng location,
  ) {
    if (!_validCoordinate(
      location.latitude,
      location.longitude,
    )) {
      return;
    }

    _currentLocation = location;
  }

  // ============================================================
  // LOAD FIRESTORE ROUTE
  // ============================================================

  void _loadFirestoreRoute(
    dynamic rawRoute, {
    bool replace = false,
  }) {
    if (rawRoute is! List) {
      return;
    }

    final List<LatLng> firestoreRoute =
        _parseRoute(rawRoute);

    if (firestoreRoute.isEmpty) {
      return;
    }

    if (replace) {
      _routePoints
        ..clear()
        ..addAll(firestoreRoute);

      return;
    }

    _mergeRoutePoints(
      firestoreRoute,
    );
  }

  // ============================================================
  // MERGE FIRESTORE ROUTE
  // ============================================================

  void _mergeFirestoreRoute(
    List<dynamic> rawRoute,
  ) {
    final List<LatLng> firestoreRoute =
        _parseRoute(rawRoute);

    if (firestoreRoute.isEmpty) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _mergeRoutePoints(
        firestoreRoute,
      );
    });
  }

  // ============================================================
  // MERGE ROUTE POINTS
  //
  // Keeps the chronological route instead of destroying
  // locally collected GPS points.
  // ============================================================

  void _mergeRoutePoints(
    List<LatLng> incoming,
  ) {
    if (incoming.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // If local route is empty, simply restore it.
    // ----------------------------------------------------------

    if (_routePoints.isEmpty) {
      _routePoints.addAll(incoming);
      return;
    }

    // ----------------------------------------------------------
    // Add incoming points only when they extend the route.
    // ----------------------------------------------------------

    for (final LatLng point in incoming) {
      if (!_validCoordinate(
        point.latitude,
        point.longitude,
      )) {
        continue;
      }

      _appendRoutePoint(
        point,
      );
    }

    _trimRoute();
  }

  // ============================================================
  // ADD LIVE ROUTE POINT
  // ============================================================

  void _addRoutePoint(
    LatLng point,
  ) {
    if (!_validCoordinate(
      point.latitude,
      point.longitude,
    )) {
      return;
    }

    _appendRoutePoint(point);

    _trimRoute();
  }

  // ============================================================
  // APPEND ROUTE POINT
  // ============================================================

  void _appendRoutePoint(
    LatLng point,
  ) {
    if (_routePoints.isEmpty) {
      _routePoints.add(point);
      return;
    }

    final LatLng last =
        _routePoints.last;

    final double distance =
        const Distance().as(
      LengthUnit.Meter,
      last,
      point,
    );

    // ----------------------------------------------------------
    // Ignore GPS noise below 5 metres.
    // ----------------------------------------------------------

    if (distance < 5) {
      return;
    }

    // ----------------------------------------------------------
    // Ignore impossible GPS jumps.
    //
    // Background service already protects against large jumps,
    // but keeping this guard here protects the visual polyline.
    // ----------------------------------------------------------

    if (distance > 500) {
      return;
    }

    _routePoints.add(point);
  }

  // ============================================================
  // KEEP ROUTE SIZE SAFE
  // ============================================================

  void _trimRoute() {
    if (_routePoints.length <= 3000) {
      return;
    }

    _routePoints.removeRange(
      0,
      _routePoints.length - 3000,
    );
  }

  // ============================================================
  // PARSE FIRESTORE ROUTE
  // ============================================================

  List<LatLng> _parseRoute(
    dynamic rawRoute,
  ) {
    final List<LatLng> result =
        <LatLng>[];

    if (rawRoute is! List) {
      return result;
    }

    for (final dynamic item in rawRoute) {
      if (item is! Map) {
        continue;
      }

      final double? lat =
          _toDouble(
        item['lat'] ??
            item['latitude'],
      );

      final double? lng =
          _toDouble(
        item['lng'] ??
            item['longitude'] ??
            item['lon'],
      );

      if (lat == null || lng == null) {
        continue;
      }

      if (!_validCoordinate(lat, lng)) {
        continue;
      }

      result.add(
        LatLng(lat, lng),
      );
    }

    return result;
  }

  // ============================================================
  // READ CURRENT LOCATION
  // ============================================================

  LatLng? _readLocation(
    dynamic value,
  ) {
    if (value is! Map) {
      return null;
    }

    final double? lat =
        _toDouble(
      value['lat'] ??
          value['latitude'],
    );

    final double? lng =
        _toDouble(
      value['lng'] ??
          value['longitude'] ??
          value['lon'],
    );

    if (lat == null || lng == null) {
      return null;
    }

    if (!_validCoordinate(lat, lng)) {
      return null;
    }

    return LatLng(
      lat,
      lng,
    );
  }

  // ============================================================
  // MOVE CAMERA
  // ============================================================

  void _moveMapToLocation(
    LatLng location,
  ) {
    if (!_mapReady) {
      return;
    }

    try {
      _mapController.move(
        location,
        _mapController.camera.zoom,
      );
    } catch (_) {
      // Map controller may not be ready.
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final LatLng center =
        _currentLocation ??
            (_routePoints.isNotEmpty
                ? _routePoints.first
                : const LatLng(
                    20.5937,
                    78.9629,
                  ));

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 17,
        minZoom: 3,
        maxZoom: 20,
        onMapReady: () {
          _mapReady = true;

          final LatLng? location =
              _currentLocation;

          if (location != null) {
            _moveMapToLocation(
              location,
            );
          }
        },
      ),
      children: <Widget>[
        // ========================================================
        // OPEN STREET MAP
        // ========================================================

        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        // ========================================================
        // COMPLETE LIVE WALK POLYLINE
        //
        // START
        //   ↓
        // GPS POINT
        //   ↓
        // GPS POINT
        //   ↓
        // GPS POINT
        //   ↓
        // CURRENT LOCATION
        //   ↓
        // COMPLETE
        // ========================================================

        if (_routePoints.length >= 2)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points:
                    List<LatLng>.unmodifiable(
                  _routePoints,
                ),
                strokeWidth: 5,
                color: Colors.orange,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
              ),
            ],
          ),

        // ========================================================
        // START MARKER
        // ========================================================

        if (_routePoints.isNotEmpty)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: _routePoints.first,
                width: 34,
                height: 34,
                child: const _StartMarker(),
              ),
            ],
          ),

        // ========================================================
        // CURRENT WALKER LOCATION
        // ========================================================

        if (_currentLocation != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: _currentLocation!,
                width: 52,
                height: 52,
                child:
                    const _WalkerLocationMarker(),
              ),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // DOUBLE
  // ============================================================

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
      value.toString().trim(),
    );
  }

  // ============================================================
  // VALID COORDINATE
  // ============================================================

  bool _validCoordinate(
    double lat,
    double lng,
  ) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    unawaited(
      _locationSubscription?.cancel(),
    );

    super.dispose();
  }
}

// ==================================================================
// START MARKER
// ==================================================================

class _StartMarker extends StatelessWidget {
  const _StartMarker();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.orange,
          width: 3,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.orange,
          size: 18,
        ),
      ),
    );
  }
}

// ==================================================================
// CURRENT WALKER LOCATION MARKER
// ==================================================================

class _WalkerLocationMarker
    extends StatelessWidget {
  const _WalkerLocationMarker();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // --------------------------------------------------------
        // GPS ACCURACY / LOCATION PULSE
        // --------------------------------------------------------

        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color:
                Colors.orange.withValues(
              alpha: 0.18,
            ),
            shape: BoxShape.circle,
          ),
        ),

        // --------------------------------------------------------
        // WALKER
        // --------------------------------------------------------

        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x44000000),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_walk_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ],
    );
  }
}
