// File:
// lib/screens/walker_main_app_bar.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/theme/dojo_walker_colors.dart';
import '../features/profile/screens/profile_screen.dart';
import '../services/walker_availability_service.dart';
import 'help_support_screen.dart';
import 'notifications_screen.dart';

class WalkerMainAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const WalkerMainAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Container(
      width: double.infinity,
      color: DojoWalkerColors.primary,
      child: SafeArea(
        top: true,
        bottom: false,
        child: SizedBox(
          height: 68,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // ==================================================
                // DOJO WALKER LOGO
                // ==================================================

                SizedBox(
                  width: 46,
                  height: 46,
                  child: Image.asset(
                    'assets/DOJO_WALKER.png',
                    fit: BoxFit.contain,
                    errorBuilder: (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const Icon(
                        Icons.pets_rounded,
                        color: Colors.white,
                        size: 30,
                      );
                    },
                  ),
                ),

                const SizedBox(width: 10),

                // ==================================================
                // BRAND TITLE + AVAILABILITY
                // ==================================================

                Expanded(
                  child: AnimatedBuilder(
                    animation: WalkerAvailabilityService.instance,
                    builder: (
                      BuildContext context,
                      Widget? child,
                    ) {
                      final WalkerAvailabilityService availability =
                          WalkerAvailabilityService.instance;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Dojo Walker',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          _AvailabilityToggle(
                            isOnline: availability.isOnline,
                            isActiveWalk: availability.isActiveWalk,
                            isChanging: availability.isChangingStatus,
                            onTap: () async {
                              if (availability.isChangingStatus) {
                                return;
                              }

                              if (availability.isActiveWalk) {
                                _showActiveWalkMessage(context);
                                return;
                              }

                              await availability.toggleAvailability();

                              if (!context.mounted) {
                                return;
                              }

                              final String? error =
                                  availability.error;

                              if (error != null &&
                                  error.trim().isNotEmpty) {
                                ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();

                                ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(error),
                                  behavior:
                                      SnackBarBehavior.floating,
                                ),
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // ==================================================
                // NOTIFICATION
                // ==================================================

                _HeaderButton(
                  icon: Icons.notifications_none_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const NotificationsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 6),

                // ==================================================
                // HELP
                // ==================================================

                _HeaderButton(
                  icon: Icons.headset_mic_outlined,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const WalkerHelpSupportScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 6),

                // ==================================================
                // PROFILE
                // ==================================================

                _ProfileButton(
                  user: user,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const ProfileScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // ACTIVE WALK MESSAGE
  // ==============================================================

  static void _showActiveWalkMessage(
    BuildContext context,
  ) {
    ScaffoldMessenger.of(context)
      .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'You cannot go Offline during an active walk.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ================================================================
// AVAILABILITY TOGGLE
// ================================================================

class _AvailabilityToggle extends StatelessWidget {
  final bool isOnline;
  final bool isActiveWalk;
  final bool isChanging;
  final VoidCallback onTap;

  const _AvailabilityToggle({
    required this.isOnline,
    required this.isActiveWalk,
    required this.isChanging,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool locked = isActiveWalk;

    return GestureDetector(
      onTap: locked || isChanging ? null : onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 78,
        height: 24,
        padding: const EdgeInsets.symmetric(
          horizontal: 3,
        ),
        decoration: BoxDecoration(
          color: isOnline
              ? const Color(0xFF36B56B)
              : Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOnline
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: isOnline
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(
                  left: isOnline ? 25 : 0,
                  right: isOnline ? 0 : 25,
                ),
                child: Text(
                  isOnline ? 'ONLINE' : 'OFFLINE',
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.45,
                  ),
                ),
              ),
            ),

            // ----------------------------------------------------
            // MOVING TOGGLE KNOB
            // ----------------------------------------------------

            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: isOnline
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: isChanging
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(
                            DojoWalkerColors.primary,
                          ),
                        ),
                      )
                    : locked
                        ? const Icon(
                            Icons.lock_rounded,
                            size: 10,
                            color: DojoWalkerColors.primary,
                          )
                        : null,
              ),
            ),
          ],
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

    return StreamBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('walkers')
          .doc(user!.uid)
          .snapshots(),
      builder: (
        BuildContext context,
        AsyncSnapshot<
            DocumentSnapshot<Map<String, dynamic>>> snapshot,
      ) {
        String selfieUrl = '';

        if (snapshot.hasData &&
            snapshot.data!.exists) {
          final Map<String, dynamic> data =
              snapshot.data!.data() ??
                  <String, dynamic>{};

          selfieUrl =
              (data['Profile Selfie'] ?? '')
                  .toString()
                  .trim();
        }

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    Colors.white.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: selfieUrl.isNotEmpty
                ? Image.network(
                    selfieUrl,
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                    errorBuilder: (
                      BuildContext context,
                      Object error,
                      StackTrace? stackTrace,
                    ) {
                      return const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      );
                    },
                  )
                : const Icon(
                    Icons.person_outline_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
          ),
        );
      },
    );
  }

  Widget _fallbackButton() {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color:
              Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                Colors.white.withValues(alpha: 0.55),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.person_outline_rounded,
          color: Colors.white,
          size: 18,
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
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color:
              Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color:
                Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}
