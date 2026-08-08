// File location: lib/screens/walker_home_screen.dart
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isWalkStarted ? 'Active Walk' : 'Dojo Walker - Buddy',
          style: const TextStyle(color: Colors.white),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isWalkStarted ? Icons.directions_walk : Icons.map,
                      size: 100,
                      color: AppColors.primary,
                    ),
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
                  ],
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isWalkStarted ? Colors.redAccent : AppColors.primary,
                ),
                onPressed: () {
                  if (!_isWalkStarted) {
                    _openCameraScanner(context);
                  } else {
                    setState(() {
                      _isWalkStarted = false;
                      _scannedOwnerData = null;
                    });
                  }
                },
                child: Text(
                  _isWalkStarted ? 'End Walk' : 'Scan Owner QR Code',
                  style: const TextStyle(
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
