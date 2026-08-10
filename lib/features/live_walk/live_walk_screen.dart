// File location: lib/features/live_walk/live_walk_screen.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/map_view.dart';

class LiveWalkScreen extends StatelessWidget {
  final String? scannedOwnerData;
  final VoidCallback onMinimize;
  final VoidCallback onEndWalk;

  const LiveWalkScreen({
    super.key,
    required this.scannedOwnerData,
    required this.onMinimize,
    required this.onEndWalk,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Active Walk',
          style: TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 28),
            onPressed: onMinimize,
            tooltip: 'Minimize Live Walk',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ActivityCard(),
            const SizedBox(height: 16),
            const MapViewWidget(),
            if (scannedOwnerData != null) ...[
              const SizedBox(height: 16),
              Text(
                "Connected to Owner:\n$scannedOwnerData",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onEndWalk,
                child: const Text(
                  'End Walk',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
