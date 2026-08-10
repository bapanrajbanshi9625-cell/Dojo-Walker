// File location: lib/features/live_walk/widgets/live_walk_activity_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart'; // Verified import path for AppColors

class LiveWalkActivityCard extends StatelessWidget {
  const LiveWalkActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(80), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.directions_walk, color: AppColors.primary, size: 28),
              SizedBox(width: 10),
              Text(
                "Live Walk Progress",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.black87),
              ),
            ],
          ),
          const Divider(height: 30, thickness: 1, color: Colors.black12),
          const Text("Duration", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          const Text(
            "00:45:12",
            style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: AppColors.primary, letterSpacing: -1),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat("2.4 km", "Distance"),
              Container(height: 30, width: 1, color: AppColors.primary.withAlpha(50)),
              _buildStat("3,200", "Steps"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      );
}
