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
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
            ),
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
                // BRAND + AVAILABILITY
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
                          const SizedBox(height: 4),
                          _AvailabilityToggle(
                            isOnline: availability.isOnline,
                            isActiveWalk: availability.isActiveWalk,
                            isChanging:
                                availability.isChangingStatus,
                            onTap: () async {
                              await _handleAvailabilityTap(
                                context,
                                availability,
                              );
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
                        builder: (_) => const NotificationsScreen(),
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
                        builder: (_) => const ProfileScreen(),
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
  // AVAILABILITY ACTION
  // ==============================================================

  static Future<void> _handleAvailabilityTap(
    BuildContext context,
    WalkerAvailabilityService availability,
  ) async {
    if (availability.isChangingStatus) {
      return;
    }

    // Active walk हमेशा Online रहेगा.
    if (availability.isActiveWalk) {
      _showActiveWalkMessage(context);
      return;
    }

    // ============================================================
    // ONLINE -> OFFLINE
    // ============================================================

    if (availability.isOnline) {
      final bool? confirmed =
          await _showOfflineConfirmation(context);

      if (!context.mounted || confirmed != true) {
        return;
      }

      await availability.goOffline();

      // IMPORTANT:
      // The async operation above may have changed the widget
      // lifecycle. Do not use BuildContext until mounted is checked.
      if (!context.mounted) {
        return;
      }

      _showAvailabilityErrorIfAny(
        context,
        availability,
      );

      return;
    }

    // ============================================================
    // OFFLINE -> CHOOSE WALK TYPE
    // ============================================================

    final WalkerWalkType? selected =
        await _showWalkTypePicker(context);

    if (!context.mounted || selected == null) {
      return;
    }

    await availability.setWalkType(
      selected,
    );

    if (!context.mounted) {
      return;
    }

    final bool online =
        await availability.goOnline();

    if (!context.mounted) {
      return;
    }

    if (!online) {
      _showAvailabilityErrorIfAny(
        context,
        availability,
      );
      return;
    }

    // IMPORTANT:
    // Insta Walk selected = ONLINE only.
    // Search remains OFF until Start Insta Walk Search.
    if (selected == WalkerWalkType.instaWalk) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'You are Online for Insta Walk. Start Insta Walk Search to receive nearby walk requests.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'You are Online for Daily Walk. Your assigned walk can continue.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ==============================================================
  // WALK TYPE PICKER
  // ==============================================================

  static Future<WalkerWalkType?> _showWalkTypePicker(
    BuildContext context,
  ) {
    return showModalBottomSheet<WalkerWalkType>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (
        BuildContext sheetContext,
      ) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              12,
              0,
              12,
              12,
            ),
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              18,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1D5DB),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose Walk Type',
                  style: TextStyle(
                    color: Color(0xFF171717),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how you want to work Online.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                _WalkTypeOption(
                  icon: Icons.pets_rounded,
                  title: 'Insta Walk',
                  subtitle:
                      'Find nearby instant walk requests',
                  iconColor: DojoWalkerColors.primary,
                  onTap: () {
                    Navigator.of(sheetContext).pop(
                      WalkerWalkType.instaWalk,
                    );
                  },
                ),

                const SizedBox(height: 10),

                _WalkTypeOption(
                  icon: Icons.calendar_month_rounded,
                  title: 'Daily Walk',
                  subtitle:
                      'Continue your assigned daily walk',
                  iconColor: const Color(0xFF3F6FA5),
                  onTap: () {
                    Navigator.of(sheetContext).pop(
                      WalkerWalkType.dailyWalk,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==============================================================
  // OFFLINE CONFIRMATION
  // ==============================================================

  static Future<bool?> _showOfflineConfirmation(
    BuildContext context,
  ) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (
        BuildContext dialogContext,
      ) {
        return AlertDialog(
          title: const Text(
            'Go Offline?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'You will stop receiving new walk requests and live location tracking.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Go Offline'),
            ),
          ],
        );
      },
    );
  }

  // ==============================================================
  // ERROR
  // ==============================================================

  static void _showAvailabilityErrorIfAny(
    BuildContext context,
    WalkerAvailabilityService availability,
  ) {
    final String? error = availability.error;

    if (error == null || error.trim().isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
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
      ..hideCurrentSnackBar()
      ..showSnackBar(
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
// WALK TYPE OPTION
// ================================================================

class _WalkTypeOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final VoidCallback onTap;

  const _WalkTypeOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8F9FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF171717),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
                size: 22,
              ),
            ],
          ),
        ),
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
        width: 88,
        height: 26,
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
            // ======================================================
            // FULL ONLINE / OFFLINE TEXT
            // ======================================================

            Positioned.fill(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      isOnline ? 'ONLINE' : 'OFFLINE',
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.35,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ======================================================
            // TOGGLE KNOB
            // ======================================================

            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: isOnline
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 20,
                height: 20,
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

        if (snapshot.hasData && snapshot.data!.exists) {
          final Map<String, dynamic> data =
              snapshot.data!.data() ?? <String, dynamic>{};

          selfieUrl =
              (data['Profile Selfie'] ?? '').toString().trim();
        }

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
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
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.55),
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
          color: Colors.white.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
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
