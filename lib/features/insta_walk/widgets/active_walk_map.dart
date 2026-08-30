import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkMap extends StatelessWidget {
  final MapController mapController;
  final LatLng? walkerLocation;
  final LatLng? pickupLocation;
  final LatLng? destinationLocation;

  const ActiveWalkMap({
    super.key,
    required this.mapController,
    this.walkerLocation,
    this.pickupLocation,
    this.destinationLocation,
  });

  @override
  Widget build(BuildContext context) {
    final List<Marker> markers = <Marker>[];

    // ============================================================
    // WALKER — LIVE LOCATION
    // ============================================================

    if (walkerLocation != null) {
      markers.add(
        Marker(
          point: walkerLocation!,
          width: 56,
          height: 56,
          child: _walkerMarker(),
        ),
      );
    }

    // ============================================================
    // OWNER — FIXED REQUEST LOCATION
    // ============================================================

    if (pickupLocation != null) {
      markers.add(
        Marker(
          point: pickupLocation!,
          width: 62,
          height: 62,
          child: _pickupMarker(),
        ),
      );
    }

    // ============================================================
    // DESTINATION
    // ============================================================

    if (destinationLocation != null) {
      markers.add(
        Marker(
          point: destinationLocation!,
          width: 45,
          height: 45,
          child: _destinationMarker(),
        ),
      );
    }

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: _getCenter(),
        initialZoom: _getInitialZoom(),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        // ========================================================
        // MAP
        // ========================================================

        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.doojowalker.app',
        ),

        // ========================================================
        // WALKER → FIXED OWNER POLYLINE
        // ========================================================

        if (walkerLocation != null &&
            pickupLocation != null)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points: <LatLng>[
                  walkerLocation!,
                  pickupLocation!,
                ],
                strokeWidth: 5,
                color: AppColors.primary,
              ),
            ],
          ),

        // ========================================================
        // MARKERS
        // ========================================================

        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers,
          ),
      ],
    );
  }

  // ============================================================
  // CENTER
  // ============================================================

  LatLng _getCenter() {
    if (walkerLocation != null &&
        pickupLocation != null) {
      return LatLng(
        (walkerLocation!.latitude +
                pickupLocation!.latitude) /
            2,
        (walkerLocation!.longitude +
                pickupLocation!.longitude) /
            2,
      );
    }

    if (walkerLocation != null) {
      return walkerLocation!;
    }

    if (pickupLocation != null) {
      return pickupLocation!;
    }

    if (destinationLocation != null) {
      return destinationLocation!;
    }

    return const LatLng(
      20.5937,
      78.9629,
    );
  }

  // ============================================================
  // INITIAL ZOOM
  // ============================================================

  double _getInitialZoom() {
    if (walkerLocation != null &&
        pickupLocation != null) {
      return 14;
    }

    return 16;
  }

  // ============================================================
  // WALKER MARKER
  // ============================================================

  Widget _walkerMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(
              alpha: .20,
            ),
            blurRadius: 10,
          ),
        ],
      ),
      child: const Icon(
        Icons.person_rounded,
        color: AppColors.secondary,
        size: 22,
      ),
    );
  }

  // ============================================================
  // OWNER / PICKUP MARKER
  // ============================================================

  Widget _pickupMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.cardBackground,
          width: 4,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(
              alpha: .25,
            ),
            blurRadius: 12,
          ),
        ],
      ),
      child: const Icon(
        Icons.pets_rounded,
        color: AppColors.buttonText,
        size: 24,
      ),
    );
  }

  // ============================================================
  // DESTINATION MARKER
  // ============================================================

  Widget _destinationMarker() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.flag_rounded,
        color: AppColors.buttonText,
        size: 18,
      ),
    );
  }
}
