import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class AcceptWalkMap extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final LatLng center =
        walkerLocation ?? ownerLocation;

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.5,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.doojo.walker',
        ),

        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: routePoints,
                strokeWidth: 8,
                color: Colors.white,
              ),
              Polyline(
                points: routePoints,
                strokeWidth: 4.5,
                color: DojoWalkerColors.primary,
              ),
            ],
          ),

        CircleLayer(
          circles: <CircleMarker>[
            CircleMarker(
              point: ownerLocation,
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
              point: ownerLocation,
              width: 46,
              height: 46,
              child: const _OwnerMarker(),
            ),
            if (walkerLocation != null)
              Marker(
                point: walkerLocation!,
                width: 46,
                height: 46,
                child: const _WalkerMarker(),
              ),
          ],
        ),

        if (onMyLocationPressed != null)
          Positioned(
            right: 14,
            bottom: bottomPanelHeight + 14,
            child: SafeArea(
              top: false,
              child: Material(
                elevation: 5,
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onMyLocationPressed,
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
