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

class _InstaWalkMapRadarState extends State<InstaWalkMapRadar>
    with SingleTickerProviderStateMixin {
  // ============================================================
  // MAP
  // ============================================================

  final MapController _mapController = MapController();

  bool _mapReady = false;
  bool _hasCenteredInitially = false;

  // ============================================================
  // GPS
  // ============================================================

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  Position? _position;

  StreamSubscription<Position>? _locationSubscription;

  bool _locationLoading = true;
  String? _locationError;

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
  // LOCATION
  // ============================================================

  Future<void> _startLocation() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _locationLoading = true;
      _locationError = null;
    });

    // ----------------------------------------------------------
    // CHECK LOCATION SERVICE
    // ----------------------------------------------------------

    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationLoading = false;
        _locationError =
            'Location service is turned off.';
      });

      return;
    }

    // ----------------------------------------------------------
    // CHECK / REQUEST PERMISSION
    // ----------------------------------------------------------

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationLoading = false;
        _locationError =
            'Location permission denied.';
      });

      return;
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationLoading = false;
        _locationError =
            'Location permission is permanently denied.';
      });

      return;
    }

    // ----------------------------------------------------------
    // FIRST POSITION
    // ----------------------------------------------------------

    Position? position;

    // First use your existing location service.
    try {
      position =
          await _locationService.getCurrentLocation();
    } catch (_) {
      position = null;
    }

    // ----------------------------------------------------------
    // FALLBACK DIRECT GEOLOCATOR
    // ----------------------------------------------------------

    if (position == null) {
      try {
        position =
            await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
      } catch (_) {
        position = null;
      }
    }

    // ----------------------------------------------------------
    // POSITION RESULT
    // ----------------------------------------------------------

    if (position != null &&
        _isValidPosition(position)) {
      _setPosition(
        position,
        centerMap: true,
      );
    } else {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationLoading = false;
        _locationError =
            'Unable to get your current location.';
      });
    }

    // ----------------------------------------------------------
    // START CONTINUOUS TRACKING
    // ----------------------------------------------------------

    bool trackingStarted = false;

    try {
      trackingStarted =
          await _locationService.startTracking();
    } catch (_) {
      trackingStarted = false;
    }

    // ----------------------------------------------------------
    // USE SERVICE STREAM
    // ----------------------------------------------------------

    if (trackingStarted) {
      await _locationSubscription?.cancel();

      _locationSubscription =
          _locationService.locationStream.listen(
        (Position position) {
          if (!_isValidPosition(position)) {
            return;
          }

          _setPosition(
            position,
            centerMap: !_hasCenteredInitially,
          );
        },
        onError: (_) {
          // Keep map alive if stream temporarily fails.
        },
        cancelOnError: false,
      );

      return;
    }

    // ----------------------------------------------------------
    // FALLBACK DIRECT GEOLOCATOR STREAM
    // ----------------------------------------------------------

    await _locationSubscription?.cancel();

    const LocationSettings settings =
        LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _locationSubscription =
        Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        if (!_isValidPosition(position)) {
          return;
        }

        _setPosition(
          position,
          centerMap: !_hasCenteredInitially,
        );
      },
      onError: (_) {
        // GPS stream failure must not crash the map.
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
    final double lat = position.latitude;
    final double lng = position.longitude;

    if (!lat.isFinite || !lng.isFinite) {
      return false;
    }

    if (lat < -90 || lat > 90) {
      return false;
    }

    if (lng < -180 || lng > 180) {
      return false;
    }

    if (lat == 0 && lng == 0) {
      return false;
    }

    // Ignore extremely inaccurate fixes.
    if (position.accuracy > 150) {
      return false;
    }

    return true;
  }

  // ============================================================
  // SET POSITION
  // ============================================================

  void _setPosition(
    Position position, {
    required bool centerMap,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _position = position;
      _locationLoading = false;
      _locationError = null;
    });

    if (centerMap) {
      _centerOnPosition(position);
    }
  }

  // ============================================================
  // CENTER MAP
  // ============================================================

  void _centerOnPosition(
    Position position,
  ) {
    if (!_mapReady) {
      // Map is not attached yet.
      // build/mapReady callback will center it.
      return;
    }

    if (!mounted) {
      return;
    }

    try {
      _mapController.move(
        LatLng(
          position.latitude,
          position.longitude,
        ),
        15.5,
      );

      _hasCenteredInitially = true;
    } catch (_) {
      // Map controller may temporarily be unavailable.
    }
  }

  // ============================================================
  // MANUAL RECENTER
  // ============================================================

  void _recenter() {
    final Position? position = _position;

    if (position == null) {
      _startLocation();
      return;
    }

    _centerOnPosition(position);
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
            // OPENSTREETMAP
            // ==================================================

            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: const LatLng(
                  20.5937,
                  78.9629,
                ),
                initialZoom: 5,

                interactionOptions:
                    const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),

                onMapReady: () {
                  _mapReady = true;

                  final Position? position =
                      _position;

                  if (position != null) {
                    _centerOnPosition(position);
                  }
                },
              ),
              children: [
                // ==================================================
                // OSM TILES
                // ==================================================

                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.doojowalker.app',
                  maxZoom: 19,
                ),

                // ==================================================
                // 3.5 KM SEARCH RANGE
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
                            const Color(
                          0xFF238EAE,
                        ).withOpacity(.08),
                        borderColor:
                            const Color(
                          0xFF238EAE,
                        ).withOpacity(.55),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                // ==================================================
                // CURRENT WALKER LOCATION
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
            // RADAR OVERLAY
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
            // TOP STATUS
            // ====================================================

            Positioned(
              left: 12,
              top: 12,
              child: _buildStatus(),
            ),

            // ====================================================
            // RECENTER BUTTON
            // ====================================================

            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: Colors.white,
                elevation: 4,
                shadowColor:
                    Colors.black.withOpacity(.20),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _recenter,
                  customBorder:
                      const CircleBorder(),
                  child: const SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      Icons.my_location_rounded,
                      color: Color(0xFF238EAE),
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),

            // ====================================================
            // LOCATION ERROR
            // ====================================================

            if (_position == null &&
                !_locationLoading)
              Positioned(
                left: 16,
                right: 16,
                bottom: 12,
                child: _buildLocationError(),
              ),

            // ====================================================
            // SMALL LOADING INDICATOR
            //
            // IMPORTANT:
            // Do NOT cover the whole map.
            // ====================================================

            if (_position == null &&
                _locationLoading)
              Positioned(
                right: 12,
                top: 58,
                child: _buildLoadingIndicator(),
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
    return Stack(
      alignment: Alignment.center,
      children: [
        // ------------------------------------------------------
        // OUTER GLOW
        // ------------------------------------------------------

        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                const Color(0xFF238EAE)
                    .withOpacity(.16),
          ),
        ),

        // ------------------------------------------------------
        // WHITE BORDER
        // ------------------------------------------------------

        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          padding: const EdgeInsets.all(3),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF238EAE),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // STATUS
  // ============================================================

  Widget _buildStatus() {
    final bool hasLocation =
        _position != null;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.94),
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.12),
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
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasLocation
                  ? const Color(0xFF20A45A)
                  : const Color(0xFFFFA000),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            hasLocation
                ? widget.searching
                    ? 'Searching • 3.5 km'
                    : 'Current Location'
                : 'Locating...',
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
  // LOADING INDICATOR
  // ============================================================

  Widget _buildLoadingIndicator() {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.94),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.12),
            blurRadius: 8,
          ),
        ],
      ),
      padding: const EdgeInsets.all(9),
      child: const CircularProgressIndicator(
        strokeWidth: 2,
        valueColor:
            AlwaysStoppedAnimation<Color>(
          Color(0xFF238EAE),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION ERROR
  // ============================================================

  Widget _buildLocationError() {
    return Material(
      color: Colors.white.withOpacity(.95),
      borderRadius:
          BorderRadius.circular(12),
      child: InkWell(
        onTap: _startLocation,
        borderRadius:
            BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_off_rounded,
                size: 18,
                color: Color(0xFFE53935),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _locationError ??
                      'Unable to get location',
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                    color: Color(0xFF263746),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w900,
                  color: Color(0xFF238EAE),
                ),
              ),
            ],
          ),
        ),
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
        startAngle:
            angle - sweepWidth,
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
