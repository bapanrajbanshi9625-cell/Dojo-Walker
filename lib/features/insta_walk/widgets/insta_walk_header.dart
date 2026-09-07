import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker.dart';

class InstaWalkHeader extends StatelessWidget {
  final bool searching;

  const InstaWalkHeader({
    super.key,
    required this.searching,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DojoWalkerColors.textPrimary,
            DojoWalkerColors.dark,
            DojoWalkerColors.textPrimary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DojoWalkerColors.border.withValues(alpha: 0.13),
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkerColors.black.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // ========================================================
          // INSTA WALK ICON
          // ========================================================

          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: DojoWalkerColors.primary,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              Icons.flash_on_rounded,
              color: DojoWalkerColors.white,
              size: 30,
            ),
          ),

          const SizedBox(width: 13),

          // ========================================================
          // TITLE
          // ========================================================

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insta Walk',
                  style: TextStyle(
                    color: DojoWalkerColors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Find a walk request nearby',
                  style: TextStyle(
                    color: DojoWalkerColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // ========================================================
          // LIVE STATUS
          // ========================================================

          if (searching)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: DojoWalkerColors.success.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: DojoWalkerColors.success.withValues(alpha: 0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.circle,
                    color: DojoWalkerColors.success,
                    size: 8,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: DojoWalkerColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
