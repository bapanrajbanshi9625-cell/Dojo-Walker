import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class DateOfBirthField extends StatelessWidget {
  final DateTime? dateOfBirth;
  final VoidCallback? onTap;

  const DateOfBirthField({
    super.key,
    required this.dateOfBirth,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final String day =
        date.day.toString().padLeft(2, '0');

    final String month =
        date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date of Birth',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textGrey,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: InputDecorator(
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFFD5D9DE),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              suffixIcon: const Icon(
                Icons.calendar_month,
              ),
            ),
            child: Text(
              dateOfBirth == null
                  ? 'Select date of birth'
                  : _formatDate(dateOfBirth!),
              style: TextStyle(
                color: dateOfBirth == null
                    ? Colors.grey
                    : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
