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

  // ============================================================
  // GPS
  // ============================================================

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  Position? _position;

  // ============================================================
  // GPS SUBSCRIPTION
  // ============================================================

  StreamSubscription<Position>? _locationSubscription;

  // ============================================================
  // RADAR ANIMATION
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

    _startLocation();
  }

  // ============================================================
  // SEARCHING CHANGE
  // ============================================================

  @override
  void didUpdateWidget(
    covariant InstaWalkMapRadar oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (widget.searching != oldWidget.searching) {
      if (widget.searching) {
        _radarController.repeat();
      } else {
        _radarController.stop();
        _radarController.value = 0;
      }
    }
  }

  // ============================================================
  // START LOCATION
  // ============================================================

  Future<void> _startLocation() async {
    final Position? position =
        await _locationService.getCurrentLocation();

    if (!mounted) {
      return;
    }

    if (position != null) {
      setState(() {
        _position = position;
      });

      _moveMap(position);
    }

    final bool trackingStarted =
        await _locationService.startTracking();

    if (!trackingStarted || !mounted) {
      return;
    }

    await _locationSubscription?.cancel();

    _locationSubscription =
        _locationService.locationStream.listen(
      (Position position) {
        if (!mounted) {
          return;
        }

        setState(() {
          _position = position;
        });

        _moveMap(position);
      },
    );
  }

  // ============================================================
  // MOVE MAP TO WALKER
  // ============================================================

  void _moveMap(Position position) {
    if (!mounted) {
      return;
    }

    try {
      _mapController.move(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        15.2,
      );
    } catch (_) {
      // MapController may not be attached yet.
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        height: 260,
        child: Stack(
          children: [
            // ==================================================
            // OPENSTREETMAP
            // ==================================================

            FlutterMap(
              mapController: _mapController,
              options: const MapOptions(
                initialCenter: LatLng(
                  20.5937,
                  78.9629,
                ),
                initialZoom: 5,
                interactionOptions: InteractionOptions(
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

                // ==================================================
                // WALKER LOCATION
                // ==================================================

                if (_position != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(
                          _position!.latitude,
                          _position!.longitude,
                        ),
                        width: 48,
                        height: 48,
                        child: _buildWalkerMarker(),
                      ),
                    ],
                  ),

                // ==================================================
                // 3.5 KM SEARCH CIRCLE
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
                        color: Colors.blue.withOpacity(.08),
                        borderColor:
                            Colors.blue.withOpacity(.55),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),
              ],
            ),

            // ====================================================
            // RADAR OVERLAY
            // ====================================================

            if (widget.searching)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: _MapRadarPainter(
                          progress: _radarController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ====================================================
            // TOP STATUS
            // ====================================================

            Positioned(
              left: 12,
              top: 12,
              child: _buildStatus(),
            ),

            // ====================================================
            // GPS ERROR / LOADING
            // ====================================================

            if (_position == null)
              Positioned.fill(
                child: Container(
                  color: Colors.white.withOpacity(.82),
                  alignment: Alignment.center,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        size: 30,
                        color: Color(0xFF238EAE),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Getting current location...',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
  // WALKER MARKER
  // ============================================================

  Widget _buildWalkerMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.22),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF238EAE),
        ),
        child: const Icon(
          Icons.person_pin_circle_rounded,
          color: Colors.white,
          size: 27,
        ),
      ),
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.92),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.12),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF20A45A),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            widget.searching
                ? 'Searching • 3.5 km'
                : 'Current Location',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Color(0xFF263746),
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
    _locationSubscription?.cancel();
    _radarController.dispose();

    super.dispose();
  }
}

// ================================================================
// MAP RADAR PAINTER
// ================================================================

class _MapRadarPainter extends CustomPainter {
  final double progress;

  const _MapRadarPainter({
    required this.progress,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final Offset center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final double maxRadius =
        math.min(
          size.width,
          size.height,
        ) *
        .48;

    // ==========================================================
    // RADAR SWEEP
    // ==========================================================

    final double angle =
        progress * math.pi * 2;

    const double sweepWidth =
    math.pi / 3;

    final Paint sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - sweepWidth,
        endAngle: angle,
        colors: [
          Colors.transparent,
          Colors.cyan.withOpacity(.04),
          Colors.cyan.withOpacity(.18),
          Colors.cyan.withOpacity(.32),
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: maxRadius,
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

    final Paint ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.cyan.withOpacity(.20);

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        maxRadius * (i / 3),
        ringPaint,
      );
    }

    // ==========================================================
    // ROTATING LINE
    // ==========================================================

    final Offset end = Offset(
      center.dx +
          math.cos(angle) * maxRadius,
      center.dy +
          math.sin(angle) * maxRadius,
    );

    final Paint linePaint = Paint()
      ..strokeWidth = 2
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.cyan.withOpacity(.75),
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

    final Paint centerPaint = Paint()
      ..color = Colors.cyan.withOpacity(.80);

    canvas.drawCircle(
      center,
      5,
      centerPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _MapRadarPainter oldDelegate,
  ) {
    return oldDelegate.progress != progress;
  }
}
