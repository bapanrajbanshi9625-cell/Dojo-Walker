import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class IncomingWalkMap extends StatefulWidget {
  const IncomingWalkMap({
    super.key,
    required this.walkerLocation,
    required this.ownerLocation,
  });

  final LatLng? walkerLocation;
  final LatLng? ownerLocation;

  @override
  State<IncomingWalkMap> createState() =>
      _IncomingWalkMapState();
}

class _IncomingWalkMapState
    extends State<IncomingWalkMap> {
  final MapController _mapController =
      MapController();

  LatLng get _mapCenter {
    final LatLng? walker =
        widget.walkerLocation;

    if (walker != null) {
      return walker;
    }

    final LatLng? owner =
        widget.ownerLocation;

    if (owner != null) {
      return owner;
    }

    return const LatLng(
      20.5937,
      78.9629,
    );
  }

  @override
  void didUpdateWidget(
    covariant IncomingWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.walkerLocation !=
            oldWidget.walkerLocation ||
        widget.ownerLocation !=
            oldWidget.ownerLocation) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          _fitMap();
        }
      });
    }
  }

  void _fitMap() {
    final LatLng? walker =
        widget.walkerLocation;

    final LatLng? owner =
        widget.ownerLocation;

    if (walker == null ||
        owner == null) {
      return;
    }

    try {
      final LatLngBounds bounds =
          LatLngBounds.fromPoints(
        <LatLng>[
          walker,
          owner,
        ],
      );

      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.fromLTRB(
            45,
            130,
            45,
            400,
          ),
          maxZoom: 16,
        ),
      );
    } catch (error) {
      debugPrint(
        'Incoming walk map fit error: $error',
      );
    }
  }

  List<Marker> _buildMarkers() {
    final List<Marker> markers =
        <Marker>[];

    final LatLng? walker =
        widget.walkerLocation;

    final LatLng? owner =
        widget.ownerLocation;

    // ------------------------------------------------------------
    // WALKER
    // ------------------------------------------------------------

    if (walker != null) {
      markers.add(
        Marker(
          point: walker,
          width: 58,
          height: 58,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 4,
              ),
              boxShadow:
                  const <BoxShadow>[
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                ),
              ],
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      );
    }

    // ------------------------------------------------------------
    // OWNER
    // ------------------------------------------------------------

    if (owner != null) {
      markers.add(
        Marker(
          point: owner,
          width: 62,
          height: 70,
          child: Column(
            children: <Widget>[
              Container(
                width: 50,
                height: 50,
                decoration:
                    const BoxDecoration(
                  color: Color(0xFFF4511E),
                  shape: BoxShape.circle,
                  boxShadow:
                      <BoxShadow>[
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons
                      .person_pin_circle_rounded,
                  color: Colors.white,
                  size: 29,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildStatusBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),
        boxShadow:
            const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 9,
            height: 9,
            decoration:
                const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            'LIVE LOCATION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final LatLng? walker =
        widget.walkerLocation;

    final LatLng? owner =
        widget.ownerLocation;

    final List<Marker> markers =
        _buildMarkers();

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: ColoredBox(
            color: const Color(
              0xFFE9EEF3,
            ),
            child: FlutterMap(
              mapController:
                  _mapController,
              options: MapOptions(
                initialCenter:
                    _mapCenter,
                initialZoom: 14,
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

                if (markers.isNotEmpty)
                  MarkerLayer(
                    markers: markers,
                  ),

                if (walker != null &&
                    owner != null)
                  PolylineLayer(
                    polylines: <Polyline>[
                      Polyline(
                        points: <LatLng>[
                          walker,
                          owner,
                        ],
                        strokeWidth: 4,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 105,
          left: 14,
          child: _buildStatusBadge(),
        ),
      ],
    );
  }
}
