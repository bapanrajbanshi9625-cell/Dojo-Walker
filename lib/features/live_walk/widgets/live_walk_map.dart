import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

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

  StreamSubscription<dynamic>? _locationSubscription;

  LatLng? _currentLocation;

  List<LatLng> _routePoints = <LatLng>[];

  bool _mapReady = false;

  @override
  void initState() {
    super.initState();

    _loadInitialData();

    _locationSubscription =
        _backgroundService.locationStream.listen(
      (dynamic position) {
        final double? lat =
            _toDouble(position.latitude);

        final double? lng =
            _toDouble(position.longitude);

        if (lat == null || lng == null) {
          return;
        }

        final LatLng location =
            LatLng(lat, lng);

        if (!mounted) {
          return;
        }

        setState(() {
          _currentLocation = location;
          _addRoutePoint(location);
        });

        _moveMapToLocation(location);
      },
    );
  }

  // ============================================================
  // INITIAL DATA
  // ============================================================

  void _loadInitialData() {
    final dynamic currentLocation =
        widget.sessionData['currentLocation'];

    if (currentLocation is Map) {
      final double? lat =
          _toDouble(
        currentLocation['lat'] ??
            currentLocation['latitude'],
      );

      final double? lng =
          _toDouble(
        currentLocation['lng'] ??
            currentLocation['longitude'] ??
            currentLocation['lon'],
      );

      if (lat != null && lng != null) {
        _currentLocation =
            LatLng(lat, lng);
      }
    }

    final dynamic rawRoute =
        widget.sessionData['routeCoordinates'];

    if (rawRoute is List) {
      for (final dynamic item
          in rawRoute) {
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

        _routePoints.add(
          LatLng(lat, lng),
        );
      }
    }

    // If Firestore has no route yet,
    // use current location as first point.
    if (_routePoints.isEmpty &&
        _currentLocation != null) {
      _routePoints.add(
        _currentLocation!,
      );
    }
  }

  // ============================================================
  // DID UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant LiveWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final dynamic rawRoute =
        widget.sessionData['routeCoordinates'];

    if (rawRoute is! List) {
      return;
    }

    final List<LatLng> firestoreRoute =
        <LatLng>[];

    for (final dynamic item
        in rawRoute) {
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

      firestoreRoute.add(
        LatLng(lat, lng),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _routePoints =
          firestoreRoute;
    });
  }

  // ============================================================
  // ADD ROUTE POINT
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

    // Ignore GPS noise below 5 metres.
    if (distance < 5) {
      return;
    }

    _routePoints.add(point);

    if (_routePoints.length > 3000) {
      _routePoints.removeRange(
        0,
        _routePoints.length - 3000,
      );
    }
  }

  // ============================================================
  // MOVE MAP
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
      // Map may not be ready yet.
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

          if (_currentLocation != null) {
            _moveMapToLocation(
              _currentLocation!,
            );
          }
        },
      ),
      children: <Widget>[
        // ========================================================
        // MAP
        // ========================================================

        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        // ========================================================
        // WALK ROUTE POLYLINE
        //
        // Start -> movement -> movement -> movement -> Complete
        // ========================================================

        if (_routePoints.length >= 2)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: _routePoints,
                strokeWidth: 5,
                color: Colors.orange,
                borderStrokeWidth: 2,
                borderColor: Colors.white,
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
                child: const _WalkerLocationMarker(),
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
// WALKER LOCATION MARKER
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
