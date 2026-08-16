// File location:
// lib/features/walker_home/containers/walker_home_header.dart

import 'package:flutter/material.dart';

import '../walker_home_features.dart';

class WalkerHomeHeader extends StatelessWidget {
  const WalkerHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: WalkerHomeFeatures.orange,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          // ======================================================
          // SAME APP BAR LEVEL AS PROFILE
          // ======================================================

          height: 56,

          width: double.infinity,

          padding: const EdgeInsets.symmetric(
            horizontal: 16,
          ),

          decoration: const BoxDecoration(
            color: WalkerHomeFeatures.orange,
          ),

          child: Row(
            children: [
              // ==================================================
              // PAW LOGO
              // ==================================================

              Container(
                width: 40,
                height: 40,
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
                  size: 23,
                ),
              ),

              const SizedBox(width: 10),

              // ==================================================
              // TITLE
              // ==================================================

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
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    SizedBox(height: 1),

                    Text(
                      "Buddy's Dashboard",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // NOTIFICATION
              // ==================================================

              _HeaderButton(
                icon:
                    Icons.notifications_none_rounded,
                onTap: () {
                  WalkerHomeFeatures
                      .openNotifications(context);
                },
              ),

              const SizedBox(width: 6),

              // ==================================================
              // SUPPORT
              // ==================================================

              _HeaderButton(
                icon:
                    Icons.headset_mic_outlined,
                onTap: () {
                  WalkerHomeFeatures
                      .openSupport(context);
                },
              ),

              const SizedBox(width: 6),

              // ==================================================
              // PROFILE
              // ==================================================

              _HeaderButton(
                icon:
                    Icons.person_outline_rounded,
                onTap: () {
                  // Profile action can be connected here later.
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================================================================
// HEADER BUTTON
// ================================================================

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
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.14),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(.30),
            width: 1,
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
