import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LiveWalkMap extends StatelessWidget {
  const LiveWalkMap({
    super.key,
    required this.sessionData,
  });

  final Map<String, dynamic> sessionData;

  List<LatLng> _route() {
    final dynamic raw =
        sessionData['routeCoordinates'];

    if (raw is! List) {
      return [];
    }

    final List<LatLng> points = [];

    for (final item in raw) {
      if (item is Map) {
        final dynamic lat =
            item['lat'] ?? item['latitude'];

        final dynamic lng =
            item['lng'] ?? item['longitude'];

        final double? latitude =
            double.tryParse(
          lat?.toString() ?? '',
        );

        final double? longitude =
            double.tryParse(
          lng?.toString() ?? '',
        );

        if (latitude != null &&
            longitude != null &&
            latitude != 0 &&
            longitude != 0) {
          points.add(
            LatLng(
              latitude,
              longitude,
            ),
          );
        }
      }
    }

    return points;
  }

  LatLng? _currentLocation() {
    final dynamic location =
        sessionData['currentLocation'];

    if (location is Map) {
      final double? lat =
          double.tryParse(
        (
          location['lat'] ??
              location['latitude'] ??
              ''
        ).toString(),
      );

      final double? lng =
          double.tryParse(
        (
          location['lng'] ??
              location['longitude'] ??
              ''
        ).toString(),
      );

      if (lat != null &&
          lng != null &&
          lat != 0 &&
          lng != 0) {
        return LatLng(lat, lng);
      }
    }

    final double? lat =
        double.tryParse(
      (
        sessionData['currentLat'] ?? ''
      ).toString(),
    );

    final double? lng =
        double.tryParse(
      (
        sessionData['currentLng'] ?? ''
      ).toString(),
    );

    if (lat != null &&
        lng != null &&
        lat != 0 &&
        lng != 0) {
      return LatLng(lat, lng);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> route = _route();
    final LatLng? current =
        _currentLocation();

    final LatLng center =
        current ??
        (route.isNotEmpty
            ? route.last
            : const LatLng(
                22.5726,
                88.3639,
              ));

    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
        interactionOptions:
            const InteractionOptions(
          flags:
              InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        if (route.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: route,
                strokeWidth: 5,
                color:
                    const Color(0xFFFF6600),
              ),
            ],
          ),

        MarkerLayer(
          markers: [
            if (route.isNotEmpty)
              Marker(
                point: route.first,
                width: 38,
                height: 38,
                child: Container(
                  decoration:
                      const BoxDecoration(
                    color:
                        Color(0xFF16A34A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.flag_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),

            if (current != null)
              Marker(
                point: current,
                width: 58,
                height: 58,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFFF6600,
                    ).withOpacity(.18),
                    shape: BoxShape.circle,
                  ),
                  padding:
                      const EdgeInsets.all(10),
                  child: Container(
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFFF6600),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons
                          .directions_walk_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
