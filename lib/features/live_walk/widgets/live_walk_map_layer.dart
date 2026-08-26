import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
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
      children: [
        // ========================================================
        // MAP
        // ========================================================

        Positioned.fill(
          child: LiveWalkMap(
            sessionData: sessionData,
          ),
        ),

        // ========================================================
        // LIVE BADGE
        // ========================================================

        Positioned(
          top: 14,
          left: 16,
          child: _liveBadge(),
        ),

        // ========================================================
        // GPS BADGE
        // ========================================================

        Positioned(
          top: 14,
          right: 16,
          child: _gpsBadge(),
        ),
      ],
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
    final Color color = gpsReady
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
}
