import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
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
  State<LiveWalkMap> createState() => LiveWalkMapState();
}

class LiveWalkMapState extends State<LiveWalkMap> {
  final MapController _mapController = MapController();

  final LiveWalkBackgroundService _backgroundService =
      LiveWalkBackgroundService.instance;

  final LiveWalkRoutingService _routingService =
      LiveWalkRoutingService.instance;

  StreamSubscription<dynamic>? _locationSubscription;

  LatLng? _currentLocation;
  LatLng? _pickupLocation;

  final List<LatLng> _gpsPoints = <LatLng>[];
  final List<LatLng> _roadRoute = <LatLng>[];

  bool _mapReady = false;
  bool _routing = false;
  bool _completed = false;
  bool _initialCameraSet = false;

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

    _loadBackgroundCurrentLocation();
  }

  // ============================================================
  // INITIAL DATA
  // ============================================================

  void _loadInitialData() {
    _pickupLocation = _readFirstLocation(
      <dynamic>[
        widget.sessionData['startLocation'],
        widget.sessionData['pickupLocation'],
        widget.sessionData['ownerPickupLocation'],
        widget.sessionData['ownerLocation'],
        widget.sessionData['ownerCurrentLocation'],
      ],
    );

    _currentLocation = _readFirstLocation(
      <dynamic>[
        widget.sessionData['currentLocation'],
        widget.sessionData['walkerLocation'],
        widget.sessionData['walkerCurrentLocation'],
        widget.sessionData['lastLocation'],
      ],
    );

    _loadRawGpsRoute(
      widget.sessionData['routeCoordinates'],
    );

    final String status =
        widget.sessionData['status']?.toString().trim().toLowerCase() ?? '';

    _completed =
        status == 'completed' ||
        status == 'complete' ||
        status == 'ended' ||
        status == 'finished' ||
        widget.sessionData['walkEnded'] == true;

    _loadBackgroundCurrentLocation();

    unawaited(
      _rebuildRoadRoute(),
    );
  }

  // ============================================================
  // BACKGROUND SERVICE CURRENT GPS
  // ============================================================

  void _loadBackgroundCurrentLocation() {
    final dynamic position = _backgroundService.lastPosition;

    if (position == null) {
      return;
    }

    final double? latitude = _toDouble(position.latitude);
    final double? longitude = _toDouble(position.longitude);

    if (latitude == null || longitude == null) {
      return;
    }

    if (!_validCoordinate(latitude, longitude)) {
      return;
    }

    final LatLng location = LatLng(
      latitude,
      longitude,
    );

    _currentLocation = location;
    _appendGpsPoint(location);

    if (_pickupLocation == null) {
      _pickupLocation = _readFirstLocation(
        <dynamic>[
          widget.sessionData['startLocation'],
          widget.sessionData['pickupLocation'],
          widget.sessionData['ownerPickupLocation'],
          widget.sessionData['ownerLocation'],
        ],
      );
    }

    // IMPORTANT:
    // Do not move the camera here on every GPS update.
    // Initial camera is handled only once.
    if (_mapReady && !_initialCameraSet) {
      _setInitialCameraIfPossible();
    }

    if (!_completed) {
      _scheduleRouting();
    }
  }

  // ============================================================
  // FIRESTORE UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant LiveWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final LatLng? pickup = _readFirstLocation(
      <dynamic>[
        widget.sessionData['startLocation'],
        widget.sessionData['pickupLocation'],
        widget.sessionData['ownerPickupLocation'],
        widget.sessionData['ownerLocation'],
        widget.sessionData['ownerCurrentLocation'],
      ],
    );

    if (pickup != null) {
      _pickupLocation = pickup;
    }

    final LatLng? current = _readFirstLocation(
      <dynamic>[
        widget.sessionData['currentLocation'],
        widget.sessionData['walkerLocation'],
        widget.sessionData['walkerCurrentLocation'],
        widget.sessionData['lastLocation'],
      ],
    );

    if (current != null) {
      _currentLocation = current;
      _appendGpsPoint(current);
    }

    _loadRawGpsRoute(
      widget.sessionData['routeCoordinates'],
    );

    final String status =
        widget.sessionData['status']?.toString().trim().toLowerCase() ?? '';

    final bool completed =
        status == 'completed' ||
        status == 'complete' ||
        status == 'ended' ||
        status == 'finished' ||
        widget.sessionData['walkEnded'] == true;

    if (completed) {
      _completed = true;
    }

    _loadBackgroundCurrentLocation();

    // Only set the initial camera if it has never been set.
    // Never recenter because Firestore/GPS data changed.
    if (_mapReady && !_initialCameraSet) {
      _setInitialCameraIfPossible();
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

    final List<LatLng> incoming = _parseRoute(rawRoute);

    if (incoming.isEmpty) {
      return;
    }

    for (final LatLng point in incoming) {
      _appendGpsPoint(point);
    }

    if (_currentLocation == null && _gpsPoints.isNotEmpty) {
      _currentLocation = _gpsPoints.last;
    }
  }

  // ============================================================
  // LIVE GPS LOCATION
  // ============================================================

  void _handleLiveLocation(
    dynamic position,
  ) {
    final double? latitude = _toDouble(position.latitude);
    final double? longitude = _toDouble(position.longitude);

    if (latitude == null || longitude == null) {
      return;
    }

    if (!_validCoordinate(latitude, longitude)) {
      return;
    }

    final LatLng location = LatLng(
      latitude,
      longitude,
    );

    _currentLocation = location;
    _appendGpsPoint(location);

    if (!mounted) {
      return;
    }

    setState(() {});

    // IMPORTANT:
    // GPS updates move only the marker.
    // The map camera must NOT follow automatically.
    if (_mapReady && !_initialCameraSet) {
      _setInitialCameraIfPossible();
    }

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

    final LatLng last = _gpsPoints.last;

    final double distance = const Distance().as(
      LengthUnit.Meter,
      last,
      point,
    );

    if (distance < 5) {
      return;
    }

    if (distance > 500) {
      return;
    }

    _gpsPoints.add(point);

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

    if (_currentLocation == null) {
      return;
    }

    if (_pickupLocation == null) {
      return;
    }

    if (_completed && _roadRoute.isNotEmpty) {
      return;
    }

    _routing = true;

    try {
      final List<LatLng> sourcePoints = <LatLng>[
        _pickupLocation!,
        ..._gpsPoints,
        _currentLocation!,
      ];

      final List<LatLng> cleanPoints =
          _removeNearbyDuplicatePoints(sourcePoints);

      if (cleanPoints.length < 2) {
        return;
      }

      final List<LatLng> routed = await _buildRoadRoute(
        cleanPoints,
      );

      if (!mounted || routed.isEmpty) {
        return;
      }

      setState(() {
        _roadRoute
          ..clear()
          ..addAll(routed);
      });

      // Route can trigger initial camera only once.
      if (_mapReady && !_initialCameraSet) {
        _setInitialCameraIfPossible();
      }
    } finally {
      _routing = false;
    }
  }

  // ============================================================
  // BUILD ROAD ROUTE
  // ============================================================

  Future<List<LatLng>> _buildRoadRoute(
    List<LatLng> points,
  ) async {
    if (points.length < 2) {
      return <LatLng>[];
    }

    final List<LatLng> sampled = <LatLng>[
      points.first,
    ];

    const int maxRoutingPoints = 12;

    final int step = points.length <= maxRoutingPoints
        ? 1
        : (points.length / maxRoutingPoints).ceil();

    for (
      int index = step;
      index < points.length;
      index += step
    ) {
      sampled.add(
        points[index],
      );
    }

    if (!_sameLocation(
      sampled.last,
      points.last,
    )) {
      sampled.add(
        points.last,
      );
    }

    if (sampled.length < 2) {
      return <LatLng>[];
    }

    final List<LatLng> result = <LatLng>[];

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

      // Never create a fake straight line.
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
  // REMOVE DUPLICATES
  // ============================================================

  List<LatLng> _removeNearbyDuplicatePoints(
    List<LatLng> points,
  ) {
    final List<LatLng> result = <LatLng>[];

    for (final LatLng point in points) {
      if (result.isEmpty) {
        result.add(point);
        continue;
      }

      if (!_sameLocation(
        result.last,
        point,
      )) {
        result.add(point);
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

    final double distance = const Distance().as(
      LengthUnit.Meter,
      target.last,
      point,
    );

    if (distance >= 2) {
      target.add(point);
    }
  }

  // ============================================================
  // INITIAL CAMERA
  // ============================================================

  void _setInitialCameraIfPossible() {
    if (!_mapReady || _initialCameraSet) {
      return;
    }

    final List<LatLng> points = <LatLng>[
      if (_pickupLocation != null) _pickupLocation!,
      if (_currentLocation != null) _currentLocation!,
    ];

    if (points.length < 2) {
      if (_currentLocation != null) {
        _moveMapToLocation(
          _currentLocation!,
        );
        _initialCameraSet = true;
      } else if (_pickupLocation != null) {
        _moveMapToLocation(
          _pickupLocation!,
        );
        _initialCameraSet = true;
      }

      return;
    }

    try {
      final LatLngBounds bounds =
          LatLngBounds.fromPoints(points);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(
            70,
            90,
            70,
            330,
          ),
          maxZoom: 17,
        ),
      );

      _initialCameraSet = true;
    } catch (_) {}
  }

  // ============================================================
  // MY LOCATION
  //
  // ONLY this method recenters the map after initial setup.
  // ============================================================

  void centerOnMyLocation() {
    final LatLng? location = _currentLocation;

    if (location == null || !_mapReady) {
      return;
    }

    try {
      final double currentZoom = _mapController.camera.zoom;

      _mapController.move(
        location,
        currentZoom < 16 ? 17 : currentZoom,
      );
    } catch (_) {}
  }

  // ============================================================
  // FIT WALK ROUTE
  // ============================================================

  void fitWalkRoute() {
    final List<LatLng> points = <LatLng>[
      if (_pickupLocation != null) _pickupLocation!,
      ..._roadRoute,
      if (_currentLocation != null) _currentLocation!,
    ];

    if (!_mapReady || points.length < 2) {
      centerOnMyLocation();
      return;
    }

    try {
      final LatLngBounds bounds =
          LatLngBounds.fromPoints(points);

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(
            55,
            100,
            55,
            330,
          ),
          maxZoom: 17,
        ),
      );

      _initialCameraSet = true;
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
        _mapController.camera.zoom < 16
            ? 17
            : _mapController.camera.zoom,
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

    final List<LatLng> route =
        List<LatLng>.unmodifiable(
      _roadRoute,
    );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 17,
        minZoom: 3,
        maxZoom: 20,
        onMapReady: () {
          _mapReady = true;

          _setInitialCameraIfPossible();

          if (!_initialCameraSet &&
              _pickupLocation != null &&
              _currentLocation != null) {
            fitWalkRoute();
          }
        },
      ),
      children: <Widget>[
        // ========================================================
        // OPEN STREET MAP
        // ========================================================

        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/'
              '{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        // ========================================================
        // REAL ROAD ROUTE
        // ========================================================

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

        // ========================================================
        // OWNER / PICKUP LOCATION
        // ========================================================

        if (_pickupLocation != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: _pickupLocation!,
                width: 54,
                height: 64,
                alignment: Alignment.topCenter,
                child: const _PickupMarker(),
              ),
            ],
          ),

        // ========================================================
        // REAL WALKER GPS LOCATION
        // ========================================================

        if (_currentLocation != null)
          MarkerLayer(
            markers: <Marker>[
              Marker(
                point: _currentLocation!,
                width: 58,
                height: 58,
                child: const _WalkerLocationMarker(),
              ),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // LOCATION READER
  // ============================================================

  LatLng? _readFirstLocation(
    List<dynamic> values,
  ) {
    for (final dynamic value in values) {
      final LatLng? location = _readLocation(value);

      if (location != null) {
        return location;
      }
    }

    return null;
  }

  // ============================================================
  // READ LOCATION
  // ============================================================

  LatLng? _readLocation(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is GeoPoint) {
      if (!_validCoordinate(
        value.latitude,
        value.longitude,
      )) {
        return null;
      }

      return LatLng(
        value.latitude,
        value.longitude,
      );
    }

    if (value is LatLng) {
      if (!_validCoordinate(
        value.latitude,
        value.longitude,
      )) {
        return null;
      }

      return value;
    }

    if (value is Map) {
      final double? latitude = _toDouble(
        value['lat'] ??
            value['latitude'] ??
            value['latValue'],
      );

      final double? longitude = _toDouble(
        value['lng'] ??
            value['longitude'] ??
            value['lon'] ??
            value['long'] ??
            value['lngValue'],
      );

      if (latitude != null &&
          longitude != null &&
          _validCoordinate(
            latitude,
            longitude,
          )) {
        return LatLng(
          latitude,
          longitude,
        );
      }

      final LatLng? nestedLocation = _readLocation(
        value['location'],
      );

      if (nestedLocation != null) {
        return nestedLocation;
      }

      final LatLng? nestedCoordinates = _readCoordinates(
        value['coordinates'],
      );

      if (nestedCoordinates != null) {
        return nestedCoordinates;
      }

      return null;
    }

    return _readCoordinates(value);
  }

  // ============================================================
  // COORDINATES ARRAY
  //
  // GeoJSON order:
  // [longitude, latitude]
  // ============================================================

  LatLng? _readCoordinates(
    dynamic value,
  ) {
    if (value is! List || value.length < 2) {
      return null;
    }

    final double? first = _toDouble(value[0]);
    final double? second = _toDouble(value[1]);

    if (first == null || second == null) {
      return null;
    }

    // GeoJSON:
    // [lng, lat]
    if (_validCoordinate(
      second,
      first,
    )) {
      return LatLng(
        second,
        first,
      );
    }

    // Also support:
    // [lat, lng]
    if (_validCoordinate(
      first,
      second,
    )) {
      return LatLng(
        first,
        second,
      );
    }

    return null;
  }

  // ============================================================
  // PARSE ROUTE
  // ============================================================

  List<LatLng> _parseRoute(
    dynamic rawRoute,
  ) {
    final List<LatLng> result = <LatLng>[];

    if (rawRoute is! List) {
      return result;
    }

    for (final dynamic item in rawRoute) {
      final LatLng? location = _readLocation(item);

      if (location != null) {
        result.add(location);
      }
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
        !(latitude == 0 && longitude == 0);
  }

  // ============================================================
  // SAME LOCATION
  // ============================================================

  bool _sameLocation(
    LatLng a,
    LatLng b,
  ) {
    return (a.latitude - b.latitude).abs() < 0.000001 &&
        (a.longitude - b.longitude).abs() < 0.000001;
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
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.red,
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
          child: const Center(
            child: Icon(
              Icons.home_rounded,
              color: Colors.red,
              size: 22,
            ),
          ),
        ),
        const Icon(
          Icons.arrow_drop_down_rounded,
          color: Colors.red,
          size: 20,
        ),
      ],
    );
  }
}

// ============================================================================
// WALKER GPS MARKER
// ============================================================================

class _WalkerLocationMarker extends StatelessWidget {
  const _WalkerLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.blue.withValues(
              alpha: 0.18,
            ),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 30,
          height: 30,
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
            size: 17,
          ),
        ),
      ],
    );
  }
}
