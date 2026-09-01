// File:
// lib/screens/menu_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_colors.dart';
import '../features/walker_home/containers/walker_home_header.dart';
import 'mobile_login_screen.dart';
import 'profile_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  // ============================================================
  // NAVIGATION
  // ============================================================

  void _showComingSoon(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(
            24,
            24,
            24,
            30,
          ),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                  size: 27,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.buttonText,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // RELOAD APP
  // ============================================================

  Future<void> _reloadApp(
    BuildContext context,
  ) async {
    final NavigatorState navigator = Navigator.of(context);

    // Close any open menu/sheet first.
    if (navigator.canPop()) {
      navigator.pop();
    }

    await Future<void>.delayed(
      const Duration(milliseconds: 150),
    );

    if (!context.mounted) {
      return;
    }

    // Rebuild the current route.
    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MenuScreen(),
      ),
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout(
    BuildContext context,
  ) async {
    final bool? confirm =
        await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Logout',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to logout from your Walker account?',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    await FirebaseAuth.instance.signOut();

    final SharedPreferences prefs =
        await SharedPreferences.getInstance();

    await prefs.setBool(
      'isLoggedIn',
      false,
    );

    if (!context.mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const MobileLoginScreen(),
      ),
      (Route<dynamic> route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ======================================================
          // COMMON WALKER HEADER
          // ======================================================

          const WalkerHomeHeader(),

          // ======================================================
          // MENU CONTENT
          // ======================================================

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                16,
                14,
                16,
                24,
              ),
              children: [
                // ==================================================
                // ACCOUNT
                // ==================================================

                const _MenuSectionTitle(
                  title: 'Account',
                ),

                const SizedBox(height: 8),

                _MenuCard(
                  icon: Icons.person_outline_rounded,
                  iconColor: AppColors.primary,
                  title: 'My Profile',
                  subtitle: 'View and manage your Walker profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.directions_walk_rounded,
                  iconColor: AppColors.info,
                  title: 'My Walks',
                  subtitle: 'View your completed and past walks',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'My Walks',
                      description:
                          'Your completed walk history will appear here.',
                      icon: Icons.directions_walk_rounded,
                    );
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.star_outline_rounded,
                  iconColor: AppColors.warning,
                  title: 'Ratings & Reviews',
                  subtitle: 'View your Walker ratings and reviews',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'Ratings & Reviews',
                      description:
                          'Your ratings and owner reviews will appear here.',
                      icon: Icons.star_outline_rounded,
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // WALKER
                // ==================================================

                const _MenuSectionTitle(
                  title: 'Walker',
                ),

                const SizedBox(height: 8),

                _MenuCard(
                  icon: Icons.checkroom_outlined,
                  iconColor: AppColors.primary,
                  title: 'Walker Uniform',
                  subtitle: 'Uniform requirements and information',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'Walker Uniform',
                      description:
                          'Your official Dojo Walker uniform information will appear here.',
                      icon: Icons.checkroom_outlined,
                    );
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.badge_outlined,
                  iconColor: AppColors.info,
                  title: 'Walker ID / Verification',
                  subtitle: 'View your Walker verification details',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'Walker ID / Verification',
                      description:
                          'Your Walker ID and verification information will appear here.',
                      icon: Icons.badge_outlined,
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // SAFETY & SUPPORT
                // ==================================================

                const _MenuSectionTitle(
                  title: 'Safety & Support',
                ),

                const SizedBox(height: 8),

                _MenuCard(
                  icon: Icons.emergency_outlined,
                  iconColor: AppColors.error,
                  title: 'Safety / Emergency',
                  subtitle: 'Emergency and Walker safety information',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'Safety / Emergency',
                      description:
                          'Emergency contacts and Walker safety tools will appear here.',
                      icon: Icons.emergency_outlined,
                    );
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.headset_mic_outlined,
                  iconColor: AppColors.info,
                  title: 'Help & Support',
                  subtitle: 'Get help with your Walker account',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'Help & Support',
                      description:
                          'Walker support options will appear here.',
                      icon: Icons.headset_mic_outlined,
                    );
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.help_outline_rounded,
                  iconColor: AppColors.primary,
                  title: 'FAQs',
                  subtitle: 'Frequently asked Walker questions',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'FAQs',
                      description:
                          'Frequently asked questions for Walkers will appear here.',
                      icon: Icons.help_outline_rounded,
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // INFORMATION
                // ==================================================

                const _MenuSectionTitle(
                  title: 'Information',
                ),

                const SizedBox(height: 8),

                _MenuCard(
                  icon: Icons.description_outlined,
                  iconColor: AppColors.textSecondary,
                  title: 'Terms & Conditions',
                  subtitle: 'Dojo Walker terms and conditions',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'Terms & Conditions',
                      description:
                          'The Dojo Walker terms and conditions will appear here.',
                      icon: Icons.description_outlined,
                    );
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.lock_outline_rounded,
                  iconColor: AppColors.textSecondary,
                  title: 'Privacy Policy',
                  subtitle: 'How your information is handled',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'Privacy Policy',
                      description:
                          'The Dojo Walker privacy policy will appear here.',
                      icon: Icons.lock_outline_rounded,
                    );
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.info_outline_rounded,
                  iconColor: AppColors.textSecondary,
                  title: 'About Dojo Walker',
                  subtitle: 'App information and version',
                  onTap: () {
                    _showComingSoon(
                      context,
                      title: 'About Dojo Walker',
                      description:
                          'Dojo Walker application information will appear here.',
                      icon: Icons.info_outline_rounded,
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ==================================================
                // APP
                // ==================================================

                const _MenuSectionTitle(
                  title: 'App',
                ),

                const SizedBox(height: 8),

                _MenuCard(
                  icon: Icons.refresh_rounded,
                  iconColor: AppColors.primary,
                  title: 'Reload App',
                  subtitle: 'Refresh the Walker app',
                  onTap: () {
                    _reloadApp(context);
                  },
                ),

                const SizedBox(height: 10),

                _MenuCard(
                  icon: Icons.logout_rounded,
                  iconColor: AppColors.error,
                  title: 'Logout',
                  subtitle: 'Sign out of your Walker account',
                  destructive: true,
                  onTap: () {
                    _logout(context);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SECTION TITLE
// ================================================================

class _MenuSectionTitle extends StatelessWidget {
  final String title;

  const _MenuSectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

// ================================================================
// MENU CARD
// ================================================================

class _MenuCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _MenuCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color effectiveTitleColor =
        destructive
            ? AppColors.error
            : AppColors.textPrimary;

    final Color effectiveSubtitleColor =
        destructive
            ? AppColors.error
            : AppColors.textSecondary;

    final Color iconBackground =
        destructive
            ? AppColors.error.withValues(alpha: 0.08)
            : iconColor.withValues(alpha: 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.border,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                // ==================================================
                // ICON
                // ==================================================

                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 13),

                // ==================================================
                // TEXT
                // ==================================================

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: effectiveTitleColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: effectiveSubtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ==================================================
                // ARROW
                // ==================================================

                Icon(
                  Icons.chevron_right_rounded,
                  color: destructive
                      ? AppColors.error
                      : AppColors.iconSecondary,
                  size: 23,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
