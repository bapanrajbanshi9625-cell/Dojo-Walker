import 'package:flutter/material.dart';

import '../walker_home_features.dart';

class WalkerHomeHeader extends StatelessWidget {
  const WalkerHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: WalkerHomeFeatures.orange,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(.38),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),

          const SizedBox(width: 9),

          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dojo Walker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  "Buddy's Dashboard",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          _HeaderButton(
            icon: Icons.notifications_none_rounded,
            onTap: () {
              WalkerHomeFeatures.openNotifications(context);
            },
          ),

          const SizedBox(width: 6),

          _HeaderButton(
            icon: Icons.headset_mic_outlined,
            onTap: () {
              WalkerHomeFeatures.openSupport(context);
            },
          ),
        ],
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
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
          size: 20,
        ),
      ),
    );
  }
}
