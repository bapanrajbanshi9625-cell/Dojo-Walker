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
  // LOCATION
  // ============================================================

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  Position? _position;

  StreamSubscription<Position>? _locationSubscription;

  bool _locationLoading = true;
  bool _locationError = false;

  String _locationMessage = 'Getting current location...';

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

    unawaited(_initializeLocation());
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
  // INITIALIZE LOCATION
  // ============================================================

  Future<void> _initializeLocation() async {
    if (!mounted) {
      return;
    }

    setState(() {
      _locationLoading = true;
      _locationError = false;
      _locationMessage = 'Checking GPS...';
    });

    // ----------------------------------------------------------
    // 1. USE EXISTING/CACHED POSITION FIRST
    // ----------------------------------------------------------

    final Position? cached =
        _locationService.currentPosition;

    if (cached != null &&
        _isValidPosition(cached)) {
      _setPosition(cached);
    }

    // ----------------------------------------------------------
    // 2. CHECK LOCATION PERMISSION + GPS
    // ----------------------------------------------------------

    bool permissionAllowed = false;

    try {
      permissionAllowed =
          await _locationService.ensurePermission();
    } catch (e) {
      debugPrint(
        'Location permission check error: $e',
      );
    }

    if (!permissionAllowed) {
      if (!mounted) {
        return;
      }

      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!mounted) {
        return;
      }

      setState(() {
        _locationLoading = false;
        _locationError = true;

        if (!serviceEnabled) {
          _locationMessage =
              'GPS is OFF. Turn on Location.';
        } else {
          _locationMessage =
              'Location permission required.';
        }
      });

      return;
    }

    // ----------------------------------------------------------
    // 3. GET REAL CURRENT LOCATION
    // ----------------------------------------------------------

    if (mounted) {
      setState(() {
        _locationMessage =
            'Getting current location...';
      });
    }

    try {
      final Position? position =
          await _locationService.getCurrentLocation();

      if (!mounted) {
        return;
      }

      if (position != null &&
          _isValidPosition(position)) {
        _setPosition(position);
      }
    } catch (e) {
      debugPrint(
        'Current location error: $e',
      );
    }

    // ----------------------------------------------------------
    // 4. START CONTINUOUS GPS
    // ----------------------------------------------------------

    bool trackingStarted = false;

    try {
      trackingStarted =
          await _locationService.startTracking();
    } catch (e) {
      debugPrint(
        'GPS tracking error: $e',
      );
    }

    if (!trackingStarted) {
      if (!mounted) {
        return;
      }

      // If we already have a valid position,
      // keep showing the map.
      if (_position != null) {
        setState(() {
          _locationLoading = false;
          _locationError = false;
          _locationMessage = 'Current Location';
        });
      } else {
        setState(() {
          _locationLoading = false;
          _locationError = true;
          _locationMessage =
              'Unable to start GPS tracking.';
        });
      }

      return;
    }

    // ----------------------------------------------------------
    // 5. LISTEN TO LOCATION SERVICE
    // ----------------------------------------------------------

    await _locationSubscription?.cancel();

    _locationSubscription =
        _locationService.locationStream.listen(
      (Position position) {
        if (!mounted) {
          return;
        }

        if (!_isValidPosition(position)) {
          return;
        }

        _setPosition(position);
      },
      onError: (Object error) {
        debugPrint(
          'Walker GPS stream error: $error',
        );
      },
      cancelOnError: false,
    );

    // ----------------------------------------------------------
    // 6. FINAL STATE
    // ----------------------------------------------------------

    if (!mounted) {
      return;
    }

    setState(() {
      _locationLoading = false;

      if (_position != null) {
        _locationError = false;
        _locationMessage =
            widget.searching
                ? 'Searching • 3.5 km'
                : 'Current Location';
      } else {
        _locationError = true;
        _locationMessage =
            'Waiting for GPS signal...';
      }
    });
  }

  // ============================================================
  // SET POSITION
  // ============================================================

  void _setPosition(Position position) {
    if (!_isValidPosition(position)) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _position = position;
      _locationLoading = false;
      _locationError = false;
      _locationMessage =
          widget.searching
              ? 'Searching • 3.5 km'
              : 'Current Location';
    });

    // Map may not be ready yet.
    // _centerMap() will safely wait.
    _centerMap(position);
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
    if (!mounted || !_mapReady) {
      return;
    }

    if (!_isValidPosition(position)) {
      return;
    }

    try {
      final LatLng point = LatLng(
        position.latitude,
        position.longitude,
      );

      // --------------------------------------------------------
      // FIRST LOCATION
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
      // ONLY FOLLOW GPS DURING SEARCH
      // --------------------------------------------------------

      if (widget.searching) {
        _mapController.move(
          point,
          16.0,
        );
      }
    } catch (e) {
      debugPrint(
        'Map center error: $e',
      );
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
      borderRadius:
          BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        height: 260,
        child: Stack(
          children: [
            // ==================================================
            // MAP
            // ==================================================

            FlutterMap(
              mapController:
                  _mapController,

              options: MapOptions(
                initialCenter:
                    _position == null
                        ? const LatLng(
                            20.5937,
                            78.9629,
                          )
                        : LatLng(
                            _position!.latitude,
                            _position!.longitude,
                          ),

                initialZoom:
                    _position == null
                        ? 5.0
                        : 16.0,

                interactionOptions:
                    const InteractionOptions(
                  flags:
                      InteractiveFlag.all,
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
                // OPEN STREET MAP
                // ==================================================

                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                  userAgentPackageName:
                      'com.doojowalker.app',

                  maxZoom: 19,
                ),

                // ==================================================
                // 3.5 KM SEARCH RADIUS
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
                        color: Colors.blue
                            .withOpacity(0.08),
                        borderColor:
                            Colors.blue
                                .withOpacity(0.55),
                        borderStrokeWidth: 2,
                      ),
                    ],
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
                        width: 52,
                        height: 52,
                        child:
                            _buildWalkerMarker(),
                      ),
                    ],
                  ),
              ],
            ),

            // ==================================================
            // RADAR
            // ==================================================

            if (widget.searching &&
                _position != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation:
                        _radarController,
                    builder:
                        (
                      BuildContext context,
                      Widget? child,
                    ) {
                      return CustomPaint(
                        painter:
                            _MapRadarPainter(
                          progress:
                              _radarController
                                  .value,
                        ),
                      );
                    },
                  ),
                ),
              ),

            // ==================================================
            // STATUS
            // ==================================================

            Positioned(
              left: 12,
              top: 12,
              child: _buildStatus(),
            ),

            // ==================================================
            // MY LOCATION
            // ==================================================

            Positioned(
              right: 12,
              bottom: 12,
              child:
                  _buildLocationButton(),
            ),

            // ==================================================
            // LOADING / ERROR
            // ==================================================

            if (_position == null)
              Positioned.fill(
                child: Container(
                  color: Colors.white
                      .withOpacity(0.82),
                  alignment:
                      Alignment.center,
                  child:
                      _buildLocationOverlay(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION OVERLAY
  // ============================================================

  Widget _buildLocationOverlay() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 24,
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          if (_locationLoading)
            const SizedBox(
              width: 25,
              height: 25,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
                color:
                    Color(0xFF238EAE),
              ),
            )
          else
            const Icon(
              Icons.location_off_rounded,
              size: 30,
              color:
                  Color(0xFF238EAE),
            ),

          const SizedBox(height: 10),

          Text(
            _locationMessage,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w800,
              color:
                  Color(0xFF263746),
            ),
          ),

          if (_locationError) ...[
            const SizedBox(height: 10),

            SizedBox(
              height: 36,
              child:
                  ElevatedButton.icon(
                onPressed:
                    () {
                  unawaited(
                    _initializeLocation(),
                  );
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 17,
                ),
                label:
                    const Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(
                    0xFF238EAE,
                  ),
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 16,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
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
          unawaited(
            _refreshLocation(),
          );
        },
        child: Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            color: Colors.white
                .withOpacity(0.95),
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(0.16),
                blurRadius: 8,
                offset:
                    const Offset(0, 2),
              ),
            ],
          ),
          child:
              const Icon(
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
    if (!mounted) {
      return;
    }

    setState(() {
      _locationLoading = true;
      _locationError = false;
      _locationMessage =
          'Getting current location...';
    });

    try {
      final bool allowed =
          await _locationService
              .ensurePermission();

      if (!allowed) {
        if (!mounted) {
          return;
        }

        final bool gpsEnabled =
            await Geolocator
                .isLocationServiceEnabled();

        if (!mounted) {
          return;
        }

        setState(() {
          _locationLoading = false;
          _locationError = true;
          _locationMessage =
              gpsEnabled
                  ? 'Location permission required.'
                  : 'GPS is OFF. Turn on Location.';
        });

        return;
      }

      final Position? position =
          await _locationService
              .getCurrentLocation();

      if (!mounted) {
        return;
      }

      if (position == null ||
          !_isValidPosition(position)) {
        setState(() {
          _locationLoading = false;
          _locationError = true;
          _locationMessage =
              'Unable to get GPS location.';
        });

        return;
      }

      _setPosition(position);

      _hasCenteredMap = true;

      _centerMap(position);
    } catch (e) {
      debugPrint(
        'Refresh location error: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _locationLoading = false;
        _locationError = true;
        _locationMessage =
            'Unable to get current location.';
      });
    }
  }

  // ============================================================
  // WALKER MARKER
  // ============================================================

  Widget _buildWalkerMarker() {
    return Container(
      decoration:
          const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
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
        child:
            const Icon(
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
      decoration:
          BoxDecoration(
        color: Colors.white
            .withOpacity(0.94),
        borderRadius:
            BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withOpacity(0.12),
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
            hasLocation
                ? widget.searching
                    ? 'Searching • 3.5 km'
                    : 'Current Location'
                : _locationMessage,
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
              radius: maxRadius,
            ),
          );

    canvas.drawCircle(
      center,
      maxRadius,
      sweepPaint,
    );

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
    covariant _MapRadarPainter oldDelegate,
  ) {
    return oldDelegate.progress !=
        progress;
  }
}
