import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class IncomingWalkMap extends StatefulWidget {
  const IncomingWalkMap({
    super.key,
    required this.walkerLocation,
    required this.ownerLocation,
    this.routePoints = const <LatLng>[],
  });

  final LatLng? walkerLocation;
  final LatLng? ownerLocation;

  /// Road-following route returned by the routing service.
  final List<LatLng> routePoints;

  @override
  State<IncomingWalkMap> createState() =>
      _IncomingWalkMapState();
}

class _IncomingWalkMapState
    extends State<IncomingWalkMap> {
  final MapController _mapController =
      MapController();

  bool _hasInitialFit = false;

  @override
  void didUpdateWidget(
    covariant IncomingWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final LatLng? oldWalker =
        oldWidget.walkerLocation;

    final LatLng? newWalker =
        widget.walkerLocation;

    final LatLng? oldOwner =
        oldWidget.ownerLocation;

    final LatLng? newOwner =
        widget.ownerLocation;

    if (!_hasInitialFit &&
        newWalker != null &&
        newOwner != null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          _fitBothLocations();
        },
      );
    }

    // Keep the map usable when the walker moves.
    // We intentionally do not recenter on every GPS update.
    if (oldWalker == null &&
        newWalker != null &&
        newOwner != null &&
        !_hasInitialFit) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          _fitBothLocations();
        },
      );
    }

    if (oldOwner == null &&
        newOwner != null &&
        newWalker != null &&
        !_hasInitialFit) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          if (!mounted) {
            return;
          }

          _fitBothLocations();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng? walker =
        widget.walkerLocation;

    final LatLng? owner =
        widget.ownerLocation;

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter:
            owner ??
            walker ??
            const LatLng(
              28.4595,
              77.0266,
            ),
        initialZoom: 15.5,
        interactionOptions:
            const InteractionOptions(
          flags:
              InteractiveFlag.all,
        ),
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        // ------------------------------------------------------
        // ROAD ROUTE
        // ------------------------------------------------------

        if (widget.routePoints.length >= 2)
          PolylineLayer(
            polylines: <Polyline>[
              Polyline(
                points:
                    widget.routePoints,
                strokeWidth: 7,
                color: const Color(
                  0xFF1976D2,
                ).withValues(
                  alpha: 0.20,
                ),
                borderStrokeWidth: 0,
              ),
              Polyline(
                points:
                    widget.routePoints,
                strokeWidth: 4,
                color: const Color(
                  0xFF1976D2,
                ),
                borderStrokeWidth: 1.5,
                borderColor:
                    Colors.white.withValues(
                  alpha: 0.90,
                ),
              ),
            ],
          ),

        // ------------------------------------------------------
        // PICKUP / OWNER 100m REACH AREA
        // ------------------------------------------------------

        if (owner != null)
          CircleLayer(
            circles: <CircleMarker>[
              CircleMarker(
                point: owner,
                radius: 100,
                useRadiusInMeter: true,
                color: const Color(
                  0xFFFF6B35,
                ).withValues(
                  alpha: 0.08,
                ),
                borderColor:
                    const Color(
                  0xFFFF6B35,
                ).withValues(
                  alpha: 0.45,
                ),
                borderStrokeWidth: 1.5,
              ),
            ],
          ),

        // ------------------------------------------------------
        // MARKERS
        // ------------------------------------------------------

        MarkerLayer(
          markers: <Marker>[
            if (owner != null)
              Marker(
                point: owner,
                width: 52,
                height: 64,
                child: const _PickupMarker(),
              ),

            if (walker != null)
              Marker(
                point: walker,
                width: 58,
                height: 58,
                child: const _WalkerMarker(),
              ),
          ],
        ),

        // ------------------------------------------------------
        // LIVE LOCATION BADGE
        // ------------------------------------------------------

        if (walker != null &&
            owner != null)
          Positioned(
            top: 78,
            right: 14,
            child: _LiveLocationBadge(),
          ),

        // ------------------------------------------------------
        // RECENTER BUTTON
        // ------------------------------------------------------

        Positioned(
          right: 14,
          bottom: 250,
          child: Material(
            color: Colors.white,
            elevation: 5,
            shadowColor:
                Colors.black.withValues(
              alpha: 0.16,
            ),
            shape:
                const CircleBorder(),
            child: InkWell(
              customBorder:
                  const CircleBorder(),
              onTap: _fitBothLocations,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(
                  Icons.my_location_rounded,
                  color: Color(
                    0xFF1976D2,
                  ),
                  size: 23,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _fitBothLocations() {
    final LatLng? walker =
        widget.walkerLocation;

    final LatLng? owner =
        widget.ownerLocation;

    if (walker == null ||
        owner == null) {
      return;
    }

    final double minLat =
        walker.latitude < owner.latitude
            ? walker.latitude
            : owner.latitude;

    final double maxLat =
        walker.latitude > owner.latitude
            ? walker.latitude
            : owner.latitude;

    final double minLng =
        walker.longitude < owner.longitude
            ? walker.longitude
            : owner.longitude;

    final double maxLng =
        walker.longitude > owner.longitude
            ? walker.longitude
            : owner.longitude;

    final LatLngBounds bounds =
        LatLngBounds(
      LatLng(
        minLat,
        minLng,
      ),
      LatLng(
        maxLat,
        maxLng,
      ),
    );

    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding:
              const EdgeInsets.fromLTRB(
            60,
            120,
            60,
            300,
          ),
          maxZoom: 16.5,
        ),
      );

      _hasInitialFit = true;
    } catch (error) {
      debugPrint(
        'IncomingWalkMap fit error: $error',
      );
    }
  }
}

class _WalkerMarker extends StatelessWidget {
  const _WalkerMarker();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(
              0xFF1976D2,
            ).withValues(
              alpha: 0.12,
            ),
          ),
        ),
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Container(
            margin:
                const EdgeInsets.all(3),
            decoration:
                const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(
                0xFF1976D2,
              ),
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
}

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
            color: const Color(
              0xFFFF6B35,
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color:
                    Colors.black.withValues(
                  alpha: 0.20,
                ),
                blurRadius: 8,
                offset:
                    const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.location_on_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        Container(
          width: 3,
          height: 8,
          color: const Color(
            0xFFFF6B35,
          ),
        ),
      ],
    );
  }
}

class _LiveLocationBadge
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.12,
            ),
            blurRadius: 10,
            offset:
                const Offset(0, 3),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize:
            MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.circle,
            size: 8,
            color: Color(
              0xFF16A34A,
            ),
          ),
          SizedBox(width: 6),
          Text(
            'LIVE LOCATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w900,
              letterSpacing: 0.5,
              color: Color(
                0xFF374151,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
