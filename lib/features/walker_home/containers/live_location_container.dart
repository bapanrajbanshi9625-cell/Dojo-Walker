import 'package:flutter/material.dart';

import '../widgets/section_title.dart';
import '../widgets/map_painter.dart';
import '../widgets/location_marker.dart';
import '../widgets/live_location_badge.dart';

class LiveLocationContainer extends StatelessWidget {
  final bool isWalkStarted;

  const LiveLocationContainer({
    super.key,
    this.isWalkStarted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const WalkerSectionTitle(
          title: 'Live Location',
          live: true,
        ),

        const SizedBox(height: 12),

        Container(
          height: 330,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFE7EEF5),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: const Color(0xFFFFD3C4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.07),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: WalkerMapPainter(),
              ),

              // ==================================================
              // LIVE LOCATION
              // ==================================================

              const Positioned(
                top: 14,
                left: 14,
                child: LiveLocationBadge(),
              ),

              // ==================================================
              // MY LOCATION
              // ==================================================

              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.13),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFFFF4B16),
                    size: 23,
                  ),
                ),
              ),

              // ==================================================
              // LOCATION MARKER
              // ==================================================

              const Positioned(
                left: 160,
                top: 135,
                child: WalkerLocationMarker(),
              ),

              // ==================================================
              // WALK NOT STARTED OVERLAY
              // ==================================================

              if (!isWalkStarted)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(.08),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
