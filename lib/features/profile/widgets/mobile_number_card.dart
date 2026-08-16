import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class MobileNumberCard
    extends StatelessWidget {
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
      margin:
          const EdgeInsets.only(bottom: 12),
      padding:
          const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color:
            AppColors.cardBackground,
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color:
                  AppColors.secondary
                      .withOpacity(0.09),
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.phone_outlined,
              color:
                  AppColors.secondary,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mobile Number',
                  style:
                      TextStyle(
                    fontSize: 12,
                    color:
                        AppColors.textGrey,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  phone,
                  style:
                      const TextStyle(
                    fontSize: 15,
                    color:
                        AppColors.textDark,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          Material(
            color: AppColors.secondary
                .withOpacity(0.09),
            borderRadius:
                BorderRadius.circular(9),
            child: InkWell(
              onTap: onEdit,
              borderRadius:
                  BorderRadius.circular(9),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.edit_outlined,
                  color:
                      AppColors.secondary,
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
