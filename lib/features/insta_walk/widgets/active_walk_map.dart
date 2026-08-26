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
  Widget build(
    BuildContext context,
  ) {
    final List<LatLng> locations = [];

    if (walkerLocation != null) {
      locations.add(walkerLocation!);
    }

    if (pickupLocation != null) {
      locations.add(pickupLocation!);
    }

    if (destinationLocation != null) {
      locations.add(destinationLocation!);
    }

    final LatLng center =
        _getCenter();

    final List<Marker> markers = [];

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
        initialCenter: center,
        initialZoom:
            locations.length > 1 ? 14 : 16,
        interactionOptions:
            const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        if (walkerLocation != null &&
            pickupLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  walkerLocation!,
                  pickupLocation!,
                ],
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            ],
          ),

        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers,
          ),
      ],
    );
  }

  LatLng _getCenter() {
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
            color: AppColors.overlay.withOpacity(.20),
            blurRadius: 10,
          ),
        ],
      ),
      child: Icon(
        Icons.person_rounded,
        color: AppColors.secondary,
        size: 22,
      ),
    );
  }

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
            color: AppColors.overlay.withOpacity(.25),
            blurRadius: 12,
          ),
        ],
      ),
      child: Icon(
        Icons.pets_rounded,
        color: AppColors.buttonText,
        size: 24,
      ),
    );
  }

  Widget _destinationMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.flag_rounded,
        color: AppColors.buttonText,
        size: 18,
      ),
    );
  }
}
