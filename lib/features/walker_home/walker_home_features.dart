import 'package:flutter/material.dart';

import '../../screens/profile_screen.dart';

class WalkerHomeFeatures {
  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF4B16);
  static const Color dark = Color(0xFF27394A);

  // ============================================================
  // TODAY SUMMARY DATA
  // ============================================================

  static const String totalWalks = '0';
  static const String distance = '0.0 km';
  static const String duration = '0 min';
  static const String performance = 'Performance';

  // ============================================================
  // SUMMARY DETAILS
  // ============================================================

  static String summaryDetails(String type) {
    switch (type) {
      case 'walks':
        return 'Today you have completed 0 walks.\n\n'
            'Your completed walks will appear here '
            'as soon as you finish a walk.';

      case 'distance':
        return 'Today’s walking distance is 0.0 km.\n\n'
            'Distance will automatically increase '
            'while your live walk is active.';

      case 'duration':
        return 'Today’s active walking duration is 0 minutes.\n\n'
            'The timer will start when a walk begins '
            'and continue while the walk is active.';

      case 'report':
        return 'Your walking performance will be shown here.\n\n'
            'You will be able to review completed walks, '
            'distance, duration and overall activity.';

      default:
        return '';
    }
  }

  // ============================================================
  // PAST WALKS
  // ============================================================

  static const List<Map<String, String>> pastWalks = [
    {
      'id': '#WWD-1023',
      'time': '08:15 AM',
      'details': '1.8 km • 25 mins • 04 Aug 2026',
      'distance': '1.8 km',
      'duration': '25 minutes',
      'date': '04 Aug 2026',
      'status': 'Completed',
    },
    {
      'id': '#WWD-1022',
      'time': '06:45 AM',
      'details': '2.3 km • 32 mins • 03 Aug 2026',
      'distance': '2.3 km',
      'duration': '32 minutes',
      'date': '03 Aug 2026',
      'status': 'Completed',
    },
  ];

  // ============================================================
  // PAST WALK DETAILS
  // ============================================================

  static String pastWalkDetails(
    Map<String, String> walk,
  ) {
    return 'Walk ID: ${walk['id']}\n\n'
        'Start Time: ${walk['time']}\n'
        'Distance: ${walk['distance']}\n'
        'Duration: ${walk['duration']}\n'
        'Date: ${walk['date']}\n'
        'Status: ${walk['status']}\n\n'
        'Your complete walk route and location '
        'history can appear here.';
  }

  // ============================================================
  // HEADER ACTIONS
  // ============================================================

  static void openNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifications will open here'),
      ),
    );
  }

  static void openSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support will open here'),
      ),
    );
  }

  // ============================================================
  // PROFILE
  // ============================================================

  static void openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );
  }

  // ============================================================
  // QR ACTION
  // ============================================================

  static void openScanner(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('QR Scanner will open here'),
      ),
    );
  }
}
