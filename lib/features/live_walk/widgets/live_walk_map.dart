import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/live_walk_background_service.dart';
import '../services/live_walk_routing_service.dart';

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

  final LiveWalkBackgroundService
      _backgroundService =
      LiveWalkBackgroundService.instance;

  final LiveWalkRoutingService
      _routingService =
      LiveWalkRoutingService.instance;

  StreamSubscription<dynamic>?
      _locationSubscription;

  LatLng? _currentLocation;
  LatLng? _pickupLocation;

  final List<LatLng> _gpsPoints =
      <LatLng>[];

  final List<LatLng> _roadRoute =
      <LatLng>[];

  bool _mapReady = false;
  bool _routing = false;
  bool _completed = false;

  Timer? _routeTimer;

  @override
  void initState() {
    super.initState();

    _loadInitialData();

    _locationSubscription =
        _backgroundService.locationStream.listen(
      _handleLiveLocation,
      onError: (_) {},
      cancelOnError: false,
    );
  }

  // ============================================================
  // INITIAL DATA
  // ============================================================

  void _loadInitialData() {
    final LatLng? pickup =
        _readLocation(
      widget.sessionData['startLocation'],
    );

    final LatLng? current =
        _readLocation(
      widget.sessionData['currentLocation'],
    );

    _pickupLocation = pickup;
    _currentLocation = current;

    _loadRawGpsRoute(
      widget.sessionData['routeCoordinates'],
    );

    final String status =
        widget.sessionData['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    _completed =
        status == 'completed' ||
        status == 'complete' ||
        status == 'ended' ||
        status == 'finished' ||
        widget.sessionData['walkEnded'] == true;

    unawaited(
      _rebuildRoadRoute(),
    );
  }

  // ============================================================
  // FIRESTORE UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant LiveWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final LatLng? pickup =
        _readLocation(
      widget.sessionData['startLocation'],
    );

    if (pickup != null) {
      _pickupLocation = pickup;
    }

    final LatLng? current =
        _readLocation(
      widget.sessionData['currentLocation'],
    );

    if (current != null) {
      _currentLocation = current;
    }

    _loadRawGpsRoute(
      widget.sessionData['routeCoordinates'],
    );

    final String status =
        widget.sessionData['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    final bool completed =
        status == 'completed' ||
        status == 'complete' ||
        status == 'ended' ||
        status == 'finished' ||
        widget.sessionData['walkEnded'] == true;

    if (completed) {
      _completed = true;
    }

    unawaited(
      _rebuildRoadRoute(),
    );
  }

  // ============================================================
  // RAW GPS ROUTE
  // ============================================================

  void _loadRawGpsRoute(
    dynamic rawRoute,
  ) {
    if (rawRoute is! List) {
      return;
    }

    final List<LatLng> incoming =
        _parseRoute(rawRoute);

    if (incoming.isEmpty) {
      return;
    }

    for (final LatLng point in incoming) {
      _appendGpsPoint(point);
    }

    if (_pickupLocation == null &&
        _gpsPoints.isNotEmpty) {
      _pickupLocation =
          _gpsPoints.first;
    }

    if (_currentLocation == null &&
        _gpsPoints.isNotEmpty) {
      _currentLocation =
          _gpsPoints.last;
    }
  }

  // ============================================================
  // LIVE GPS LOCATION
  // ============================================================

  void _handleLiveLocation(
    dynamic position,
  ) {
    final double? latitude =
        _toDouble(position.latitude);

    final double? longitude =
        _toDouble(position.longitude);

    if (latitude == null ||
        longitude == null) {
      return;
    }

    if (!_validCoordinate(
      latitude,
      longitude,
    )) {
      return;
    }

    final LatLng location =
        LatLng(
      latitude,
      longitude,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _currentLocation = location;

      _appendGpsPoint(
        location,
      );

      if (_pickupLocation == null) {
        _pickupLocation =
            location;
      }
    });

    // Keep the live map following
    // the actual walker GPS location.
    _moveMapToLocation(
      location,
    );

    if (!_completed) {
      _scheduleRouting();
    }
  }

  // ============================================================
  // GPS POINT MANAGEMENT
  // ============================================================

  void _appendGpsPoint(
    LatLng point,
  ) {
    if (!_validCoordinate(
      point.latitude,
      point.longitude,
    )) {
      return;
    }

    if (_gpsPoints.isEmpty) {
      _gpsPoints.add(point);
      return;
    }

    final LatLng last =
        _gpsPoints.last;

    final double distance =
        const Distance().as(
      LengthUnit.Meter,
      last,
      point,
    );

    // Ignore GPS noise.
    if (distance < 5) {
      return;
    }

    // Ignore unrealistic GPS jumps.
    if (distance > 500) {
      return;
    }

    _gpsPoints.add(point);

    // Keep memory bounded.
    if (_gpsPoints.length > 3000) {
      _gpsPoints.removeRange(
        0,
        _gpsPoints.length - 3000,
      );
    }
  }

  // ============================================================
  // ROUTING SCHEDULER
  // ============================================================

  void _scheduleRouting() {
    _routeTimer?.cancel();

    _routeTimer = Timer(
      const Duration(seconds: 2),
      () {
        unawaited(
          _rebuildRoadRoute(),
        );
      },
    );
  }

  // ============================================================
  // ROAD ROUTE
  // ============================================================

  Future<void> _rebuildRoadRoute() async {
    if (_routing) {
      return;
    }

    if (_gpsPoints.length < 2) {
      return;
    }

    // Once completed, keep the final road route.
    if (_completed &&
        _roadRoute.isNotEmpty) {
      return;
    }

    _routing = true;

    try {
      final List<LatLng> sourcePoints =
          List<LatLng>.from(
        _gpsPoints,
      );

      if (sourcePoints.length < 2) {
        return;
      }

      final List<LatLng> routed =
          await _buildRoadRoute(
        sourcePoints,
      );

      if (!mounted ||
          routed.isEmpty) {
        return;
      }

      setState(() {
        _roadRoute
          ..clear()
          ..addAll(routed);
      });
    } finally {
      _routing = false;
    }
  }

  // ============================================================
  // BUILD ROAD ROUTE THROUGH SAMPLED GPS POINTS
  // ============================================================

  Future<List<LatLng>> _buildRoadRoute(
    List<LatLng> points,
  ) async {
    if (points.length < 2) {
      return <LatLng>[];
    }

    final List<LatLng> sampled =
        <LatLng>[];

    sampled.add(
      points.first,
    );

    const int maxRoutingPoints = 12;

    final int step =
        points.length <= maxRoutingPoints
            ? 1
            : (points.length /
                    maxRoutingPoints)
                .ceil();

    for (
      int index = step;
      index < points.length;
      index += step
    ) {
      sampled.add(
        points[index],
      );
    }

    if (sampled.last != points.last) {
      sampled.add(
        points.last,
      );
    }

    if (sampled.length < 2) {
      return <LatLng>[];
    }

    final List<LatLng> result =
        <LatLng>[];

    for (
      int index = 0;
      index < sampled.length - 1;
      index++
    ) {
      final List<LatLng> segment =
          await _routingService.getRoadRoute(
        start: sampled[index],
        end: sampled[index + 1],
      );

      // IMPORTANT:
      // Do not create a fake straight line when
      // road routing fails.
      if (segment.isEmpty) {
        continue;
      }

      for (final LatLng point in segment) {
        _appendUnique(
          result,
          point,
        );
      }
    }

    return result;
  }

  // ============================================================
  // UNIQUE ROUTE POINT
  // ============================================================

  void _appendUnique(
    List<LatLng> target,
    LatLng point,
  ) {
    if (target.isEmpty) {
      target.add(point);
      return;
    }

    final double distance =
        const Distance().as(
      LengthUnit.Meter,
      target.last,
      point,
    );

    if (distance >= 2) {
      target.add(point);
    }
  }

  // ============================================================
  // MY LOCATION
  // ============================================================

  void centerOnMyLocation() {
    final LatLng? location =
        _currentLocation;

    if (location == null ||
        !_mapReady) {
      return;
    }

    try {
      final double currentZoom =
          _mapController.camera.zoom;

      _mapController.move(
        location,
        currentZoom < 16
            ? 17
            : currentZoom,
      );
    } catch (_) {}
  }

  // ============================================================
  // FIT WALK ROUTE
  // ============================================================

  void fitWalkRoute() {
    final List<LatLng> points =
        <LatLng>[
      if (_pickupLocation != null)
        _pickupLocation!,
      ..._roadRoute,
      if (_currentLocation != null)
        _currentLocation!,
    ];

    if (!_mapReady ||
        points.length < 2) {
      centerOnMyLocation();
      return;
    }

    try {
      final LatLngBounds bounds =
          LatLngBounds.fromPoints(
        points,
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(
            55,
            120,
            55,
            260,
          ),
          maxZoom: 17,
        ),
      );
    } catch (_) {}
  }

  // ============================================================
  // MOVE MAP TO REAL GPS LOCATION
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
    } catch (_) {}
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
        _pickupLocation ??
        (
          _gpsPoints.isNotEmpty
              ? _gpsPoints.first
              : const LatLng(
                  20.5937,
                  78.9629,
                )
        );

    // ONLY actual road-routing geometry.
    //
    // We intentionally do NOT fall back to raw
    // GPS points because that can create a fake
    // straight line between two locations.
    final List<LatLng> route =
        List<LatLng>.unmodifiable(
      _roadRoute,
    );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // ======================================================
        // MAP
        // ======================================================

        FlutterMap(
          mapController:
              _mapController,
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
            // ==================================================
            // OPEN STREET MAP
            // ==================================================

            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/'
                  '{z}/{x}/{y}.png',
              userAgentPackageName:
                  'com.doojowalker.app',
            ),

            // ==================================================
            // REAL ROAD ROUTE
            // ==================================================

            if (route.length >= 2)
              PolylineLayer(
                polylines: <Polyline>[
                  Polyline(
                    points: route,
                    strokeWidth: 5,
                    color: Colors.blue,
                    borderStrokeWidth: 2,
                    borderColor: Colors.white,
                  ),
                ],
              ),

            // ==================================================
            // OWNER / PICKUP LOCATION
            // ==================================================

            if (_pickupLocation != null)
              MarkerLayer(
                markers: <Marker>[
                  Marker(
                    point:
                        _pickupLocation!,
                    width: 42,
                    height: 42,
                    child:
                        const _PickupMarker(),
                  ),
                ],
              ),

            // ==================================================
            // REAL WALKER GPS LOCATION
            // ==================================================

            if (_currentLocation != null)
              MarkerLayer(
                markers: <Marker>[
                  Marker(
                    point:
                        _currentLocation!,
                    width: 52,
                    height: 52,
                    child:
                        const _WalkerLocationMarker(),
                  ),
                ],
              ),
          ],
        ),

        // ======================================================
        // MY LOCATION BUTTON
        //
        // This is a real map control.
        // It moves the map to the current GPS position.
        // ======================================================

        Positioned(
          right: 14,
          bottom: 24,
          child: _MapLocationButton(
            onPressed:
                centerOnMyLocation,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // READ LOCATION
  // ============================================================

  LatLng? _readLocation(
    dynamic value,
  ) {
    if (value is! Map) {
      return null;
    }

    final double? latitude =
        _toDouble(
      value['lat'] ??
          value['latitude'],
    );

    final double? longitude =
        _toDouble(
      value['lng'] ??
          value['longitude'] ??
          value['lon'],
    );

    if (latitude == null ||
        longitude == null ||
        !_validCoordinate(
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
  // PARSE ROUTE
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

      final double? latitude =
          _toDouble(
        item['lat'] ??
            item['latitude'],
      );

      final double? longitude =
          _toDouble(
        item['lng'] ??
            item['longitude'] ??
            item['lon'],
      );

      if (latitude == null ||
          longitude == null ||
          !_validCoordinate(
            latitude,
            longitude,
          )) {
        continue;
      }

      result.add(
        LatLng(
          latitude,
          longitude,
        ),
      );
    }

    return result;
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
    double latitude,
    double longitude,
  ) {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180 &&
        !(latitude == 0 &&
            longitude == 0);
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _routeTimer?.cancel();

    unawaited(
      _locationSubscription?.cancel(),
    );

    super.dispose();
  }
}

// ============================================================================
// PICKUP / OWNER MARKER
// ============================================================================

class _PickupMarker extends StatelessWidget {
  const _PickupMarker();

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.green,
          width: 3,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 7,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.location_on_rounded,
          color: Colors.green,
          size: 21,
        ),
      ),
    );
  }
}

// ============================================================================
// WALKER GPS MARKER
// ============================================================================

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
        // Real-location accuracy area.
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(
              alpha: 0.18,
            ),
            shape: BoxShape.circle,
          ),
        ),

        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue,
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

// ============================================================================
// MY LOCATION BUTTON
// ============================================================================

class _MapLocationButton
    extends StatelessWidget {
  const _MapLocationButton({
    required this.onPressed,
  });

  final VoidCallback onPressed;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shadowColor:
          const Color(0x33000000),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap: onPressed,
        child: const SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            Icons.my_location_rounded,
            color: Colors.blue,
            size: 23,
          ),
        ),
      ),
    );
  }
}
