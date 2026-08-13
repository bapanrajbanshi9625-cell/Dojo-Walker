import 'package:flutter/material.dart';

import '../walker_home_features.dart';

class WelcomeContainer extends StatelessWidget {
  const WelcomeContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: WalkerHomeFeatures.dark,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.11),
            blurRadius: 17,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: WalkerHomeFeatures.orange
                  .withOpacity(.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: WalkerHomeFeatures.orange
                    .withOpacity(.48),
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: WalkerHomeFeatures.orange,
              size: 40,
            ),
          ),

          const SizedBox(width: 17),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'You and Buddy are ready to walk.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
