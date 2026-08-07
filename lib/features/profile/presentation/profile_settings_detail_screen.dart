import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProfileSettingsDetailScreen extends StatelessWidget {
  const ProfileSettingsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile Settings',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: const Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: Bapan Walker',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Phone: +91 9876543210',
              style: TextStyle(fontSize: 16, color: AppColors.textGrey),
            ),
          ],
        ),
      ),
    );
  }
}
