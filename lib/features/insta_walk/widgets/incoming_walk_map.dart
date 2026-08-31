// File:
// lib/features/insta_walk/widgets/incoming_walk_map.dart


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

  bool _mapReady = false;
  bool _hasInitialFit = false;

  // ============================================================
  // DEFAULT LOCATION
  // ============================================================

  static const LatLng _defaultCenter =
      LatLng(
    20.5937,
    78.9629,
  );

  // ============================================================
  // MAP CENTER
  // ============================================================

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

    return _defaultCenter;
  }

  // ============================================================
  // UPDATE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant IncomingWalkMap oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    final bool walkerChanged =
        widget.walkerLocation !=
            oldWidget.walkerLocation;

    final bool ownerChanged =
        widget.ownerLocation !=
            oldWidget.ownerLocation;

    if (!walkerChanged &&
        !ownerChanged) {
      return;
    }

    WidgetsBinding.instance
        .addPostFrameCallback((_) {
      if (!mounted || !_mapReady) {
        return;
      }

      // First time both locations become
      // available: fit both points.
      if (!_hasInitialFit &&
          widget.walkerLocation != null &&
          widget.ownerLocation != null) {
        _hasInitialFit = true;
        _fitBothLocations();
      }
    });
  }

  // ============================================================
  // FIT BOTH LOCATIONS
  // ============================================================

  void _fitBothLocations() {
    final LatLng? walker =
        widget.walkerLocation;

    final LatLng? owner =
        widget.ownerLocation;

    if (!_mapReady ||
        walker == null ||
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
            55,
            145,
            55,
            360,
          ),
          maxZoom: 16,
          minZoom: 12,
        ),
      );
    } catch (error) {
      debugPrint(
        'Incoming walk map fit error: $error',
      );
    }
  }

  // ============================================================
  // MARKERS
  // ============================================================

  List<Marker> _buildMarkers() {
    final List<Marker> markers =
        <Marker>[];

    final LatLng? walker =
        widget.walkerLocation;

    final LatLng? owner =
        widget.ownerLocation;

    // ----------------------------------------------------------
    // WALKER MARKER
    // ----------------------------------------------------------

    if (walker != null) {
      markers.add(
        Marker(
          point: walker,
          width: 68,
          height: 68,
          alignment: Alignment.center,
          child: _buildWalkerMarker(),
        ),
      );
    }

    // ----------------------------------------------------------
    // OWNER MARKER
    // ----------------------------------------------------------

    if (owner != null) {
      markers.add(
        Marker(
          point: owner,
          width: 76,
          height: 88,
          alignment: Alignment.bottomCenter,
          child: _buildOwnerMarker(),
        ),
      );
    }

    return markers;
  }

  // ============================================================
  // WALKER MARKER
  // ============================================================

  Widget _buildWalkerMarker() {
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        // Accuracy / location halo
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                Colors.blue.withValues(
              alpha: 0.14,
            ),
          ),
        ),

        // White border
        Container(
          width: 42,
          height: 42,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1976D2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.navigation_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OWNER MARKER
  // ============================================================

  Widget _buildOwnerMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFFF4511E),
            shape: BoxShape.circle,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),

        // Small pointer
        Transform.translate(
          offset: const Offset(0, -4),
          child: const Icon(
            Icons.arrow_drop_down_rounded,
            color: Color(0xFFF4511E),
            size: 22,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // OWNER REACH ZONE
  // ============================================================

  CircleMarker _buildReachCircle() {
    final LatLng owner =
        widget.ownerLocation!;

    return CircleMarker(
      point: owner,
      radius: 100,
      useRadiusInMeter: true,
      color:
          const Color(0xFFF4511E)
              .withValues(
        alpha: 0.08,
      ),
      borderColor:
          const Color(0xFFF4511E)
              .withValues(
        alpha: 0.45,
      ),
      borderStrokeWidth: 2,
    );
  }

  // ============================================================
  // ROUTE LINE
  // ============================================================

  Polyline _buildRouteLine() {
    final LatLng walker =
        widget.walkerLocation!;

    final LatLng owner =
        widget.ownerLocation!;

    return Polyline(
      points: <LatLng>[
        walker,
        owner,
      ],
      strokeWidth: 5,
      color:
          const Color(0xFF1976D2)
              .withValues(
        alpha: 0.82,
      ),
      borderStrokeWidth: 2,
      borderColor:
          Colors.white.withValues(
        alpha: 0.90,
      ),
    );
  }

  // ============================================================
  // STATUS BADGE
  // ============================================================

  Widget _buildStatusBadge() {
    final bool hasWalker =
        widget.walkerLocation != null;

    final bool hasOwner =
        widget.ownerLocation != null;

    final String text;

    if (hasWalker && hasOwner) {
      text = 'LIVE LOCATION';
    } else if (hasWalker) {
      text = 'YOUR LOCATION';
    } else if (hasOwner) {
      text = 'OWNER LOCATION';
    } else {
      text = 'GETTING LOCATION';
    }

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
        border: Border.all(
          color:
              Colors.black.withValues(
            alpha: 0.06,
          ),
        ),
        boxShadow:
            const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 3),
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
                BoxDecoration(
              shape: BoxShape.circle,
              color:
                  hasWalker && hasOwner
                      ? Colors.green
                      : Colors.orange,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP CONTROL BUTTON
  // ============================================================

  Widget _buildRecenterButton() {
    return Material(
      color: Colors.white,
      elevation: 5,
      borderRadius:
          BorderRadius.circular(14),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () {
          if (!_mapReady) {
            return;
          }

          if (widget.walkerLocation != null &&
              widget.ownerLocation != null) {
            _fitBothLocations();
            return;
          }

          final LatLng center =
              _mapCenter;

          try {
            _mapController.move(
              center,
              15,
            );
          } catch (error) {
            debugPrint(
              'Map recenter error: $error',
            );
          }
        },
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            Icons.my_location_rounded,
            size: 21,
            color: Color(0xFF17202A),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY MAP OVERLAY
  // ============================================================

  Widget _buildEmptyOverlay() {
    if (widget.walkerLocation != null ||
        widget.ownerLocation != null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color:
              Colors.white.withValues(
            alpha: 0.82,
          ),
          alignment: Alignment.center,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.location_searching_rounded,
                size: 30,
                color: Color(0xFF1976D2),
              ),
              SizedBox(height: 9),
              Text(
                'Getting locations...',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

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
        // --------------------------------------------------------
        // MAP
        // --------------------------------------------------------

        Positioned.fill(
          child: FlutterMap(
            mapController:
                _mapController,
            options: MapOptions(
              initialCenter:
                  _mapCenter,
              initialZoom:
                  walker != null || owner != null
                      ? 14
                      : 5,

              interactionOptions:
                  const InteractionOptions(
                flags:
                    InteractiveFlag.all,
              ),

              onMapReady: () {
                _mapReady = true;

                if (walker != null &&
                    owner != null &&
                    !_hasInitialFit) {
                  _hasInitialFit = true;

                  WidgetsBinding.instance
                      .addPostFrameCallback(
                    (_) {
                      if (mounted) {
                        _fitBothLocations();
                      }
                    },
                  );
                }
              },
            ),

            children: <Widget>[
              // --------------------------------------------------
              // OPENSTREETMAP
              // --------------------------------------------------

              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.doojowalker.app',
                maxZoom: 19,
                minZoom: 3,
                tileProvider:
                    NetworkTileProvider(),
              ),

              // --------------------------------------------------
              // REACH ZONE
              // --------------------------------------------------

              if (owner != null)
                CircleLayer(
                  circles: <CircleMarker>[
                    _buildReachCircle(),
                  ],
                ),

              // --------------------------------------------------
              // ROUTE
              // --------------------------------------------------

              if (walker != null &&
                  owner != null)
                PolylineLayer(
                  polylines: <Polyline>[
                    _buildRouteLine(),
                  ],
                ),

              // --------------------------------------------------
              // MARKERS
              // --------------------------------------------------

              if (markers.isNotEmpty)
                MarkerLayer(
                  markers: markers,
                ),
            ],
          ),
        ),

        // --------------------------------------------------------
        // TOP STATUS
        // --------------------------------------------------------

        Positioned(
          top: 105,
          left: 14,
          child: _buildStatusBadge(),
        ),

        // --------------------------------------------------------
        // RECENTER BUTTON
        // --------------------------------------------------------

        Positioned(
          right: 14,
          top: 105,
          child: _buildRecenterButton(),
        ),

        // --------------------------------------------------------
        // EMPTY / LOADING
        // --------------------------------------------------------

        _buildEmptyOverlay(),
      ],
    );
  }
}
