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
  // ============================================================
  // CONTROLLER
  // ============================================================

  late final LiveWalkController _controller;

  // ============================================================
  // LOCAL UI
  // ============================================================

  bool _showingEndDialog = false;

  // ============================================================
  // INIT
  // ============================================================

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

  // ============================================================
  // CONTROLLER CHANGE
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // SESSION STREAM
  // ============================================================

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get _sessionStream {
    return _controller.sessionStream;
  }

  // ============================================================
  // BUILD
  // ============================================================

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

        // ======================================================
        // FIRESTORE -> CONTROLLER
        // ======================================================

        if (data.isNotEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (!mounted) {
              return;
            }

            _controller.updateFromSession(
              data,
            );
          });
        }

        // ======================================================
        // STATUS
        // ======================================================

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        // ======================================================
        // COMPLETED
        // ======================================================

        if (status == 'completed' ||
            status == 'ended') {
          return _completedScreen(
            data,
          );
        }

        // ======================================================
        // START PANEL
        // ======================================================

        final bool showStartPanel =
            !_controller.walkStarted &&
            !_controller.ending;

        // ======================================================
        // WALK STARTED
        // ======================================================

        final bool showBottomSheet =
            _controller.walkStarted;

        // ======================================================
        // LIVE SCREEN
        // ======================================================

        return Scaffold(
          backgroundColor:
              AppColors.cardBackground,

          // ====================================================
          // APP BAR
          // ====================================================

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
                fontWeight:
                    FontWeight.w900,
                letterSpacing: .4,
              ),
            ),

            actions: [
              // ------------------------------------------------
              // SOS
              // ------------------------------------------------

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

              // ------------------------------------------------
              // SUPPORT
              // ------------------------------------------------

              IconButton(
                tooltip: 'Support',
                onPressed:
                    _controller.ending
                        ? null
                        : _openSupport,
                icon: const Icon(
                  Icons
                      .support_agent_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),

          // ====================================================
          // BODY
          // ====================================================

          body: Stack(
            children: [
              // ------------------------------------------------
              // MAP
              // ------------------------------------------------

              Positioned.fill(
                child: LiveWalkMapLayer(
                  sessionData: data,
                  gpsReady:
                      _controller.gpsReady,
                ),
              ),

              // ------------------------------------------------
              // START PANEL
              // ------------------------------------------------

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

              // ------------------------------------------------
              // NORMAL WALK BOTTOM SHEET
              // ------------------------------------------------

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
  // CONFIRM END WALK
  //
  // IMPORTANT:
  //
  // यहां direct "End Walk" नहीं होगा.
  //
  // पहले confirmation dialog.
  // उसके बाद Complete Slider.
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
            'Slide to complete this walk. '
            'GPS tracking will stop after the walk is completed.',
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
                'Keep Walking',
                style: TextStyle(
                  color:
                      AppColors.secondary,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    ).whenComplete(() {
      _showingEndDialog = false;

      if (!mounted ||
          !_controller.walkStarted ||
          _controller.ending) {
        return;
      }

      // --------------------------------------------------------
      // COMPLETE SLIDER
      // --------------------------------------------------------

      _openCompleteSlider();
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
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) {
        return SafeArea(
          child: Container(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              18,
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
                // --------------------------------------------
                // HANDLE
                // --------------------------------------------

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

                const SizedBox(
                  height: 14,
                ),

                const Text(
                  'Complete Walk',
                  style: TextStyle(
                    color:
                        AppColors.secondary,
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'Slide to confirm that the walk is complete.',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 16,
                ),

                // --------------------------------------------
                // COMPLETE SLIDER
                // --------------------------------------------

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

      // --------------------------------------------------------
      // Controller ने:
      //
      // 1. Firestore completed
      // 2. Walk request completed
      // 3. GPS stopped
      //
      // कर दिया है.
      // --------------------------------------------------------

      _showMessage(
        'Walk completed.',
      );

      // --------------------------------------------------------
      // Firestore stream completed state दिखाएगा.
      //
      // यहां direct pop नहीं करेंगे.
      // --------------------------------------------------------

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

                const SizedBox(
                  height: 18,
                ),

                const Icon(
                  Icons
                      .support_agent_rounded,
                  color:
                      AppColors.primary,
                  size: 38,
                ),

                const SizedBox(
                  height: 10,
                ),

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

                const SizedBox(
                  height: 6,
                ),

                const Text(
                  'Need help during this walk?',
                  textAlign:
                      TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(
                  height: 18,
                ),

                SizedBox(
                  width:
                      double.infinity,
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

    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        automaticallyImplyLeading:
            false,
        backgroundColor:
            AppColors.primary,
        foregroundColor:
            Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'WALK COMPLETED',
          style: TextStyle(
            fontWeight:
                FontWeight.w900,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: [
                // =================================================
                // SUCCESS ICON
                // =================================================

                Container(
                  width: 100,
                  height: 100,
                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.success
                            .withValues(
                      alpha: .10,
                    ),
                    shape:
                        BoxShape.circle,
                  ),
                  child:
                      const Icon(
                    Icons
                        .check_circle_rounded,
                    color:
                        AppColors.success,
                    size: 80,
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                const Text(
                  'Walk Completed',
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

                const SizedBox(
                  height: 8,
                ),

                Text(
                  '${widget.dogName}\'s walk is complete.',
                  textAlign:
                      TextAlign.center,
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(
                  height: 25,
                ),

                // =================================================
                // STATS
                // =================================================

                Row(
                  children: [
                    Expanded(
                      child:
                          _completedStat(
                        '${distance.toStringAsFixed(2)} km',
                        'Distance',
                      ),
                    ),

                    const SizedBox(
                      width: 10,
                    ),

                    Expanded(
                      child:
                          _completedStat(
                        '$steps',
                        'Steps',
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 25,
                ),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(true);
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
                            BorderRadius.circular(
                          14,
                        ),
                      ),
                    ),
                    child:
                        const Text(
                      'Back to Walker Home',
                      style:
                          TextStyle(
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMPLETED STAT
  // ============================================================

  Widget _completedStat(
    String value,
    String title,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 10,
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
          Text(
            value,
            style:
                const TextStyle(
              color:
                  AppColors.secondary,
              fontSize: 16,
              fontWeight:
                  FontWeight.w900,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            title,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 9,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
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

  // ============================================================
  // MESSAGE
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
  // ERROR CLEANER
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
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _controller.removeListener(
      _onControllerChanged,
    );

    _controller.dispose();

    // IMPORTANT:
    //
    // Controller dispose GPS stop नहीं करता.
    //
    // Successful endWalk() ही GPS stop करता है.
    //

    super.dispose();
  }
}
