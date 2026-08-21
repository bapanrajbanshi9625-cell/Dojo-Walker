// File:
// lib/features/walks/widgets/insta_walk_container.dart

import 'package:flutter/material.dart';

import '../models/walk_request.dart';
import 'insta_walk_map_radar.dart';

class InstaWalkContainer extends StatelessWidget {
  // ============================================================
  // CALLBACK
  // ============================================================

  final VoidCallback? onSearchPressed;

  // ============================================================
  // SEARCH STATE
  // ============================================================

  final bool searching;
  final bool loading;

  // ============================================================
  // RADAR
  // ============================================================

  final AnimationController? radarAnimation;

  final bool dotVisible;
  final double dotX;
  final double dotY;

  // ============================================================
  // REQUESTS
  // ============================================================

  final List<WalkRequest> requests;

  // ============================================================
  // REQUEST LIST BUILDER
  // ============================================================

  final WidgetBuilder? requestListBuilder;

  const InstaWalkContainer({
    super.key,
    this.onSearchPressed,
    this.searching = false,
    this.loading = false,
    this.radarAnimation,
    this.dotVisible = false,
    this.dotX = 0,
    this.dotY = 0,
    this.requests = const [],
    this.requestListBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ========================================================
        // MAIN INSTA WALK CONTAINER
        // ========================================================

        Container(
          margin: const EdgeInsets.symmetric(
            horizontal: 18,
          ),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFFE45D32),
                Color(0xFFC84A24),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.08),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================

              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color:
                          Colors.white.withOpacity(.18),
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.flash_on_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insta Walk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Find a walk right now',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // ==================================================
              // NORMAL DESCRIPTION
              // ==================================================

              if (!searching)
                const Text(
                  'Search for available Insta Walk requests within 3.5 kilometre.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),

              // ==================================================
              // SEARCHING AREA
              // ==================================================

              if (searching) ...[
                const SizedBox(height: 2),

                // ----------------------------------------------
                // RADAR
                // ----------------------------------------------

                SizedBox(
                  width: double.infinity,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Existing radar widget
                      Positioned.fill(
                        child: InstaWalkMapRadar(
                          searching: searching,
                        ),
                      ),

                      // ----------------------------------------
                      // RADAR DOT
                      // ----------------------------------------

                      if (dotVisible)
                        Positioned(
                          left: 50 +
                              ((dotX + 1) / 2) *
                                  230,
                          top: 20 +
                              ((dotY + 1) / 2) *
                                  180,
                          child: _RadarDot(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ----------------------------------------------
                // SEARCH STATUS
                // ----------------------------------------------

                Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFF62E6A7),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Searching for nearby Insta Walk requests...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 15),

              // ==================================================
              // SEARCH / STOP BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton(
                  onPressed:
                      loading ? null : onSearchPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    disabledBackgroundColor:
                        Colors.white70,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      if (loading) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<
                                    Color>(
                              Color(0xFF238EAE),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'Searching...',
                          style: TextStyle(
                            color:
                                Color(0xFF238EAE),
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ] else ...[
                        Icon(
                          searching
                              ? Icons.stop_rounded
                              : Icons.search_rounded,
                          color:
                              const Color(0xFF238EAE),
                          size: 21,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          searching
                              ? 'Stop Insta Walk Search'
                              : 'Insta Walk Search',
                          style: const TextStyle(
                            color:
                                Color(0xFF238EAE),
                            fontWeight:
                                FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ========================================================
        // REQUEST LIST
        // ========================================================

        if (searching &&
            requests.isNotEmpty &&
            requestListBuilder != null) ...[
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: requestListBuilder!(context),
          ),
        ],
      ],
    );
  }
}

// ==================================================================
// RADAR DOT
// ==================================================================

class _RadarDot extends StatelessWidget {
  const _RadarDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xFF62E6A7),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF62E6A7)
                .withOpacity(.75),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}
