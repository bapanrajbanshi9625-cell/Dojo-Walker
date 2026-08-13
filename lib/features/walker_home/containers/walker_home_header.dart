import 'package:flutter/material.dart';

import '../walker_home_features.dart';

class WalkerHomeHeader extends StatelessWidget {
  const WalkerHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      decoration: const BoxDecoration(
        color: WalkerHomeFeatures.orange,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(.38),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 29,
            ),
          ),

          const SizedBox(width: 11),

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dojo Walker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  "Buddy's Dashboard",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          GestureDetector(
            onTap: () {
              WalkerHomeFeatures.openNotifications(context);
            },
            child: const _HeaderButton(
              icon: Icons.notifications_none_rounded,
            ),
          ),

          const SizedBox(width: 7),

          GestureDetector(
            onTap: () {
              WalkerHomeFeatures.openSupport(context);
            },
            child: const _HeaderButton(
              icon: Icons.headset_mic_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;

  const _HeaderButton({
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(.30),
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 21,
      ),
    );
  }
}
