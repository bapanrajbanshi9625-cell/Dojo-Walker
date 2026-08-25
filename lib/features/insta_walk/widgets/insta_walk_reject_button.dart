import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class InstaWalkRejectButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const InstaWalkRejectButton({
    super.key,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SizedBox(
        height: 43,
        child: OutlinedButton(
          onPressed: loading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.error,
            disabledForegroundColor:
                AppColors.error.withOpacity(.45),
            side: BorderSide(
              color: AppColors.error.withOpacity(.25),
            ),
            backgroundColor: AppColors.errorSoft,
            disabledBackgroundColor:
                AppColors.errorSoft.withOpacity(.50),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.error,
                  ),
                )
              : Text(
                  'Reject',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
        ),
      ),
    );
  }
}
