import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class ActiveWalkStartPanel extends StatelessWidget {
  final bool enabled;
  final bool starting;
  final VoidCallback onStarted;

  const ActiveWalkStartPanel({
    super.key,
    required this.enabled,
    required this.starting,
    required this.onStarted,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = !enabled || starting;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.success.withValues(
            alpha: 0.20,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // READY HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: AppColors.buttonText,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              const Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'READY TO START',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.4,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'You have reached the owner.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ======================================================
          // START WALK BUTTON
          // ======================================================

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: disabled ? null : onStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                disabledBackgroundColor:
                    AppColors.border,
                disabledForegroundColor:
                    AppColors.textMuted,
                foregroundColor:
                    AppColors.buttonText,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(15),
                ),
              ),
              child: starting
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          AppColors.buttonText,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          size: 23,
                        ),
                        SizedBox(width: 7),
                        Text(
                          'START WALK',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
