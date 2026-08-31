// File:
// lib/features/live_walk/widgets/live_walk_completed_screen.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class LiveWalkCompletedScreen extends StatelessWidget {
  const LiveWalkCompletedScreen({
    super.key,
    required this.dogName,
    required this.distanceKm,
    required this.steps,
    required this.onBack,
  });

  final String dogName;
  final double distanceKm;
  final int steps;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final String cleanDogName =
        dogName.trim().isEmpty ? 'Dog' : dogName.trim();

    final double safeDistance =
        distanceKm < 0 ? 0 : distanceKm;

    final int safeSteps =
        steps < 0 ? 0 : steps;

    return Scaffold(
      backgroundColor: AppColors.background,

      // ========================================================
      // APP BAR
      // ========================================================

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'WALK COMPLETED',
          style: TextStyle(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ==================================================
                // SUCCESS ICON
                // ==================================================

                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.success,
                    size: 80,
                  ),
                ),

                const SizedBox(height: 20),

                // ==================================================
                // TITLE
                // ==================================================

                const Text(
                  'Walk Completed',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                // ==================================================
                // DOG
                // ==================================================

                Text(
                  '$cleanDogName\'s walk is complete.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================================
                // STATS
                // ==================================================

                Row(
                  children: [
                    Expanded(
                      child: _stat(
                        '${safeDistance.toStringAsFixed(2)} km',
                        'Distance',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _stat(
                        '$safeSteps',
                        'Steps',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // ==================================================
                // BACK BUTTON
                // ==================================================

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: onBack,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to Walker Home',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _stat(
    String value,
    String title,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
