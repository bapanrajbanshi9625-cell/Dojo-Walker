// File:
// lib/features/walks/widgets/insta_walk_container.dart

import 'package:flutter/material.dart';

import '../../walks/models/walk_request.dart';
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

  // ============================================================
  // COLORS
  // ============================================================

  static const Color _orange = Color(0xFFFF6B35);
  static const Color _orangeDark = Color(0xFFE94F25);

  static const Color _navy = Color(0xFF101820);
  static const Color _navyLight = Color(0xFF18232D);

  static const Color _green = Color(0xFF62E6A7);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ========================================================
        // MAIN INSTA WALK CONTAINER
        // ========================================================

        Container(
          margin: const EdgeInsets.symmetric(horizontal: 18),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                _navy,
                _navyLight,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _orange.withOpacity(0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.14),
                blurRadius: 22,
                offset: const Offset(0, 9),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                      gradient: const LinearGradient(
                        colors: [
                          _orange,
                          _orangeDark,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 27,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insta Walk',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Find a walk right now',
                          style: TextStyle(
                            color: Color(0xFFB7C1C9),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ==================================================
                  // RANGE CHIP
                  // ==================================================

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.near_me_rounded,
                          color: _orange,
                          size: 14,
                        ),
                        SizedBox(width: 5),
                        Text(
                          '3.5 km',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ==================================================
              // IDLE STATE
              // ==================================================

              if (!searching) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.055),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_searching_rounded,
                        color: _orange,
                        size: 21,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Search for available Insta Walk requests near your current location.',
                          style: TextStyle(
                            color: Color(0xFFDCE3E8),
                            fontSize: 12.5,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // ==================================================
              // SEARCHING STATE
              // ==================================================

              if (searching) ...[
                // ----------------------------------------------
                // LIVE LOCATION HEADER
                // ----------------------------------------------

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: _green.withOpacity(0.14),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: _green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Searching around your current location',
                          style: TextStyle(
                            color: Color(0xFFDDF8EC),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.gps_fixed_rounded,
                        color: _green,
                        size: 16,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // ----------------------------------------------
                // RADAR / MAP AREA
                // ----------------------------------------------

                ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Container(
                    width: double.infinity,
                    height: 220,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B131A),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: InstaWalkMapRadar(
                            searching: searching,
                          ),
                        ),

                        // ----------------------------------------
                        // CENTER LOCATION MARKER
                        // ----------------------------------------

                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: _orange,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _orange.withOpacity(0.55),
                                blurRadius: 14,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                        ),

                        // ----------------------------------------
                        // RADAR DOT
                        // ----------------------------------------

                        if (dotVisible)
                          Positioned(
                            left: 50 + ((dotX + 1) / 2) * 230,
                            top: 20 + ((dotY + 1) / 2) * 180,
                            child: const _RadarDot(),
                          ),

                        // ----------------------------------------
                        // RANGE LABEL
                        // ----------------------------------------

                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _navy.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.radar_rounded,
                                  color: _green,
                                  size: 14,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  '3.5 km',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // ----------------------------------------
                        // LOCATION LABEL
                        // ----------------------------------------

                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _navy.withOpacity(0.88),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.my_location_rounded,
                                  color: _orange,
                                  size: 13,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'Your location',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ----------------------------------------------
                // SEARCH STATUS
                // ----------------------------------------------

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.045),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 9,
                        height: 9,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Searching for nearby Insta Walk requests...',
                          style: TextStyle(
                            color: Color(0xFFDCE3E8),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 15),

              // ==================================================
              // SEARCH / STOP BUTTON
              // ==================================================

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: loading ? null : onSearchPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        searching ? const Color(0xFF222C34) : _orange,
                    disabledBackgroundColor:
                        searching ? const Color(0xFF222C34) : _orangeDark,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(
                        color: searching
                            ? Colors.white.withOpacity(0.08)
                            : Colors.transparent,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ==================================================
                      // LOADING
                      // ==================================================

                      if (loading) ...[
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        const Text(
                          'Searching...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ]

                      // ==================================================
                      // NORMAL / SEARCHING
                      // ==================================================

                      else ...[
                        Icon(
                          searching
                              ? Icons.stop_circle_outlined
                              : Icons.flash_on_rounded,
                          color:
                              searching ? _orange : Colors.white,
                          size: 21,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          searching
                              ? 'Stop Insta Walk Search'
                              : 'Start Insta Walk Search',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
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
            padding: const EdgeInsets.symmetric(horizontal: 18),
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
        border: Border.all(
          color: Colors.white,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF62E6A7).withOpacity(0.70),
            blurRadius: 12,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }
}
