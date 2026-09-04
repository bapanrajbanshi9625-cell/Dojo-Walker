import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileSummaryCard2 extends StatelessWidget {
  const ProfileSummaryCard2({
    super.key,
    required this.name,
    required this.dateOfBirth,
    required this.gender,
  });

  final String name;
  final DateTime dateOfBirth;
  final String gender;

  String get formattedDateOfBirth {
    return '${dateOfBirth.day.toString().padLeft(2, '0')}/'
        '${dateOfBirth.month.toString().padLeft(2, '0')}/'
        '${dateOfBirth.year}';
  }

  Widget _summaryRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.person_rounded,
                color: AppColors.green,
              ),
              SizedBox(width: 9),
              Text(
                'Walker Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          _summaryRow(
            'Full Name',
            name,
          ),

          _summaryRow(
            'Date Of Birth',
            formattedDateOfBirth,
          ),

          _summaryRow(
            'Gender',
            gender,
          ),
        ],
      ),
    );
  }
}
