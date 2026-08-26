import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/live_walk_controller.dart';
import '../widgets/live_walk_bottom_sheet.dart';
import '../widgets/live_walk_completed_view.dart';
import '../widgets/live_walk_map.dart';
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

  Stream<DocumentSnapshot<Map<String, dynamic>>>
      get _sessionStream => _controller.sessionStream;

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
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            20,
            14,
            20,
            25,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius:
                        BorderRadius.circular(10),
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
                    color: AppColors.secondary,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Need help during this walk?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();

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
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return const LiveWalkSosSheet();
      },
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (
        BuildContext context,
        Widget? child,
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

            _controller.updateFromSession(
              data,
            );

            final String status =
                data['status']
                        ?.toString()
                        .trim()
                        .toLowerCase() ??
                    'live';

            // ==================================================
            // COMPLETED
            // ==================================================

            if (status == 'completed' ||
                status == 'ended') {
              return LiveWalkCompletedView(
                dogName: widget.dogName,
                distanceKm:
                    _controller.totalDistanceKm,
                steps: _controller.steps,
                onBack: () {
                  Navigator.of(context).pop(true);
                },
              );
            }

            // ==================================================
            // WALK STARTED
            // ==================================================

            final bool walkStarted =
                _controller.walkStarted ||
                    status == 'active' ||
                    status == 'started';

            // ==================================================
            // LIVE SCREEN
            // ==================================================

            return Scaffold(
              backgroundColor:
                  AppColors.cardBackground,

              // ================================================
              // APP BAR
              // ================================================

              appBar: AppBar(
                backgroundColor:
                    AppColors.primary,
                surfaceTintColor:
                    AppColors.primary,
                elevation: 0,
                centerTitle: true,
                automaticallyImplyLeading: false,
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
                      Icons
                          .support_agent_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),

              // ================================================
              // BODY
              // ================================================

              body: Stack(
                children: [
                  // --------------------------------------------
                  // MAP
                  // --------------------------------------------

                  Positioned.fill(
                    child: LiveWalkMap(
                      sessionData: data,
                    ),
                  ),

                  // --------------------------------------------
                  // LIVE BADGE
                  // --------------------------------------------

                  Positioned(
                    top: 14,
                    left: 16,
                    child: _liveBadge(),
                  ),

                  // --------------------------------------------
                  // GPS BADGE
                  // --------------------------------------------

                  Positioned(
                    top: 14,
                    right: 16,
                    child: _gpsBadge(),
                  ),

                  // --------------------------------------------
                  // START PANEL
                  //
                  // Reach के बाद दिखाई देगा.
                  // GPS पहले से चलता रहेगा.
                  // --------------------------------------------

                  if (!walkStarted &&
                      !_controller.ending)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 20,
                      child: SafeArea(
                        child: LiveWalkStartPanel(
                          starting:
                              _controller.startingWalk,
                          onStarted:
                              _controller.startWalk,
                        ),
                      ),
                    ),

                  // --------------------------------------------
                  // WALK BOTTOM SHEET
                  //
                  // Start के बाद दिखाई देगा.
                  // --------------------------------------------

                  if (walkStarted)
                    Align(
                      alignment:
                          Alignment.bottomCenter,
                      child: LiveWalkBottomSheet(
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
                        onEndWalk: () async {
                          try {
                            await _controller.endWalk();

                            if (!mounted) {
                              return;
                            }

                            Navigator.of(
                              context,
                            ).pop(true);
                          } catch (e) {
                            _showError(
                              e.toString()
                                  .replaceFirst(
                                'Exception: ',
                                '',
                              ),
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // LIVE BADGE
  // ============================================================

  Widget _liveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: AppColors.success,
            size: 9,
          ),
          SizedBox(width: 7),
          Text(
            'LIVE',
            style: TextStyle(
              color: AppColors.secondary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GPS BADGE
  // ============================================================

  Widget _gpsBadge() {
    final bool gpsReady =
        _controller.gpsReady;

    final Color color =
        gpsReady
            ? AppColors.success
            : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 5),
          Text(
            gpsReady ? 'GPS' : 'GPS...',
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
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
    // IMPORTANT:
    //
    // यहां GPS STOP नहीं होगा.
    //
    // Central GPS Active Insta Walk से लेकर
    // Walk Completed तक चलता रहेगा.
    //
    // Controller केवल अपनी UI/session listeners साफ करेगा.

    _controller.dispose();

    super.dispose();
  }
}
