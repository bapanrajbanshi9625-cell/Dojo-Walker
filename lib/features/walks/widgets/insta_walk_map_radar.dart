// File location:
// lib/features/walks/widgets/insta_walk_map_radar.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/walker_location_service.dart';

class InstaWalkMapRadar extends StatefulWidget {
  final bool searching;

  const InstaWalkMapRadar({
    super.key,
    required this.searching,
  });

  @override
  State<InstaWalkMapRadar> createState() =>
      _InstaWalkMapRadarState();
}

class _InstaWalkMapRadarState
    extends State<InstaWalkMapRadar>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // MAP
  // ============================================================

  final MapController _mapController = MapController();

  bool _mapReady = false;
  bool _hasCenteredMap = false;

  // ============================================================
  // LOCATION SERVICE
  // ============================================================

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  Position? _position;

  StreamSubscription<Position>? _locationSubscription;

  // ============================================================
  // RADAR
  // ============================================================

  late final AnimationController _radarController;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.searching) {
      _radarController.repeat();
    }

    unawaited(_startLocation());
  }

  // ============================================================
  // SEARCHING CHANGE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant InstaWalkMapRadar oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.searching == oldWidget.searching) {
      return;
    }

    if (widget.searching) {
      _radarController.repeat();
    } else {
      _radarController.stop();
      _radarController.value = 0;
    }
  }

  // ============================================================
  // START LOCATION
  // ============================================================

  Future<void> _startLocation() async {
    // ----------------------------------------------------------
    // FIRST LOCATION
    // ----------------------------------------------------------

    try {
      final Position? position =
          await _locationService.getCurrentLocation();

      if (!mounted) {
        return;
      }

      if (position != null &&
          _isValidPosition(position)) {
        setState(() {
          _position = position;
        });

        _centerMap(position);
      }
    } catch (_) {
      // Continue with tracking.
    }

    // ----------------------------------------------------------
    // START LOCATION TRACKING
    // ----------------------------------------------------------

    bool trackingStarted = false;

    try {
      trackingStarted =
          await _locationService.startTracking();
    } catch (_) {
      trackingStarted = false;
    }

    if (!trackingStarted || !mounted) {
      return;
    }

    // ----------------------------------------------------------
    // CANCEL OLD SUBSCRIPTION
    // ----------------------------------------------------------

    await _locationSubscription?.cancel();

    // ----------------------------------------------------------
    // LOCATION STREAM
    //
    // IMPORTANT:
    // Installed Geolocator API accepts LocationSettings
    // as a positional argument here.
    // ----------------------------------------------------------

    _locationSubscription =
        _locationService.locationStream.listen(
      (Position position) {
        if (!mounted) {
          return;
        }

        if (!_isValidPosition(position)) {
          return;
        }

        setState(() {
          _position = position;
        });

        _centerMap(position);
      },
      onError: (_) {
        // GPS stream errors should not crash the map.
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // VALID POSITION
  // ============================================================

  bool _isValidPosition(
    Position position,
  ) {
    if (!position.latitude.isFinite ||
        !position.longitude.isFinite) {
      return false;
    }

    if (position.latitude < -90 ||
        position.latitude > 90) {
      return false;
    }

    if (position.longitude < -180 ||
        position.longitude > 180) {
      return false;
    }

    if (position.latitude == 0 &&
        position.longitude == 0) {
      return false;
    }

    return true;
  }

  // ============================================================
  // CENTER MAP
  // ============================================================

  void _centerMap(
    Position position,
  ) {
    if (!mounted ||
        !_mapReady) {
      return;
    }

    try {
      final LatLng point = LatLng(
        position.latitude,
        position.longitude,
      );

      // --------------------------------------------------------
      // First valid location:
      // Always center the map.
      // --------------------------------------------------------

      if (!_hasCenteredMap) {
        _hasCenteredMap = true;

        _mapController.move(
          point,
          16.0,
        );

        return;
      }

      // --------------------------------------------------------
      // During active search keep walker visible.
      // --------------------------------------------------------

      if (widget.searching) {
        _mapController.move(
          point,
          16.0,
        );
      }
    } catch (_) {
      // MapController may not be attached.
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        height: 260,
        child: Stack(
          children: [
            // ==================================================
            // OPEN STREET MAP
            // ==================================================

            FlutterMap(
              mapController: _mapController,

              options: MapOptions(
                initialCenter: _position == null
                    ? const LatLng(
                        20.5937,
                        78.9629,
                      )
                    : LatLng(
                        _position!.latitude,
                        _position!.longitude,
                      ),

                initialZoom:
                    _position == null ? 5.0 : 16.0,

                interactionOptions:
                    const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),

                onMapReady: () {
                  _mapReady = true;

                  final Position? position =
                      _position;

                  if (position != null) {
                    _centerMap(position);
                  }
                },
              ),

              children: [
                // ==================================================
                // OPENSTREETMAP TILES
                // ==================================================

                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.doojowalker.app',
                  maxZoom: 19,
                ),

                // ==================================================
                // 3.5 KM SEARCH AREA
                // ==================================================

                if (_position != null)
                  CircleLayer(
                    circles: [
                      CircleMarker(
                        point: LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        radius: 3500,
                        useRadiusInMeter: true,
                        color:
                            Colors.blue.withOpacity(0.08),
                        borderColor:
                            Colors.blue.withOpacity(0.55),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                // ==================================================
                // WALKER CURRENT LOCATION
                // ==================================================

                if (_position != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        width: 52,
                        height: 52,
                        child: _buildWalkerMarker(),
                      ),
                    ],
                  ),
              ],
            ),

            // ====================================================
            // RADAR ANIMATION
            // ====================================================

            if (widget.searching)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (
                      BuildContext context,
                      Widget? child,
                    ) {
                      return CustomPaint(
                        painter: _MapRadarPainter(
                          progress:
                              _radarController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ====================================================
            // STATUS
            // ====================================================

            Positioned(
              left: 12,
              top: 12,
              child: _buildStatus(),
            ),

            // ====================================================
            // MY LOCATION BUTTON
            // ====================================================

            Positioned(
              right: 12,
              bottom: 12,
              child: _buildLocationButton(),
            ),

            // ====================================================
            // LOCATION LOADING
            // ====================================================

            if (_position == null)
              Positioned.fill(
                child: Container(
                  color:
                      Colors.white.withOpacity(0.82),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color:
                              Color(0xFF238EAE),
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Getting current location...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              Color(0xFF263746),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION BUTTON
  // ============================================================

  Widget _buildLocationButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius:
            BorderRadius.circular(14),
        onTap: () {
          final Position? position =
              _position;

          if (position != null) {
            _hasCenteredMap = true;

            _mapController.move(
              LatLng(
                position.latitude,
                position.longitude,
              ),
              16.0,
            );
          } else {
            unawaited(
              _refreshLocation(),
            );
          }
        },
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                Colors.white.withOpacity(0.95),
            borderRadius:
                BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color:
                    Colors.black.withOpacity(0.16),
                blurRadius: 8,
                offset:
                    const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.my_location_rounded,
            size: 21,
            color:
                Color(0xFF238EAE),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // REFRESH LOCATION
  // ============================================================

  Future<void> _refreshLocation() async {
    try {
      final Position? position =
          await _locationService.getCurrentLocation();

      if (!mounted ||
          position == null ||
          !_isValidPosition(position)) {
        return;
      }

      setState(() {
        _position = position;
      });

      _hasCenteredMap = true;

      _centerMap(position);
    } catch (_) {
      // Ignore temporary GPS failures.
    }
  }

  // ============================================================
  // WALKER MARKER
  // ============================================================

  Widget _buildWalkerMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.22),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      padding:
          const EdgeInsets.all(5),
      child: Container(
        decoration:
            const BoxDecoration(
          shape: BoxShape.circle,
          color:
              Color(0xFF238EAE),
        ),
        child: const Icon(
          Icons.person_pin_circle_rounded,
          color: Colors.white,
          size: 29,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatus() {
    final bool hasLocation =
        _position != null;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.94),
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration:
                BoxDecoration(
              shape:
                  BoxShape.circle,
              color: hasLocation
                  ? const Color(
                      0xFF20A45A,
                    )
                  : Colors.orange,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            !hasLocation
                ? 'Getting location...'
                : widget.searching
                    ? 'Searching • 3.5 km'
                    : 'Current Location',
            style:
                const TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF263746),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    unawaited(
      _locationSubscription?.cancel(),
    );

    _radarController.dispose();

    super.dispose();
  }
}

// ================================================================
// MAP RADAR PAINTER
// ================================================================

class _MapRadarPainter
    extends CustomPainter {
  final double progress;

  const _MapRadarPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center =
        Offset(
      size.width / 2,
      size.height / 2,
    );

    final double maxRadius =
        math.min(
          size.width,
          size.height,
        ) *
        0.48;

    // ==========================================================
    // RADAR SWEEP
    // ==========================================================

    final double angle =
        progress *
        math.pi *
        2;

    const double sweepWidth =
        math.pi / 3;

    final Paint sweepPaint =
        Paint()
          ..shader =
              SweepGradient(
            startAngle:
                angle -
                    sweepWidth,
            endAngle:
                angle,
            colors: [
              Colors.transparent,
              Colors.cyan
                  .withOpacity(0.04),
              Colors.cyan
                  .withOpacity(0.18),
              Colors.cyan
                  .withOpacity(0.32),
            ],
          ).createShader(
            Rect.fromCircle(
              center: center,
              radius:
                  maxRadius,
            ),
          );

    canvas.drawCircle(
      center,
      maxRadius,
      sweepPaint,
    );

    // ==========================================================
    // RADAR RINGS
    // ==========================================================

    final Paint ringPaint =
        Paint()
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = Colors.cyan
              .withOpacity(0.20);

    for (int i = 1;
        i <= 3;
        i++) {
      canvas.drawCircle(
        center,
        maxRadius *
            (i / 3),
        ringPaint,
      );
    }

    // ==========================================================
    // ROTATING LINE
    // ==========================================================

    final Offset end =
        Offset(
      center.dx +
          math.cos(angle) *
              maxRadius,
      center.dy +
          math.sin(angle) *
              maxRadius,
    );

    final Paint linePaint =
        Paint()
          ..strokeWidth = 2
          ..shader =
              LinearGradient(
            colors: [
              Colors.transparent,
              Colors.cyan
                  .withOpacity(0.75),
            ],
          ).createShader(
            Rect.fromPoints(
              center,
              end,
            ),
          );

    canvas.drawLine(
      center,
      end,
      linePaint,
    );

    // ==========================================================
    // CENTER GLOW
    // ==========================================================

    final Paint centerPaint =
        Paint()
          ..color = Colors.cyan
              .withOpacity(0.80);

    canvas.drawCircle(
      center,
      5,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _MapRadarPainter
        oldDelegate,
  ) {
    return oldDelegate.progress !=
        progress;
  }
}
