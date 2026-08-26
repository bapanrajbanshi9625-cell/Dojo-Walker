import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_walk_controller.dart';
import '../widgets/live_walk_bottom_sheet.dart';
import '../widgets/live_walk_complete_slider.dart';
import '../widgets/live_walk_map_layer.dart';
import '../widgets/live_walk_sos_sheet.dart';
import '../widgets/live_walk_start_panel.dart';

class LiveWalkScreen extends StatefulWidget {
  const LiveWalkScreen({
    super.key,
    required this.ownerUid,
    required this.ownerName,
    required this.walkId,
    required this.dogName,
    this.dogBreed = '',
    this.ownerPhone,
    this.sessionId,
  });

  final String ownerUid;
  final String ownerName;
  final String walkId;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;
  final String? sessionId;

  @override
  State<LiveWalkScreen> createState() =>
      _LiveWalkScreenState();
}

class _LiveWalkScreenState
    extends State<LiveWalkScreen> {
  late final LiveWalkController _controller;

  bool _showingEndDialog = false;

  @override
  void initState() {
    super.initState();

    _controller = LiveWalkController(
      ownerUid: widget.ownerUid,
      ownerName: widget.ownerName,
      walkId: widget.walkId,
      dogName: widget.dogName,
      dogBreed: widget.dogBreed,
      ownerPhone: widget.ownerPhone,
      sessionId: widget.sessionId,
    );

    _controller.addListener(
      _onControllerChanged,
    );

    unawaited(
      _controller.initialize(),
    );
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get _sessionStream {
    return _controller.sessionStream;
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: _sessionStream,
      builder: (
        BuildContext context,
        AsyncSnapshot<
                DocumentSnapshot<
                    Map<String, dynamic>>>
            snapshot,
      ) {
        final Map<String, dynamic> data =
            snapshot.data?.data() ??
                <String, dynamic>{};

        if (data.isNotEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            _controller.updateFromSession(data);
          });
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        // ======================================================
        // WALK COMPLETED
        // ======================================================

        if (status == 'completed' ||
            status == 'ended') {
          return _completedScreen(data);
        }

        final bool showStartPanel =
            !_controller.walkStarted &&
            !_controller.ending;

        final bool showBottomSheet =
            _controller.walkStarted;

        return Scaffold(
          backgroundColor:
              AppColors.cardBackground,

          appBar: AppBar(
            automaticallyImplyLeading:
                false,
            backgroundColor:
                AppColors.primary,
            surfaceTintColor:
                AppColors.primary,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'LIVE WALK',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: .4,
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'SOS',
                onPressed:
                    _controller.ending
                        ? null
                        : _openSos,
                icon: const Icon(
                  Icons.sos_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              IconButton(
                tooltip: 'Support',
                onPressed:
                    _controller.ending
                        ? null
                        : _openSupport,
                icon: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          body: Stack(
            children: [
              // ==================================================
              // LIVE MAP
              // ==================================================

              Positioned.fill(
                child: LiveWalkMapLayer(
                  sessionData: data,
                  gpsReady:
                      _controller.gpsReady,
                ),
              ),

              // ==================================================
              // START
              // ==================================================

              if (showStartPanel)
                LiveWalkStartPanel(
                  enabled:
                      !_controller.startingWalk &&
                      !_controller.ending,
                  starting:
                      _controller.startingWalk,
                  onStarted:
                      _startWalk,
                ),

              // ==================================================
              // LIVE WALK BOTTOM
              // ==================================================

              if (showBottomSheet)
                Align(
                  alignment:
                      Alignment.bottomCenter,
                  child:
                      LiveWalkBottomSheet(
                    ownerName:
                        widget.ownerName,
                    dogName:
                        widget.dogName,
                    dogBreed:
                        widget.dogBreed,
                    ownerPhone:
                        widget.ownerPhone,
                    sessionData:
                        data,
                    ending:
                        _controller.ending,
                    onEndWalk:
                        _confirmEndWalk,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // START WALK
  // ============================================================

  Future<void> _startWalk() async {
    if (_controller.startingWalk ||
        _controller.walkStarted ||
        _controller.ending) {
      return;
    }

    try {
      await _controller.startWalk();

      if (!mounted) {
        return;
      }

      _showMessage('Walk started.');
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(_cleanError(e));
    }
  }

  // ============================================================
  // END CONFIRMATION
  // ============================================================

  void _confirmEndWalk() {
    if (_controller.ending ||
        _showingEndDialog) {
      return;
    }

    if (!_controller.walkStarted) {
      _showError(
        'Start the walk first.',
      );
      return;
    }

    _showingEndDialog = true;

    showDialog<void>(
      context: context,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          backgroundColor:
              AppColors.cardBackground,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Text(
            'Complete Walk?',
            style: TextStyle(
              color:
                  AppColors.secondary,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to complete this walk?',
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color:
                      AppColors.secondary,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                _openCompleteSlider();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primary,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Continue',
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _showingEndDialog = false;
    });
  }

  // ============================================================
  // COMPLETE SLIDER
  // ============================================================

  void _openCompleteSlider() {
    if (!mounted ||
        _controller.ending ||
        !_controller.walkStarted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              20,
            ),
            decoration:
                const BoxDecoration(
              color:
                  AppColors.cardBackground,
              borderRadius:
                  BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.border,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 42,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Complete Walk',
                  style: TextStyle(
                    color:
                        AppColors.secondary,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Slide all the way to complete the walk.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                LiveWalkCompleteSlider(
                  enabled:
                      !_controller.ending,
                  onCompleted: () {
                    Navigator.of(
                      context,
                    ).pop();

                    unawaited(
                      _endWalk(),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // END WALK
  // ============================================================

  Future<void> _endWalk() async {
    if (_controller.ending ||
        !_controller.walkStarted) {
      return;
    }

    try {
      await _controller.endWalk();

      if (!mounted) {
        return;
      }

      _showMessage(
        'Walk completed.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        _cleanError(e),
      );
    }
  }

  // ============================================================
  // COMPLETED SCREEN
  // ============================================================

  Widget _completedScreen(
    Map<String, dynamic> data,
  ) {
    final double distance =
        _readDouble(
              data['distanceKm'],
            ) ??
            _controller.totalDistanceKm;

    final int steps =
        _readInt(
              data['steps'],
            ) ??
            _controller.steps;

    final String duration =
        _readDuration(data);

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading:
            false,
        backgroundColor:
            AppColors.primary,
        surfaceTintColor:
            AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'WALK COMPLETED',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            16,
            18,
            16,
            24,
          ),
          child: Column(
            children: [
              // ==================================================
              // SUCCESS HEADER
              // ==================================================

              Container(
                width: 82,
                height: 82,
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.success
                          .withValues(
                    alpha: .12,
                  ),
                  shape:
                      BoxShape.circle,
                ),
                child:
                    const Icon(
                  Icons
                      .thumb_up_alt_rounded,
                  color:
                      AppColors.success,
                  size: 46,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Walk Completed!',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color:
                      AppColors.secondary,
                  fontSize: 25,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                'Great job! Your walk has been completed.',
                textAlign:
                    TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // POLYLINE ROUTE
              // ==================================================

              Container(
                width: double.infinity,
                height: 220,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,
                  borderRadius:
                      BorderRadius.circular(20),
                  border:
                      Border.all(
                    color:
                        AppColors.border,
                  ),
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),
                  child:
                      _WalkRoutePreview(
                    routePoints:
                        _extractRoutePoints(
                      data,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // STATS
              // ==================================================

              Row(
                children: [
                  Expanded(
                    child:
                        _completedStat(
                      Icons.route_rounded,
                      distance
                          .toStringAsFixed(2),
                      'KM',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child:
                        _completedStat(
                      Icons.timer_rounded,
                      duration,
                      'DURATION',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child:
                        _completedStat(
                      Icons.directions_walk_rounded,
                      '$steps',
                      'STEPS',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // ==================================================
              // REVIEW
              // ==================================================

              _ReviewCard(),

              const SizedBox(height: 20),

              // ==================================================
              // HOME
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 54,
                child:
                    ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(true);
                  },
                  icon: const Icon(
                    Icons.home_rounded,
                  ),
                  label: const Text(
                    'Back to Walker Home',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor:
                        Colors.white,
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        15,
                      ),
                    ),
                    textStyle:
                        const TextStyle(
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT
  // ============================================================

  Widget _completedStat(
    IconData icon,
    String value,
    String title,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 14,
        horizontal: 6,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(16),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color:
                AppColors.primary,
            size: 22,
          ),
          const SizedBox(height: 7),
          Text(
            value,
            textAlign:
                TextAlign.center,
            style:
                const TextStyle(
              color:
                  AppColors.secondary,
              fontSize: 15,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 8,
              fontWeight:
                  FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROUTE POINTS
  // ============================================================

  List<Offset> _extractRoutePoints(
    Map<String, dynamic> data,
  ) {
    final dynamic raw =
        data['routePoints'] ??
            data['polylinePoints'] ??
            data['locations'];

    if (raw is! List) {
      return <Offset>[];
    }

    final List<Offset> points =
        <Offset>[];

    for (final dynamic item in raw) {
      if (item is GeoPoint) {
        points.add(
          Offset(
            item.latitude,
            item.longitude,
          ),
        );
        continue;
      }

      if (item is Map) {
        final dynamic lat =
            item['latitude'] ??
                item['lat'];

        final dynamic lng =
            item['longitude'] ??
                item['lng'] ??
                item['lon'];

        final double? latitude =
            _readDouble(lat);

        final double? longitude =
            _readDouble(lng);

        if (latitude != null &&
            longitude != null) {
          points.add(
            Offset(
              latitude,
              longitude,
            ),
          );
        }
      }
    }

    return points;
  }

  // ============================================================
  // DURATION
  // ============================================================

  String _readDuration(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['durationMinutes'] ??
            data['duration'];

    if (value is num) {
      final int minutes =
          value.toInt();

      if (minutes < 60) {
        return '${minutes}m';
      }

      final int hours =
          minutes ~/ 60;

      final int remaining =
          minutes % 60;

      return '${hours}h ${remaining}m';
    }

    if (value != null) {
      return value
          .toString()
          .trim();
    }

    return '--';
  }

  // ============================================================
  // SOS
  // ============================================================

  void _openSos() {
    if (_controller.ending) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return const LiveWalkSosSheet();
      },
    );
  }

  // ============================================================
  // SUPPORT
  // ============================================================

  void _openSupport() {
    if (_controller.ending) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      builder: (_) {
        return Container(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            25,
          ),
          decoration:
              const BoxDecoration(
            color:
                AppColors.cardBackground,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.border,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(
                  Icons
                      .support_agent_rounded,
                  color:
                      AppColors.primary,
                  size: 38,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Walk Support',
                  style: TextStyle(
                    color:
                        AppColors.secondary,
                    fontSize: 19,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Need help during this walk?',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child:
                      ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop();

                      _showMessage(
                        'Support contact will be connected soon.',
                      );
                    },
                    icon: const Icon(
                      Icons
                          .support_agent_rounded,
                    ),
                    label: const Text(
                      'Contact Support',
                    ),
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor:
                          Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          backgroundColor:
              AppColors.error,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content:
              Text(message),
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  double? _readDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  int? _readInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString().trim(),
    );
  }

  String _cleanError(
    Object error,
  ) {
    return error
        .toString()
        .replaceFirst(
          'Exception: ',
          '',
        )
        .trim();
  }

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _controller.dispose();

    super.dispose();
  }
}

// ============================================================
// REVIEW CARD
// ============================================================

class _ReviewCard extends StatefulWidget {
  @override
  State<_ReviewCard> createState() =>
      _ReviewCardState();
}

class _ReviewCardState
    extends State<_ReviewCard> {
  int _rating = 0;

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.fromLTRB(
        16,
        16,
        16,
        14,
      ),
      decoration:
          BoxDecoration(
        color:
            AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(18),
        border:
            Border.all(
          color:
              AppColors.border,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Rate this walk',
            style: TextStyle(
              color:
                  AppColors.secondary,
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'How was your walk experience?',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: List.generate(
              5,
              (int index) {
                final int star =
                    index + 1;

                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = star;
                    });
                  },
                  splashRadius: 22,
                  icon: Icon(
                    star <= _rating
                        ? Icons.star_rounded
                        : Icons
                            .star_border_rounded,
                    color:
                        star <= _rating
                            ? AppColors.primary
                            : Colors.grey,
                    size: 32,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SIMPLE POLYLINE PREVIEW
// ============================================================

class _WalkRoutePreview
    extends StatelessWidget {
  const _WalkRoutePreview({
    required this.routePoints,
  });

  final List<Offset> routePoints;

  @override
  Widget build(
    BuildContext context,
  ) {
    return CustomPaint(
      painter:
          _WalkRoutePainter(
        routePoints,
      ),
      child: Center(
        child:
            routePoints.isEmpty
                ? Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.route_rounded,
                        color:
                            AppColors.primary,
                        size: 38,
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        'Walk route',
                        style:
                            TextStyle(
                          color:
                              AppColors.secondary,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : null,
      ),
    );
  }
}

class _WalkRoutePainter
    extends CustomPainter {
  const _WalkRoutePainter(
    this.points,
  );

  final List<Offset> points;

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    if (points.length < 2) {
      return;
    }

    double minX =
        points.first.dx;
    double maxX =
        points.first.dx;
    double minY =
        points.first.dy;
    double maxY =
        points.first.dy;

    for (final Offset point
        in points) {
      if (point.dx < minX) {
        minX = point.dx;
      }

      if (point.dx > maxX) {
        maxX = point.dx;
      }

      if (point.dy < minY) {
        minY = point.dy;
      }

      if (point.dy > maxY) {
        maxY = point.dy;
      }
    }

    final double width =
        maxX - minX == 0
            ? 1
            : maxX - minX;

    final double height =
        maxY - minY == 0
            ? 1
            : maxY - minY;

    final double scaleX =
        (size.width - 40) / width;

    final double scaleY =
        (size.height - 40) / height;

    final double scale =
        scaleX < scaleY
            ? scaleX
            : scaleY;

    Offset convert(
      Offset point,
    ) {
      return Offset(
        20 +
            (point.dx - minX) *
                scale,
        20 +
            (maxY - point.dy) *
                scale,
      );
    }

    final Paint routePaint =
        Paint()
          ..color =
              AppColors.primary
          ..style =
              PaintingStyle.stroke
          ..strokeWidth = 5
          ..strokeCap =
              StrokeCap.round
          ..strokeJoin =
              StrokeJoin.round;

    final Path path =
        Path();

    path.moveTo(
      convert(points.first).dx,
      convert(points.first).dy,
    );

    for (int i = 1;
        i < points.length;
        i++) {
      final Offset point =
          convert(points[i]);

      path.lineTo(
        point.dx,
        point.dy,
      );
    }

    canvas.drawPath(
      path,
      routePaint,
    );

    final Paint startPaint =
        Paint()
          ..color =
              AppColors.success;

    final Paint endPaint =
        Paint()
          ..color =
              AppColors.error;

    final Offset start =
        convert(points.first);

    final Offset end =
        convert(points.last);

    canvas.drawCircle(
      start,
      7,
      startPaint,
    );

    canvas.drawCircle(
      end,
      7,
      endPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _WalkRoutePainter oldDelegate,
  ) {
    return oldDelegate.points !=
        points;
  }
}
