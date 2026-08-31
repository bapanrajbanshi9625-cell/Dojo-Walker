import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkLiveStatus extends StatelessWidget {
  final bool hasLocation;

  const ActiveWalkLiveStatus({
    super.key,
    required this.hasLocation,
  });

  @override
  Widget build(BuildContext context) {
    final Color statusColor = hasLocation
        ? AppColors.success
        : AppColors.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.success.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.navigation_rounded,
            color: statusColor,
            size: 18,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasLocation
                      ? 'Live location active'
                      : 'Waiting for live location',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  hasLocation
                      ? 'Walker location is updating in real time'
                      : 'GPS location will appear here',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
