import 'package:flutter/material.dart';

import '../features/walker_home/containers/walker_home_header.dart';
import '../features/walker_home/containers/welcome_container.dart';
import '../features/walker_home/containers/today_summary_container.dart';
import '../features/walker_home/containers/live_location_container.dart';
import '../features/walker_home/containers/past_walks_container.dart';

import '../features/walker_home/services/walker_walk_service.dart';

import 'walker_home/walker_home_details_sheet.dart';

class WalkerHomeScreen extends StatefulWidget {
  const WalkerHomeScreen({super.key});

  @override
  State<WalkerHomeScreen> createState() =>
      _WalkerHomeScreenState();
}

class _WalkerHomeScreenState
    extends State<WalkerHomeScreen> {

  // ============================================================
  // ACTIVE WALK
  // ============================================================

  WalkerWalkData? _activeWalk;

  bool get _isWalkStarted =>
      _activeWalk != null;

  // ============================================================
  // SCAN OWNER QR
  // ============================================================

  Future<void> _openCameraScanner() async {
    final WalkerWalkData? walk =
        await WalkerWalkService.scanOwnerQr(
      context,
    );

    if (!mounted || walk == null) {
      return;
    }

    setState(() {
      _activeWalk = walk;
    });

    await _openLiveWalk();
  }

  // ============================================================
  // OPEN LIVE WALK
  // ============================================================

  Future<void> _openLiveWalk() async {
    final WalkerWalkData? walk =
        _activeWalk;

    if (walk == null) {
      return;
    }

    await WalkerWalkService.openLiveWalk(
      context,
      walk,
    );

    if (!mounted) {
      return;
    }

    _resetActiveWalk();
  }

  // ============================================================
  // OPEN EXISTING ACTIVE WALK
  // ============================================================

  Future<void> _openActiveWalk() async {
    if (_activeWalk == null) {
      return;
    }

    await _openLiveWalk();
  }

  // ============================================================
  // RESET
  // ============================================================

  void _resetActiveWalk() {
    if (!mounted) {
      return;
    }

    setState(() {
      _activeWalk = null;
    });
  }

  // ============================================================
  // SHOW DETAILS
  // ============================================================

  void _showDetails({
    required String title,
    required String description,
    required IconData icon,
  }) {
    WalkerHomeDetailsSheet.show(
      context,
      title: title,
      description: description,
      icon: icon,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F6F8),

      body: Stack(
        children: [
          // ======================================================
          // MAIN CONTENT
          // ======================================================

          Column(
            children: [
              // HEADER

              const WalkerHomeHeader(),

              // CONTENT

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.fromLTRB(
                    16,
                    14,
                    16,
                    115,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      // ==================================================
                      // WELCOME
                      // ==================================================

                      const WelcomeContainer(),

                      const SizedBox(height: 18),

                      // ==================================================
                      // TODAY SUMMARY
                      // ==================================================

                      TodaySummaryContainer(
                        onDetails: ({
                          required String title,
                          required String description,
                          required IconData icon,
                        }) {
                          _showDetails(
                            title: title,
                            description: description,
                            icon: icon,
                          );
                        },
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // LIVE LOCATION
                      // ==================================================

                      LiveLocationContainer(
                        isWalkStarted:
                            _isWalkStarted,
                      ),

                      const SizedBox(height: 18),

                      // ==================================================
                      // PAST WALKS
                      // ==================================================

                      PastWalksContainer(
                        onDetails: ({
                          required String title,
                          required String description,
                          required IconData icon,
                        }) {
                          _showDetails(
                            title: title,
                            description: description,
                            icon: icon,
                          );
                        },
                      ),

                      // ==================================================
                      // ACTIVE WALK
                      // ==================================================

                      if (_isWalkStarted) ...[
                        const SizedBox(height: 14),

                        ActiveWalkButton(
                          ownerName:
                              _activeWalk!
                                  .ownerName,
                          onTap:
                              _openActiveWalk,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ======================================================
          // FLOATING QR
          // ======================================================

          if (!_isWalkStarted)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 220,
                  height: 60,
                  child: FloatingQrButton(
                    onTap:
                        _openCameraScanner,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
