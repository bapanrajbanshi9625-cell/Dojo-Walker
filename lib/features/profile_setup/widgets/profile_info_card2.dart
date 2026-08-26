import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileInfoCard2 extends StatelessWidget {
  const ProfileInfoCard2({
    super.key,
    this.title = 'Verification Information',
    this.message =
        'आपकी जानकारी DOJO Platform verification के लिए भेजी जाएगी। Profile पूरा होने के बाद Admin approval तक Walker account pending रहेगा।',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.blue.withOpacity(.06),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.blue,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11.5,
                    height: 1.5,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
