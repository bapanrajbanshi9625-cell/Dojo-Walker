// File:
// lib/features/insta_walk/widgets/insta_walk_map_radar.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/walker_location_service.dart';

class InstaWalkMapRadar extends StatefulWidget {
  const InstaWalkMapRadar({
    super.key,
    required this.searching,
  });

  final bool searching;

  @override
  State<InstaWalkMapRadar> createState() =>
      _InstaWalkMapRadarState();
}

class _InstaWalkMapRadarState
    extends State<InstaWalkMapRadar>
    with SingleTickerProviderStateMixin {
  static const double _searchRadiusMeters = 3500;

  final MapController _mapController = MapController();

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  StreamSubscription<Position>? _locationSubscription;

  Position? _position;

  bool _mapReady = false;
  bool _hasInitialCenter = false;
  bool _locationLoading = true;
  bool _locationError = false;

  String _locationMessage = 'Getting current location...';

  late final AnimationController _radarController;

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

    if (_position != null && mounted) {
      setState(() {
        _locationMessage = widget.searching
            ? 'Searching • 3.5 km'
            : 'Current Location';
      });
    }
  }

  // ============================================================
  // LOCATION INITIALIZATION
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

    // Use cached location immediately if available.
    final Position? cached =
        _locationService.currentPosition;

    if (cached != null && _isValidPosition(cached)) {
      _setPosition(
        cached,
        centerMap: true,
      );
    }

    bool permissionAllowed = false;

    try {
      permissionAllowed =
          await _locationService.ensurePermission();
    } catch (error) {
      debugPrint(
        'Insta Walk permission error: $error',
      );
    }

    if (!permissionAllowed) {
      if (!mounted) {
        return;
      }

      final bool gpsEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!mounted) {
        return;
      }

      setState(() {
        _locationLoading = false;
        _locationError = true;
        _locationMessage = gpsEnabled
            ? 'Location permission required.'
            : 'GPS is OFF. Turn on Location.';
      });

      return;
    }

    try {
      final Position? current =
          await _locationService.getCurrentLocation();

      if (current != null &&
          _isValidPosition(current)) {
        _setPosition(
          current,
          centerMap: true,
        );
      }
    } catch (error) {
      debugPrint(
        'Insta Walk current location error: $error',
      );
    }

    bool trackingStarted = false;

    try {
      trackingStarted =
          await _locationService.startTracking();
    } catch (error) {
      debugPrint(
        'Insta Walk tracking error: $error',
      );
    }

    if (!trackingStarted) {
      if (!mounted) {
        return;
      }

      setState(() {
        _locationLoading = false;

        if (_position != null) {
          _locationError = false;
          _locationMessage = widget.searching
              ? 'Searching • 3.5 km'
              : 'Current Location';
        } else {
          _locationError = true;
          _locationMessage =
              'Unable to start GPS tracking.';
        }
      });

      return;
    }

    await _locationSubscription?.cancel();

    _locationSubscription =
        _locationService.locationStream.listen(
      (Position position) {
        if (!mounted ||
            !_isValidPosition(position)) {
          return;
        }

        // Do NOT recenter the map on every GPS update.
        // This keeps manual map movement smooth.
        _setPosition(
          position,
          centerMap: false,
        );
      },
      onError: (Object error) {
        debugPrint(
          'Insta Walk GPS stream error: $error',
        );
      },
      cancelOnError: false,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _locationLoading = false;

      if (_position != null) {
        _locationError = false;
        _locationMessage = widget.searching
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
  // POSITION
  // ============================================================

  void _setPosition(
    Position position, {
    required bool centerMap,
  }) {
    if (!mounted ||
        !_isValidPosition(position)) {
      return;
    }

    setState(() {
      _position = position;
      _locationLoading = false;
      _locationError = false;
      _locationMessage = widget.searching
          ? 'Searching • 3.5 km'
          : 'Current Location';
    });

    if (centerMap) {
      _centerOnPosition(
        position,
        force: !_hasInitialCenter,
      );
    }
  }

  bool _isValidPosition(Position position) {
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
  // MAP CENTER
  // ============================================================

  void _centerOnPosition(
    Position position, {
    bool force = false,
  }) {
    if (!mounted ||
        !_mapReady ||
        !_isValidPosition(position)) {
      return;
    }

    if (_hasInitialCenter && !force) {
      return;
    }

    try {
      final LatLng point = LatLng(
        position.latitude,
        position.longitude,
      );

      _hasInitialCenter = true;

      _mapController.move(
        point,
        15.5,
      );
    } catch (error) {
      debugPrint(
        'Insta Walk map center error: $error',
      );
    }
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
          await _locationService.ensurePermission();

      if (!allowed) {
        if (!mounted) {
          return;
        }

        final bool gpsEnabled =
            await Geolocator.isLocationServiceEnabled();

        if (!mounted) {
          return;
        }

        setState(() {
          _locationLoading = false;
          _locationError = true;
          _locationMessage = gpsEnabled
              ? 'Location permission required.'
              : 'GPS is OFF. Turn on Location.';
        });

        return;
      }

      final Position? position =
          await _locationService.getCurrentLocation();

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

      _setPosition(
        position,
        centerMap: true,
      );

      _hasInitialCenter = true;

      _centerOnPosition(
        position,
        force: true,
      );
    } catch (error) {
      debugPrint(
        'Insta Walk refresh location error: $error',
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
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Position? position = _position;

    final LatLng currentPoint = position == null
        ? const LatLng(
            20.5937,
            78.9629,
          )
        : LatLng(
            position.latitude,
            position.longitude,
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        width: double.infinity,
        height: 280,
        child: Stack(
          children: <Widget>[
            // ==================================================
            // OPEN STREET MAP
            // ==================================================

            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPoint,
                initialZoom:
                    position == null ? 5.0 : 15.5,

                minZoom: 3,
                maxZoom: 19,

                interactionOptions:
                    const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),

                onMapReady: () {
                  _mapReady = true;

                  final Position? current =
                      _position;

                  if (current != null) {
                    _centerOnPosition(
                      current,
                      force: !_hasInitialCenter,
                    );
                  }
                },
              ),

              children: <Widget>[
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                  userAgentPackageName:
                      'com.doojowalker.app',

                  maxZoom: 19,

                  tileProvider:
                      NetworkTileProvider(),
                ),

                // ==================================================
                // 3.5 KM SEARCH AREA
                // ==================================================

                if (position != null)
                  CircleLayer(
                    circles: <CircleMarker>[
                      CircleMarker(
                        point: currentPoint,
                        radius:
                            _searchRadiusMeters,
                        useRadiusInMeter: true,

                        color:
                            AppColors.info.withValues(
                          alpha: 0.07,
                        ),

                        borderColor:
                            AppColors.info.withValues(
                          alpha: 0.45,
                        ),

                        borderStrokeWidth: 2,
                      ),
                    ],
                  ),

                // ==================================================
                // WALKER MARKER
                // ==================================================

                if (position != null)
                  MarkerLayer(
                    markers: <Marker>[
                      Marker(
                        point: currentPoint,
                        width: 62,
                        height: 62,
                        child:
                            _buildWalkerMarker(),
                      ),
                    ],
                  ),
              ],
            ),

            // ====================================================
            // RADAR EFFECT
            // ====================================================

            if (widget.searching &&
                position != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation:
                        _radarController,
                    builder: (
                      BuildContext context,
                      Widget? child,
                    ) {
                      return CustomPaint(
                        painter:
                            _MapRadarPainter(
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
            // MY LOCATION BUTTON
            // ====================================================

            Positioned(
              right: 12,
              bottom: 12,
              child: _buildLocationButton(),
            ),

            // ====================================================
            // LOCATION LOADING / ERROR
            // ====================================================

            if (position == null)
              Positioned.fill(
                child: Container(
                  color:
                      Colors.white.withValues(
                    alpha: 0.88,
                  ),
                  alignment: Alignment.center,
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
  // WALKER MARKER
  // ============================================================

  Widget _buildWalkerMarker() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.info,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.person_pin_circle_rounded,
          color: AppColors.iconOnPrimary,
          size: 30,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(
          alpha: 0.96,
        ),
        borderRadius:
            BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 9,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: hasLocation
                  ? AppColors.success
                  : AppColors.warning,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            hasLocation
                ? widget.searching
                    ? 'SEARCHING • 3.5 KM'
                    : 'CURRENT LOCATION'
                : _locationMessage,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              letterSpacing: .1,
            ),
          ),
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
            BorderRadius.circular(15),
        onTap: () {
          unawaited(
            _refreshLocation(),
          );
        },
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.97,
            ),
            borderRadius:
                BorderRadius.circular(15),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 9,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.my_location_rounded,
            size: 22,
            color: AppColors.info,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION OVERLAY
  // ============================================================

  Widget _buildLocationOverlay() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (_locationLoading)
            SizedBox(
              width: 28,
              height: 28,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.info,
              ),
            )
          else
            Icon(
              Icons.location_off_rounded,
              size: 32,
              color: AppColors.info,
            ),

          const SizedBox(height: 11),

          Text(
            _locationMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),

          if (_locationError) ...[
            const SizedBox(height: 11),
            SizedBox(
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () {
                  unawaited(
                    _initializeLocation(),
                  );
                },
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 17,
                ),
                label: const Text(
                  'Retry',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.info,
                  foregroundColor:
                      AppColors.buttonText,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 17,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
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

class _MapRadarPainter extends CustomPainter {
  const _MapRadarPainter({
    required this.progress,
  });

  final double progress;

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
        0.43;

    final double angle =
        progress * math.pi * 2;

    const double sweepWidth =
        math.pi / 3;

    // ==========================================================
    // SOFT RADAR SWEEP
    // ==========================================================

    final Paint sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle:
            angle - sweepWidth,
        endAngle: angle,
        colors: <Color>[
          Colors.transparent,
          AppColors.info.withValues(
            alpha: 0.02,
          ),
          AppColors.info.withValues(
            alpha: 0.08,
          ),
          AppColors.info.withValues(
            alpha: 0.16,
          ),
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
      ..color = AppColors.info.withValues(
        alpha: 0.13,
      );

    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        center,
        maxRadius * (i / 3),
        ringPaint,
      );
    }

    // ==========================================================
    // RADAR LINE
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
        colors: <Color>[
          Colors.transparent,
          AppColors.info.withValues(
            alpha: 0.55,
          ),
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
    // CENTER DOT
    // ==========================================================

    final Paint centerPaint = Paint()
      ..color = AppColors.info.withValues(
        alpha: 0.75,
      );

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
