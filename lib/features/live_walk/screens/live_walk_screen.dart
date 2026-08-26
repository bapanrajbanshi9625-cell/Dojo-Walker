import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_walk_controller.dart';
import '../widgets/live_walk_app_bar.dart';
import '../widgets/live_walk_bottom_sheet.dart';
import '../widgets/live_walk_completed_screen.dart';
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

    unawaited(
      _controller.initialize(),
    );

    _controller.addListener(
      _onControllerChanged,
    );
  }

  // ============================================================
  // CONTROLLER UPDATE
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // SESSION DATA
  // ============================================================

  Map<String, dynamic> _sessionData =
      <String, dynamic>{};

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _controller.sessionStream,
      builder: (
        BuildContext context,
        AsyncSnapshot snapshot,
      ) {
        final Map<String, dynamic> data =
            snapshot.data?.data()
                    as Map<String, dynamic>? ??
                <String, dynamic>{};

        _sessionData = data;

        // --------------------------------------------------------
        // UPDATE CONTROLLER FROM FIRESTORE
        // --------------------------------------------------------

        if (data.isNotEmpty) {
          WidgetsBinding.instance
              .addPostFrameCallback(
            (_) {
              if (!mounted) {
                return;
              }

              _controller.updateFromSession(
                data,
              );
            },
          );
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        // ========================================================
        // COMPLETED
        // ========================================================

        if (status == 'completed' ||
            status == 'ended') {
          return LiveWalkCompletedScreen(
            dogName: widget.dogName,
            distanceKm:
                _controller.totalDistanceKm,
            steps: _controller.steps,
            onBack: () {
              Navigator.of(context).pop(true);
            },
          );
        }

        // ========================================================
        // WALK STARTED
        // ========================================================

        final bool walkStarted =
            _controller.walkStarted ||
                status == 'active' ||
                status == 'started';

        // ========================================================
        // START SLIDER
        // ========================================================

        final bool showStartPanel =
            !walkStarted &&
                !_controller.ending;

        // ========================================================
        // LIVE WALK SCREEN
        // ========================================================

        return Scaffold(
          backgroundColor:
              AppColors.cardBackground,

          // ======================================================
          // APP BAR
          // ======================================================

          appBar: LiveWalkAppBar(
            enabled:
                !_controller.ending,
            onSos: _openSos,
            onSupport: _openSupport,
          ),

          // ======================================================
          // BODY
          // ======================================================

          body: Stack(
            children: [
              // ==================================================
              // MAP
              // ==================================================

              Positioned.fill(
                child: LiveWalkMapLayer(
                  sessionData: data,
                  gpsReady:
                      _controller.gpsReady,
                ),
              ),

              // ==================================================
              // START PANEL
              //
              // Reach के बाद दिखाई देगा.
              //
              // GPS पहले से active रहेगा.
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
              // BOTTOM WALK INFORMATION
              //
              // Slider complete होने के बाद दिखाई देगा.
              // ==================================================

              if (walkStarted)
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
    } catch (e) {
      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // END WALK CONFIRMATION
  // ============================================================

  void _confirmEndWalk() {
    if (_controller.ending) {
      return;
    }

    if (!_controller.walkStarted) {
      _showError(
        'Start the walk before ending it.',
      );
      return;
    }

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
            'End Walk?',
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: const Text(
            'Are you sure you want to end this walk?',
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
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();

                unawaited(
                  _endWalk(),
                );
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.error,
                foregroundColor:
                    Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'End Walk',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // END WALK
  // ============================================================

  Future<void> _endWalk() async {
    try {
      await _controller.endWalk();

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showError(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
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
            color: AppColors.cardBackground,
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
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
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
                      Icons.support_agent_rounded,
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
          content: Text(message),
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
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
          duration:
              const Duration(seconds: 2),
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

    // IMPORTANT:
    //
    // Controller dispose होने पर भी GPS STOP नहीं किया जाता.
    //
    // GPS केवल successful endWalk() के बाद
    // controller के अंदर stop होता है.

    super.dispose();
  }
}
