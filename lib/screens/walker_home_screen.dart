// File location: lib/screens/walker_home_screen.dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/activity_card.dart'; // Today's Activity ki alag file
import '../widgets/map_view.dart';     // Real Map ki alag file
import 'qr_scanner_screen.dart';

class WalkerHomeScreen extends StatefulWidget {
  const WalkerHomeScreen({super.key});

  @override
  State<WalkerHomeScreen> createState() => _WalkerHomeScreenState();
}

class _WalkerHomeScreenState extends State<WalkerHomeScreen> {
  bool _isWalkStarted = false;
  String? _scannedOwnerData;

  Future<void> _openCameraScanner(BuildContext context) async {
    final String? scannedData = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (scannedData != null && scannedData.isNotEmpty) {
      setState(() {
        _isWalkStarted = true;
        _scannedOwnerData = scannedData;
      });

      debugPrint("Owner QR Data Received: $_scannedOwnerData");
    }
  }

  // Method to navigate to Live Walk Screen when blue bar is clicked
  void _navigateToLiveWalk() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveWalkDetailsScreen(
          ownerData: _scannedOwnerData ?? '',
          onWalkCompleted: () {
            setState(() {
              _isWalkStarted = false;
              _scannedOwnerData = null;
            });
            Navigator.pop(context); // Return back to Home Screen
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          _isWalkStarted ? 'Active Walk' : 'Dojo Walker - Buddy',
          style: const TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 1. Today's Activity Card
            const ActivityCard(),
            
            const SizedBox(height: 20),

            // 2. Map View / Real Map
            const MapViewWidget(),

            if (_isWalkStarted && _scannedOwnerData != null) ...[
              const SizedBox(height: 20),
              Text(
                "Connected to Owner:\n$_scannedOwnerData",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],

            const SizedBox(height: 30),

            // 3. Conditional UI: Show Blue Live Walk Bar if walk started, else show Scan QR Button
            if (_isWalkStarted)
              GestureDetector(
                onTap: _navigateToLiveWalk,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade700,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(80),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_walk, color: Colors.white, size: 28),
                          SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Live Walk in Progress",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Tap to view live details",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _openCameraScanner(context),
                  child: const Text(
                    'Scan Owner QR Code',
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

// Dedicated Live Walk Details Screen class to handle active walk interface
class LiveWalkDetailsScreen extends StatelessWidget {
  const LiveWalkDetailsScreen({
    super.key,
    required this.ownerData,
    required this.onWalkCompleted,
  });

  final String ownerData;
  final VoidCallback onWalkCompleted;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue.shade700,
        title: const Text('Live Walk Details', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Active Walk in Progress...",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                "Owner Info: $ownerData",
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
            ),
            const Spacer(),
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
                onPressed: onWalkCompleted,
                child: const Text(
                  'Complete / End Walk',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
