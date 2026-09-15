import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class IncomingWalkMap extends StatelessWidget {
  const IncomingWalkMap({
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
    final LatLng center = walkerLocation ?? ownerLocation;

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15.5,
        interactionOptions: const InteractionOptions(
          flags:
              InteractiveFlag.drag |
              InteractiveFlag.pinchZoom |
              InteractiveFlag.doubleTapZoom |
              InteractiveFlag.flingAnimation |
              InteractiveFlag.scrollWheelZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.doojo.walker',
        ),

        // ----------------------------------------------------------
        // WALKER -> PICKUP ROAD ROUTE
        // ----------------------------------------------------------
        if (routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                strokeWidth: 7,
                color: Colors.white,
              ),
              Polyline(
                points: routePoints,
                strokeWidth: 4,
                color: DojoWalkerColors.primary,
              ),
            ],
          ),

        // ----------------------------------------------------------
        // PICKUP LOCATION AREA
        // ----------------------------------------------------------
        CircleLayer(
          circles: [
            CircleMarker(
              point: ownerLocation,
              radius: 100,
              useRadiusInMeter: true,
              color: DojoWalkerColors.primary.withValues(
                alpha: 0.08,
              ),
              borderColor: DojoWalkerColors.primary.withValues(
                alpha: 0.35,
              ),
              borderStrokeWidth: 1.5,
            ),

            // Google Maps style current-location accuracy area
            if (walkerLocation != null)
              CircleMarker(
                point: walkerLocation!,
                radius: 35,
                useRadiusInMeter: true,
                color: const Color(0xFF4285F4).withValues(
                  alpha: 0.14,
                ),
                borderColor: const Color(0xFF4285F4).withValues(
                  alpha: 0.28,
                ),
                borderStrokeWidth: 1,
              ),
          ],
        ),

        // ----------------------------------------------------------
        // MARKERS
        // ----------------------------------------------------------
        MarkerLayer(
          markers: [
            // Pickup
            Marker(
              point: ownerLocation,
              width: 46,
              height: 46,
              child: const _OwnerMarker(),
            ),

            // Walker current location
            if (walkerLocation != null)
              Marker(
                point: walkerLocation!,
                width: 34,
                height: 34,
                child: const _WalkerMarker(),
              ),
          ],
        ),

        // ----------------------------------------------------------
        // MY LOCATION BUTTON
        // ----------------------------------------------------------
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

// ================================================================
// PICKUP MARKER
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
        boxShadow: [
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

// ================================================================
// GOOGLE MAPS STYLE WALKER CURRENT LOCATION
// ================================================================

class _WalkerMarker extends StatelessWidget {
  const _WalkerMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF4285F4),
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            spreadRadius: 1,
            color: Colors.black.withValues(alpha: 0.18),
          ),
        ],
      ),
      child: const SizedBox(
        width: 10,
        height: 10,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
