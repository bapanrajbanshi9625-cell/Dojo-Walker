import 'package:flutter/material.dart';

import '../../../core/theme/dojo_colors.dart';

class MyBoxCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool enabled;

  const MyBoxCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: DojoColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DojoColors.border,
              ),
            ),
            child: Row(
              children: [
                // =================================================
                // ICON
                // =================================================

                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: DojoColors.orangeLight,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: DojoColors.orange,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 12),

                // =================================================
                // TITLE + SUBTITLE
                // =================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DojoColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: DojoColors.textSecondary,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // =================================================
                // ARROW
                // =================================================

                const Icon(
                  Icons.chevron_right_rounded,
                  color: DojoColors.iconSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
