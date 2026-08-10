import 'package:flutter/material.dart';
import '../widgets/live_walk_activity_card.dart';
import '../widgets/customer_info_card.dart';
import '../widgets/map_view_widget.dart';

class AppColors {
  static const Color primary = Color(0xFFFF6600);
}

class WalkerHomeScreen extends StatelessWidget {
  final VoidCallback? onWalkCompleted;

  const WalkerHomeScreen({super.key, this.onWalkCompleted});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Dojo Walker - Buddy', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: const [
            LiveWalkActivityCard(),
            SizedBox(height: 16),
            CustomerInfoCard(),
            SizedBox(height: 16),
            MapViewWidget(),
            SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Colors.white,
        child: ElevatedButton(
          onPressed: () {
            // 1. वॉक कम्प्लीट होने का मैसेज दिखाएं
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Walk Completed Successfully!")),
            );

            // 2. होम स्क्रीन की नीली पट्टी हटाने के लिए कॉलबैक ट्रिगर करें
            if (onWalkCompleted != null) {
              onWalkCompleted!();
            }

            // 3. इस लाइव पेज को बंद करके वापस होम स्क्रीन पर जाएं
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
          ),
          child: const Text(
            'Complete Walk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
