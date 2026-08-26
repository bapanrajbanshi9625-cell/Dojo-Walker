import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ProfileSubmitButton2 extends StatelessWidget {
  const ProfileSubmitButton2({
    super.key,
    required this.onPressed,
    required this.saving,
  });

  final VoidCallback? onPressed;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: saving ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.green,
          disabledBackgroundColor:
              AppColors.green.withOpacity(.55),
          foregroundColor: AppColors.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
        ),
        child: saving
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.onPrimary,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'SUBMITTING...',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_rounded),
                  SizedBox(width: 9),
                  Text(
                    'SUBMIT FOR VERIFICATION',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
