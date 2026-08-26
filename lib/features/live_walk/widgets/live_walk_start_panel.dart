import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'live_walk_start_slider.dart';

class LiveWalkStartPanel extends StatelessWidget {
  const LiveWalkStartPanel({
    super.key,
    required this.enabled,
    required this.starting,
    required this.onStarted,
  });

  final bool enabled;
  final bool starting;
  final VoidCallback onStarted;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 20,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ====================================================
            // GPS ACTIVE INFO
            // ====================================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: AppColors.success,
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'GPS is active',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 9),

            // ====================================================
            // START SLIDER
            // ====================================================

            LiveWalkStartSlider(
              enabled: enabled && !starting,
              onStarted: onStarted,
            ),

            // ====================================================
            // STARTING LOADER
            // ====================================================

            if (starting)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
