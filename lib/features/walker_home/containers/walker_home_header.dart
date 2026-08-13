import 'package:flutter/material.dart';

import '../walker_home_features.dart';

class WalkerHomeHeader extends StatelessWidget {
  const WalkerHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        22,
        10,
        18,
        14,
      ),
      decoration: const BoxDecoration(
        color: WalkerHomeFeatures.orange,
      ),
      child: Row(
        children: [
          // ======================================================
          // LOGO
          // ======================================================

          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(.42),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),

          const SizedBox(width: 13),

          // ======================================================
          // TITLE
          // ======================================================

          const Expanded(
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Dojo Walker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  "Buddy's Dashboard",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // ======================================================
          // NOTIFICATION
          // ======================================================

          GestureDetector(
            onTap: () {
              WalkerHomeFeatures
                  .openNotifications(context);
            },
            child: const _HeaderButton(
              icon: Icons.notifications_none_rounded,
            ),
          ),

          const SizedBox(width: 9),

          // ======================================================
          // SUPPORT
          // ======================================================

          GestureDetector(
            onTap: () {
              WalkerHomeFeatures
                  .openSupport(context);
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
      width: 49,
      height: 49,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(.35),
        ),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 26,
      ),
    );
  }
}
