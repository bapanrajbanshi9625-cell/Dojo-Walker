import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class InstaWalkInfo extends StatelessWidget {
  const InstaWalkInfo({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Search for available Insta Walk requests within '
          '3.5 kilometre of your service area.',
          style: TextStyle(
            color: AppColors.textDark,
            fontSize: 13,
            height: 1.45,
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.52),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.border.withOpacity(0.70),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: AppColors.textDark,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                'Search range: 3.5 kilometre',
                style: TextStyle(
                  color: AppColors.textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
