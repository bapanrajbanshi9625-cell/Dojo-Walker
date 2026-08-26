import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_walk_controller.dart';
import '../widgets/live_walk_bottom_sheet.dart';
import '../widgets/live_walk_complete_slider.dart';
import '../widgets/live_walk_map_layer.dart';
import '../widgets/live_walk_review_bottom_sheet.dart';
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

class _LiveWalkScreenState extends State<LiveWalkScreen> {
  late final LiveWalkController _controller;

  bool _showingEndDialog = false;
  bool _showingReview = false;

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

    _controller.addListener(_onControllerChanged);

    unawaited(
      _controller.initialize(),
    );
  }

  // ============================================================
  // CONTROLLER
  // ============================================================

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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
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

        final bool showStartPanel =
            !_controller.walkStarted &&
            !_controller.ending;

        final bool showLiveBottom =
            _controller.walkStarted &&
            !_controller.ending;

        return Scaffold(
          backgroundColor:
              AppColors.cardBackground,

          // ======================================================
          // APP BAR
          // ======================================================

          appBar: AppBar(
            automaticallyImplyLeading: false,
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
              // --------------------------------------------------
              // SOS
              // --------------------------------------------------

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

              // --------------------------------------------------
              // SUPPORT
              // --------------------------------------------------

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

          // ======================================================
          // BODY
          // ======================================================

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
              // START WALK PANEL
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
              // LIVE BOTTOM SHEET
              // ==================================================

              if (showLiveBottom)
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
                        _confirmCompleteWalk,
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

      _showMessage(
        'Walk started.',
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
  // COMPLETE CONFIRMATION
  // ============================================================

  void _confirmCompleteWalk() {
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
            // --------------------------------------------------
            // CANCEL
            // --------------------------------------------------

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

            // --------------------------------------------------
            // CONTINUE
            // --------------------------------------------------

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
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(12),
                ),
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
                // ------------------------------------------------
                // HANDLE
                // ------------------------------------------------

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

                // ------------------------------------------------
                // ICON
                // ------------------------------------------------

                const Icon(
                  Icons
                      .check_circle_outline_rounded,
                  color:
                      AppColors.primary,
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
                      _completeWalk(),
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
  // COMPLETE WALK
  // ============================================================

  Future<void> _completeWalk() async {
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

      await Future<void>.delayed(
        const Duration(
          milliseconds: 250,
        ),
      );

      if (!mounted) {
        return;
      }

      await _openReviewBottomSheet();
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
  // REVIEW
  // ============================================================

  Future<void> _openReviewBottomSheet() async {
    if (!mounted ||
        _showingReview) {
      return;
    }

    _showingReview = true;

    final Map<String, dynamic> data =
        _controller.currentSessionData;

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

    final List<Offset> routePoints =
        _extractRoutePoints(data);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor:
          Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (_) {
        return LiveWalkReviewBottomSheet(
          routePoints:
              routePoints,
          distanceKm:
              distance,
          duration:
              duration,
          steps:
              steps,
          walkId:
              widget.walkId,
          ownerUid:
              widget.ownerUid,
          dogName:
              widget.dogName,
          onBackToHome: () {
            Navigator.of(
              context,
            ).pop();
          },
        );
      },
    );

    _showingReview = false;

    if (!mounted) {
      return;
    }

    // ----------------------------------------------------------
    // LEAVE LIVE WALK SCREEN
    // ----------------------------------------------------------

    Navigator.of(
      context,
    ).pop(true);
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
      // --------------------------------------------------------
      // FIRESTORE GEOPOINT
      // --------------------------------------------------------

      if (item is GeoPoint) {
        points.add(
          Offset(
            item.latitude,
            item.longitude,
          ),
        );

        continue;
      }

      // --------------------------------------------------------
      // MAP
      // --------------------------------------------------------

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
      final String text =
          value.toString().trim();

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '0m';
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
                // ------------------------------------------------
                // HANDLE
                // ------------------------------------------------

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
                  Icons.support_agent_rounded,
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
  // DOUBLE
  // ============================================================

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

  // ============================================================
  // INT
  // ============================================================

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

  // ============================================================
  // ERROR
  // ============================================================

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

  // ============================================================
  // ERROR MESSAGE
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

  // ============================================================
  // NORMAL MESSAGE
  // ============================================================

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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _controller.dispose();

    super.dispose();
  }
}
