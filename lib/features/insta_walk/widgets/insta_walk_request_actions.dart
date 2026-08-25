// File:
// lib/features/insta_walk/widgets/insta_walk_request_actions.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class InstaWalkRequestActions extends StatelessWidget {
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const InstaWalkRequestActions({
    super.key,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ======================================================
        // REJECT
        // ======================================================

        Expanded(
          child: SizedBox(
            height: 43,
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: AppColors.error.withOpacity(.25),
                ),
                backgroundColor: AppColors.errorSoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Reject',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 9),

        // ======================================================
        // ACCEPT
        // ======================================================

        Expanded(
          flex: 2,
          child: SizedBox(
            height: 43,
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.buttonText,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Accept Walk',
                    style: TextStyle(
                      color: AppColors.buttonText,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
