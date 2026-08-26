import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkTopBar extends StatelessWidget {
  final String status;
  final VoidCallback onBack;

  const ActiveWalkTopBar({
    super.key,
    required this.status,
    required this.onBack,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final String cleanStatus =
        status.trim().toLowerCase();

    final bool active =
        cleanStatus == 'active';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          0,
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            _circleButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: onBack,
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 9,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius:
                    BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.overlay.withOpacity(.15),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: active
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    active
                        ? 'LIVE WALK'
                        : cleanStatus.isEmpty
                            ? 'INSTA WALK'
                            : cleanStatus.toUpperCase(),
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.cardBackground,
      elevation: 5,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder:
            const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: AppColors.secondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
