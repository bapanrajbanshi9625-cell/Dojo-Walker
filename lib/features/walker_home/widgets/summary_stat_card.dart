// File:
// lib/features/walker_home/widgets/summary_stat_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class SummaryStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color background;
  final Color iconColor;
  final VoidCallback onTap;

  const SummaryStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.background,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 104,
          padding: const EdgeInsets.fromLTRB(
            8,
            9,
            7,
            8,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // ICON
              // ==================================================

              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),

              const Spacer(),

              // ==================================================
              // TITLE
              // ==================================================

              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10.5,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 3),

              // ==================================================
              // VALUE
              // ==================================================

              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
