import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileProgressHeader extends StatelessWidget {
  const ProfileProgressHeader({
    super.key,
    required this.currentPage,
    required this.aadhaarVerified,
  });

  final int currentPage;
  final bool aadhaarVerified;

  static const Color green = Color(0xFF16A34A);
  static const Color muted = Color(0xFF7A8289);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE3E7EA),
        ),
      ),
      child: Row(
        children: [
          _circle(
            number: '1',
            active: currentPage == 0,
            completed: currentPage > 0,
          ),
          Expanded(
            child: Container(
              height: 3,
              color: currentPage > 0
                  ? green
                  : const Color(0xFFE3E7EA),
            ),
          ),
          _circle(
            number: '2',
            active: currentPage == 1,
            completed: aadhaarVerified,
          ),
        ],
      ),
    );
  }

  Widget _circle({
    required String number,
    required bool active,
    required bool completed,
  }) {
    final bool selected = active || completed;

    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: selected
            ? (completed ? green : AppColors.primary)
            : const Color(0xFFF0F2F4),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: completed
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 19,
            )
          : Text(
              number,
              style: TextStyle(
                color: selected ? Colors.white : muted,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
  }
}
