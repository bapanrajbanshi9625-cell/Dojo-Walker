// File:
// lib/features/insta_walk/widgets/insta_walk_accept_button.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class InstaWalkAcceptButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const InstaWalkAcceptButton({
    super.key,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: SizedBox(
        height: 43,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.buttonPrimary,
            foregroundColor: AppColors.buttonText,
            disabledBackgroundColor:
                AppColors.buttonPrimary.withOpacity(.50),
            disabledForegroundColor:
                AppColors.buttonText.withOpacity(.70),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.buttonText,
                  ),
                )
              : Row(
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
    );
  }
}
