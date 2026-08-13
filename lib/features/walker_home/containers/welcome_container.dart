import 'package:flutter/material.dart';

import '../walker_home_features.dart';

class WelcomeContainer extends StatelessWidget {
  const WelcomeContainer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: WalkerHomeFeatures.dark,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: WalkerHomeFeatures.orange.withOpacity(.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: WalkerHomeFeatures.orange.withOpacity(.40),
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: WalkerHomeFeatures.orange,
              size: 32,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                SizedBox(height: 4),

                Text(
                  'You and Buddy are ready to walk.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.2,
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
