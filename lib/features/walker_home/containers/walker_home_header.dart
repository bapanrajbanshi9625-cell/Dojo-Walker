import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../screens/profile_screen.dart';
import '../walker_home_features.dart';

class WalkerHomeHeader extends StatelessWidget {
  const WalkerHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Container(
      width: double.infinity,
      color: WalkerHomeFeatures.orange,
      child: SafeArea(
        top: true,
        bottom: false,
        child: Container(
          // ==================================================
          // COMPACT HEADER HEIGHT
          // ==================================================

          height: 86,
          width: double.infinity,

          padding: const EdgeInsets.symmetric(horizontal: 16),

          decoration: const BoxDecoration(
            color: WalkerHomeFeatures.orange,
          ),

          child: Row(
            children: [
              // ==================================================
              // PAW LOGO
              // ==================================================

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

              const SizedBox(width: 10),

              // ==================================================
              // TITLE
              // ==================================================

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
                icon: Icons.notifications_none_rounded,
                iconColor: const Color(0xFFFFE082),
                backgroundColor: Colors.white.withOpacity(.14),
                onTap: () {
                  WalkerHomeFeatures.openNotifications(context);
                },
              ),

              const SizedBox(width: 6),

              // ==================================================
              // SUPPORT
              // ==================================================

              _HeaderButton(
                icon: Icons.headset_mic_outlined,
                iconColor: const Color(0xFFB3E5FC),
                backgroundColor: Colors.white.withOpacity(.14),
                onTap: () {
                  WalkerHomeFeatures.openSupport(context);
                },
              ),

              const SizedBox(width: 6),

              // ==================================================
              // PROFILE / SELFIE
              // ==================================================

              _ProfileButton(
                user: user,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ProfileScreen(),
                    ),
                  );
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
// PROFILE BUTTON
// ================================================================

class _ProfileButton extends StatelessWidget {
  final User? user;
  final VoidCallback onTap;

  const _ProfileButton({
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return _fallbackButton();
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('walkers')
          .doc(user!.uid)
          .snapshots(),
      builder: (
        context,
        snapshot,
      ) {
        String selfieUrl = '';

        if (snapshot.hasData && snapshot.data!.exists) {
          final Map<String, dynamic> data =
              snapshot.data!.data() ?? <String, dynamic>{};

          selfieUrl = (data['Profile Selfie'] ?? '')
              .toString()
              .trim();
        }

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
                color: const Color(0xFFFFD180),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: selfieUrl.isNotEmpty
                ? Image.network(
                    selfieUrl,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons.person_outline_rounded,
                        color: Color(0xFFFFD180),
                        size: 19,
                      );
                    },
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    color: Color(0xFFFFD180),
                    size: 19,
                  ),
          ),
        );
      },
    );
  }

  // ============================================================
  // FALLBACK
  // ============================================================

  Widget _fallbackButton() {
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
            color: const Color(0xFFFFD180),
            width: 1.5,
          ),
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          color: Color(0xFFFFD180),
          size: 19,
        ),
      ),
    );
  }
}

// ================================================================
// COMMON HEADER BUTTON
// ================================================================

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
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
          color: backgroundColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(.30),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 19,
        ),
      ),
    );
  }
}
