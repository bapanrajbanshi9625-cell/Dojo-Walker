import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker.dart';
import 'live_walk_map.dart';

class LiveWalkMapLayer extends StatelessWidget {
  const LiveWalkMapLayer({
    super.key,
    required this.sessionData,
    required this.gpsReady,
  });

  final Map<String, dynamic> sessionData;
  final bool gpsReady;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // ========================================================
        // LIVE MAP
        // ========================================================

        Positioned.fill(
          child: LiveWalkMap(
            sessionData: sessionData,
          ),
        ),

        // ========================================================
        // STATUS OVERLAY
        // ========================================================

        Positioned(
          top: 14,
          left: 14,
          right: 14,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _StatusBadge(
                icon: Icons.circle,
                label: 'LIVE',
                iconColor: DojoWalkerColors.success,
                compactIcon: true,
              ),

              const Spacer(),

              _StatusBadge(
                icon: Icons.my_location_rounded,
                label: gpsReady ? 'GPS READY' : 'GPS CONNECTING',
                iconColor: gpsReady
                    ? DojoWalkerColors.success
                    : DojoWalkerColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================================================================
// STATUS BADGE
// ==================================================================

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.icon,
    required this.label,
    required this.iconColor,
    this.compactIcon = false,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final bool compactIcon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DojoWalkerColors.card.withValues(
          alpha: 0.96,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DojoWalkerColors.white.withValues(
            alpha: 0.75,
          ),
          width: 1,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 11,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: compactIcon ? 8 : 24,
              height: compactIcon ? 8 : 24,
              decoration: compactIcon
                  ? BoxDecoration(
                      color: iconColor,
                      shape: BoxShape.circle,
                    )
                  : BoxDecoration(
                      color: iconColor.withValues(
                        alpha: 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
              child: compactIcon
                  ? null
                  : Icon(
                      icon,
                      color: iconColor,
                      size: 14,
                    ),
            ),

            SizedBox(
              width: compactIcon ? 7 : 7,
            ),

            Text(
              label,
              style: TextStyle(
                color: DojoWalkerColors.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
