// File:
// lib/screens/walker_home_screen.dart

import 'package:flutter/material.dart';

import '../features/walker_home/containers/walker_home_header.dart';
import '../features/walker_home/containers/welcome_container.dart';
import '../features/walker_home/containers/today_summary_container.dart';
import '../features/walker_home/containers/past_walks_container.dart';

import '../features/walker_home/screens/distance_details_screen.dart';
import '../features/walker_home/screens/duration_details_screen.dart';
import '../features/walker_home/screens/walk_details_screen.dart';
import '../features/walker_home/screens/past_walks_screen.dart';

class WalkerHomeScreen extends StatefulWidget {
  const WalkerHomeScreen({super.key});

  @override
  State<WalkerHomeScreen> createState() =>
      _WalkerHomeScreenState();
}

class _WalkerHomeScreenState extends State<WalkerHomeScreen> {
  // ============================================================
  // OPEN DETAILS SCREEN
  // ============================================================

  void _showDetails({
    required String title,
    required String description,
    required IconData icon,
  }) {
    final String normalizedTitle = title.toLowerCase().trim();

    Widget? screen;

    // ------------------------------------------------------------
    // DISTANCE
    // ------------------------------------------------------------

    if (normalizedTitle.contains('distance')) {
      screen = const DistanceDetailsScreen();
    }

    // ------------------------------------------------------------
    // DURATION
    // ------------------------------------------------------------

    else if (normalizedTitle.contains('duration') ||
        normalizedTitle.contains('time')) {
      screen = const DurationDetailsScreen();
    }

    // ------------------------------------------------------------
    // WALKS
    // ------------------------------------------------------------

    else if (normalizedTitle.contains('walk')) {
      screen = const WalkDetailsScreen();
    }

    // ------------------------------------------------------------
    // PAST WALKS
    // ------------------------------------------------------------

    else if (normalizedTitle.contains('past')) {
      screen = const PastWalksScreen();
    }

    // ------------------------------------------------------------
    // FALLBACK
    // ------------------------------------------------------------

    else {
      screen = const WalkDetailsScreen();
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen!,
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          const WalkerHomeHeader(),

          // ======================================================
          // HOME CONTENT
          // ======================================================

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                24,
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // WELCOME
                  // ==================================================

                  const WelcomeContainer(),

                  const SizedBox(height: 10),

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

                  const SizedBox(height: 14),

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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
