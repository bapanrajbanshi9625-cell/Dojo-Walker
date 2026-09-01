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
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: DojoColors.surface,
            borderRadius: BorderRadius.circular(16),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DojoColors.greenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pets_rounded,
                  color: DojoColors.green,
                  size: 22,
                ),
              ),

              const SizedBox(width: 10),

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
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.1,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      details,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: DojoColors.textSecondary,
                        fontSize: 11,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 6),

              // ==================================================
              // DONE BADGE
              // ==================================================

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 7,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: DojoColors.greenLight,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'DONE',
                  style: TextStyle(
                    color: DojoColors.green,
                    fontWeight: FontWeight.w800,
                    fontSize: 9,
                  ),
                ),
              ),

              const SizedBox(width: 3),

              // ==================================================
              // ARROW
              // ==================================================

              const Icon(
                Icons.chevron_right_rounded,
                color: DojoColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
