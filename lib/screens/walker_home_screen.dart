import 'package:flutter/material.dart';

import '../features/walker_home/containers/walker_home_header.dart';
import '../features/walker_home/containers/welcome_container.dart';
import '../features/walker_home/containers/today_summary_container.dart';
import '../features/walker_home/containers/past_walks_container.dart';

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
      backgroundColor: const Color(0xFFF5F6F8),
      body: Column(
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          const WalkerHomeHeader(),

          // ======================================================
          // CONTENT
          // ======================================================

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
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
