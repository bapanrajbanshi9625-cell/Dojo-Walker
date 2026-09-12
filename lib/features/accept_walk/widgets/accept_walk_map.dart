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

  void _goToMyLocation() {
    final LatLng? walkerLocation = widget.walkerLocation;

    if (!_mapReady || walkerLocation == null) {
      widget.onMyLocationPressed?.call();
      return;
    }

    _mapController.move(
      walkerLocation,
      16.5,
    );

    widget.onMyLocationPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center =
        widget.walkerLocation ?? widget.ownerLocation;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.5,
        onMapReady: () {
          _mapReady = true;
        },
        interactionOptions: const InteractionOptions(
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
          userAgentPackageName: 'com.doojo.walker',
        ),

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

        if (widget.onMyLocationPressed != null)
          Positioned(
            right: 14,
            bottom: widget.bottomPanelHeight + 14,
            child: SafeArea(
              top: false,
              child: Material(
                elevation: 5,
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _goToMyLocation,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 46,
                    height: 46,
                    child: Icon(
                      Icons.my_location,
                      size: 22,
                      color: DojoWalkerColors.primary,
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
            color: Colors.black.withValues(alpha: 0.22),
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
            color: Colors.black.withValues(alpha: 0.22),
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
