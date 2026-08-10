// File location: lib/screens/walker_home_screen.dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../widgets/activity_card.dart'; // Today's Activity ki alag file
import '../widgets/map_view.dart';     // Real Map ki alag file
import 'qr_scanner_screen.dart';
import '../features/live_walk/screens/walker_home_screen.dart' as live_walk; // Live Walk Screen import

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
  void _navigateToLiveWalk() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => live_walk.WalkerHomeScreen(
          onWalkCompleted: () {
            setState(() {
              _isWalkStarted = false;
              _scannedOwnerData = null;
            });
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
