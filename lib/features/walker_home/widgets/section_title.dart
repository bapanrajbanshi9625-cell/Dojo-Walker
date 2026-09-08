import 'package:flutter/material.dart';

import '../../../../core/theme/dojo_walker_colors.dart';

class WalkerSectionTitle extends StatelessWidget {
  final String title;
  final bool live;

  const WalkerSectionTitle({
    super.key,
    required this.title,
    this.live = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ========================================================
        // ORANGE ACCENT
        // ========================================================

        Container(
          width: 4,
          height: 21,
          decoration: BoxDecoration(
            color: DojoWalkerColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
        ),

        const SizedBox(width: 8),

        // ========================================================
        // SECTION TITLE
        // =======================================================

        Expanded(
  child: Text(
    title,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: const TextStyle(
      color: DojoWalkerColors.textPrimary,
      fontSize: 18,
      height: 1.15,
      fontWeight: FontWeight.w700,
    ),
  ),
),

        // ========================================================
        // LIVE BADGE
        // ========================================================

        if (live)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: DojoWalkerColors.successLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 6,
                  color: DojoWalkerColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: DojoWalkerColors.success,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
