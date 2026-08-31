import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkStatCard extends StatelessWidget {
  final String value;
  final String title;

  const ActiveWalkStatCard({
    super.key,
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }
}
