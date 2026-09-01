import 'package:flutter/material.dart';

import '../../../../core/theme/dojo_walker_colors.dart';

class PastWalkCard extends StatelessWidget {
  final String id;
  final String time;
  final String details;
  final VoidCallback onTap;

  const PastWalkCard({
    super.key,
    required this.id,
    required this.time,
    required this.details,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: DojoColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: DojoColors.border,
            ),
          ),
          child: Row(
            children: [
              // ==================================================
              // DOG ICON
              // ==================================================

              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: DojoColors.greenLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.pets_rounded,
                  color: DojoColors.green,
                  size: 28,
                ),
              ),

              const SizedBox(width: 13),

              // ==================================================
              // WALK INFORMATION
              // ==================================================

              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$id • $time',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DojoColors.dark,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DojoColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==================================================
              // DONE BADGE
              // ==================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: DojoColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'DONE',
                  style: TextStyle(
                    color: DojoColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // ==================================================
              // ARROW
              // ==================================================

              Icon(
                Icons.chevron_right_rounded,
                color: DojoColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
