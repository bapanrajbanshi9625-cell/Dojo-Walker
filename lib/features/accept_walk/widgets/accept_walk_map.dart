import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class AcceptWalkMap extends StatefulWidget {
  const AcceptWalkMap({
    super.key,
    required this.ownerLocation,
    this.walkerLocation,
    this.routePoints = const [],
    this.bottomPanelHeight = 0,
    this.onMyLocationPressed,
  });

  final LatLng ownerLocation;
  final LatLng? walkerLocation;
  final List<LatLng> routePoints;
  final double bottomPanelHeight;
  final VoidCallback? onMyLocationPressed;

  @override
  State<AcceptWalkMap> createState() => _AcceptWalkMapState();
}

class _AcceptWalkMapState extends State<AcceptWalkMap> {
  final MapController _mapController = MapController();

  bool _mapReady = false;

  LatLng? _lastCameraLocation;

  static const double _followZoom = 16.5;
  static const double _minimumCameraMoveMeters = 5;

  // ============================================================
  // WIDGET UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant AcceptWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final LatLng? newWalkerLocation =
        widget.walkerLocation;

    final LatLng? oldWalkerLocation =
        oldWidget.walkerLocation;

    if (newWalkerLocation == null) {
      return;
    }

    if (oldWalkerLocation == null ||
        _hasMovedEnough(
          oldWalkerLocation,
          newWalkerLocation,
        )) {
      _followWalker(newWalkerLocation);
    }
  }

  // ============================================================
  // MAP READY
  // ============================================================

  void _handleMapReady() {
    _mapReady = true;

    final LatLng? walkerLocation =
        widget.walkerLocation;

    if (walkerLocation != null) {
      _followWalker(
        walkerLocation,
        force: true,
      );
    }
  }

  // ============================================================
  // FOLLOW WALKER
  // ============================================================

  void _followWalker(
    LatLng location, {
    bool force = false,
  }) {
    if (!_mapReady) {
      return;
    }

    if (!force &&
        _lastCameraLocation != null &&
        !_hasMovedEnough(
          _lastCameraLocation!,
          location,
        )) {
      return;
    }

    _lastCameraLocation = location;

    _mapController.move(
      location,
      _followZoom,
    );
  }

  // ============================================================
  // DISTANCE CHECK
  // ============================================================

  bool _hasMovedEnough(
    LatLng from,
    LatLng to,
  ) {
    final double distance =
        const Distance().as(
      LengthUnit.Meter,
      from,
      to,
    );

    return distance >= _minimumCameraMoveMeters;
  }

  // ============================================================
  // MY LOCATION
  // ============================================================

  void _goToMyLocation() {
    final LatLng? walkerLocation =
        widget.walkerLocation;

    if (!_mapReady || walkerLocation == null) {
      widget.onMyLocationPressed?.call();
      return;
    }

    _lastCameraLocation = walkerLocation;

    _mapController.move(
      walkerLocation,
      _followZoom,
    );

    widget.onMyLocationPressed?.call();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final LatLng center =
        widget.walkerLocation ??
        widget.ownerLocation;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.5,
        onMapReady: _handleMapReady,
        interactionOptions:
            const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.scrollWheelZoom,
        ),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojo.walker',
        ),

        // ========================================================
        // ROAD ROUTE
        // ========================================================

        if (widget.routePoints.length >= 2)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: widget.routePoints,
                strokeWidth: 8,
                color: Colors.white,
              ),
              Polyline(
                points: widget.routePoints,
                strokeWidth: 4.5,
                color: DojoWalkerColors.primary,
              ),
            ],
          ),

        // ========================================================
        // OWNER RADAR
        // ========================================================

        CircleLayer(
          circles: <CircleMarker>[
            CircleMarker(
              point: widget.ownerLocation,
              radius: 100,
              useRadiusInMeter: true,
              color: DojoWalkerColors.primary
                  .withValues(alpha: 0.08),
              borderColor: DojoWalkerColors.primary
                  .withValues(alpha: 0.35),
              borderStrokeWidth: 1.5,
            ),
          ],
        ),

        // ========================================================
        // MARKERS
        // ========================================================

        MarkerLayer(
          markers: <Marker>[
            Marker(
              point: widget.ownerLocation,
              width: 46,
              height: 46,
              child: const _OwnerMarker(),
            ),

            if (widget.walkerLocation != null)
              Marker(
                point: widget.walkerLocation!,
                width: 46,
                height: 46,
                child: const _WalkerMarker(),
              ),
          ],
        ),

        // ========================================================
        // MY LOCATION BUTTON
        // ========================================================

        if (widget.onMyLocationPressed != null)
          Positioned(
            right: 14,
            bottom:
                widget.bottomPanelHeight + 14,
            child: SafeArea(
              top: false,
              child: Material(
                elevation: 5,
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _goToMyLocation,
                  customBorder:
                      const CircleBorder(),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
                      Icons.my_location,
                      size: 22,
                      color:
                          DojoWalkerColors.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ================================================================
// OWNER MARKER
// ================================================================

class _OwnerMarker extends StatelessWidget {
  const _OwnerMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DojoWalkerColors.primary,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 7,
            color: Colors.black
                .withValues(alpha: 0.22),
          ),
        ],
      ),
      child: const Icon(
        Icons.home_rounded,
        color: Colors.white,
        size: 23,
      ),
    );
  }
}

// ================================================================
// WALKER MARKER
// ================================================================

class _WalkerMarker extends StatelessWidget {
  const _WalkerMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: DojoWalkerColors.primary,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 7,
            color: Colors.black
                .withValues(alpha: 0.22),
          ),
        ],
      ),
      child: const Icon(
        Icons.directions_walk_rounded,
        color: Colors.white,
        size: 23,
      ),
    );
  }
}
