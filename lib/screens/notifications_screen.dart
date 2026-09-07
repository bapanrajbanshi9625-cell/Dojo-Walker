import 'package:flutter/material.dart';

import '../core/theme/dojo_walker_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoWalkerColors.background,
      appBar: AppBar(
        backgroundColor: DojoWalkerColors.primary,
        foregroundColor: DojoWalkerColors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: const Center(
        child: Text(
          'No notifications yet',
          style: TextStyle(
            fontSize: 16,
            color: DojoWalkerColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
