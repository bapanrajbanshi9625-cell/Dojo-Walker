import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker.dart';

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
            color: DojoWalkerColors.textPrimary,
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
            color: DojoWalkerColors.background.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: DojoWalkerColors.border.withValues(alpha: 0.70),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: DojoWalkerColors.textPrimary,
                size: 19,
              ),
              const SizedBox(width: 7),
              Text(
                'Search range: 3.5 kilometre',
                style: TextStyle(
                  color: DojoWalkerColors.textPrimary,
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
