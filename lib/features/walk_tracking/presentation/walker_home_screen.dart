import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class WalkerHomeScreen extends StatefulWidget {
  const WalkerHomeScreen({super.key});

  @override
  State<WalkerHomeScreen> createState() => _WalkerHomeScreenState();
}

class _WalkerHomeScreenState extends State<WalkerHomeScreen> {
  bool _isWalkStarted = false;

  void _openCameraScanner(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Scan QR Code',
          style: TextStyle(color: AppColors.primary),
        ),
        content: SizedBox(
          height: 150,
          child: Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                Navigator.pop(context);
                setState(() => _isWalkStarted = true);
              },
              child: const Text(
                'Simulate Scan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
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
                child: Icon(
                  _isWalkStarted ? Icons.directions_walk : Icons.map,
                  size: 100,
                  color: AppColors.primary,
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
                    setState(() => _isWalkStarted = false);
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
