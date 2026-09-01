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
          width: 5,
          height: 28,
          decoration: BoxDecoration(
            color: DojoColors.orange,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(width: 10),

        // ========================================================
        // SECTION TITLE
        // ========================================================

        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: DojoColors.dark,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        // ========================================================
        // LIVE BADGE
        // ========================================================

        if (live)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: DojoColors.greenLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.circle,
                  size: 7,
                  color: DojoColors.green,
                ),
                const SizedBox(width: 5),
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: DojoColors.green,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
