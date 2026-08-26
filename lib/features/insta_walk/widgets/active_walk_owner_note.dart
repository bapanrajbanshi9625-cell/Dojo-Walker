import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkOwnerNote extends StatelessWidget {
  const ActiveWalkOwnerNote({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(.06),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(.12),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                color: AppColors.primary,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                'OWNER NOTE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'No additional note provided by owner.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
