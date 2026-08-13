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

        const SizedBox(height: 8),

        Container(
          height: 220,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: const Color(0xFFE7EEF5),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFFFD3C4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: WalkerMapPainter(),
              ),

              const Positioned(
                top: 10,
                left: 10,
                child: LiveLocationBadge(),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.10),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFFFF4B16),
                    size: 20,
                  ),
                ),
              ),

              const Positioned(
                left: 160,
                top: 90,
                child: WalkerLocationMarker(),
              ),

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
