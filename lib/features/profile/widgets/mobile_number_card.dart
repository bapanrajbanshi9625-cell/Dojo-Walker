// File:
// lib/features/profile/widgets/mobile_number_card.dart

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker.dart';

class MobileNumberCard extends StatelessWidget {
  final String phone;
  final VoidCallback onEdit;

  const MobileNumberCard({
    super.key,
    required this.phone,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: DojoWalkerColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DojoWalkerColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: DojoWalkerColors.primary.withValues(
                alpha: 0.09,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_outlined,
              color: DojoWalkerColors.primary,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mobile Number',
                  style: TextStyle(
                    fontSize: 12,
                    color: DojoWalkerColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  phone,
                  style: const TextStyle(
                    fontSize: 15,
                    color: DojoWalkerColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Material(
            color: DojoWalkerColors.primary.withValues(
              alpha: 0.09,
            ),
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(9),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.edit_outlined,
                  color: DojoWalkerColors.primary,
                  size: 19,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
