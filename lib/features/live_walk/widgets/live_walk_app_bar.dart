import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../../../screens/help_support_screen.dart';

class LiveWalkAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LiveWalkAppBar({
    super.key,
    required this.enabled,
    required this.onSos,
    required this.onSupport,
  });

  final bool enabled;
  final VoidCallback onSos;
  final VoidCallback onSupport;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 64,
      backgroundColor: DojoWalkerColors.primary,
      surfaceTintColor: DojoWalkerColors.transparent,
      elevation: 0,
      centerTitle: false,
      titleSpacing: 16,
      title: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: DojoWalkerColors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
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
                  color: DojoWalkerColors.white,
                  size: 24,
                );
              },
            ),
          ),
          const SizedBox(width: 11),
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'LIVE WALK',
                style: TextStyle(
                  color: DojoWalkerColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Walk in progress',
                style: TextStyle(
                  color: DojoWalkerColors.white,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        _HeaderAction(
          enabled: enabled,
          tooltip: 'Help & Support',
          icon: Icons.support_agent_rounded,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const WalkerHelpSupportScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: _EmergencyAction(
            enabled: enabled,
            onPressed: () {
              _showEmergencySheet(context);
            },
          ),
        ),
      ],
    );
  }

  // ============================================================
  // EMERGENCY BOTTOM SHEET
  // ============================================================

  static void _showEmergencySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DojoWalkerColors.transparent,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return const _EmergencyBottomSheet();
      },
    );
  }
}

// ================================================================
// HEADER ACTION
// ================================================================

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.enabled,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final bool enabled;
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      splashRadius: 22,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: DojoWalkerColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled
              ? DojoWalkerColors.white
              : DojoWalkerColors.white.withValues(alpha: 0.35),
          size: 22,
        ),
      ),
    );
  }
}

// ================================================================
// EMERGENCY ICON
// ================================================================

class _EmergencyAction extends StatelessWidget {
  const _EmergencyAction({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DojoWalkerColors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 42,
          height: 40,
          decoration: BoxDecoration(
            color: enabled
                ? DojoWalkerColors.white
                : DojoWalkerColors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.emergency_rounded,
            color: enabled
                ? DojoWalkerColors.error
                : DojoWalkerColors.white.withValues(alpha: 0.45),
            size: 24,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// EMERGENCY BOTTOM SHEET
// ================================================================

class _EmergencyBottomSheet extends StatelessWidget {
  const _EmergencyBottomSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(
          left: 10,
          right: 10,
          bottom: 10,
        ),
        padding: const EdgeInsets.fromLTRB(
          18,
          10,
          18,
          18,
        ),
        decoration: const BoxDecoration(
          color: DojoWalkerColors.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(26),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: DojoWalkerColors.border,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 17),

            // ----------------------------------------------------
            // HEADER
            // ----------------------------------------------------

            Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: DojoWalkerColors.errorLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.emergency_rounded,
                    color: DojoWalkerColors.error,
                    size: 27,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          color: DojoWalkerColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Tap a service to call immediately',
                        style: TextStyle(
                          color: DojoWalkerColors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: DojoWalkerColors.textSecondary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ----------------------------------------------------
            // AMBULANCE
            // ----------------------------------------------------

            _EmergencyContactTile(
              icon: Icons.local_hospital_rounded,
              title: 'Ambulance',
              subtitle: 'Medical emergency',
              number: '108',
              iconBackground:
                  DojoWalkerColors.errorLight,
              iconColor: DojoWalkerColors.error,
              onTap: () {
                _callEmergency(context, '108');
              },
            ),

            const SizedBox(height: 10),

            // ----------------------------------------------------
            // POLICE
            // ----------------------------------------------------

            _EmergencyContactTile(
              icon: Icons.local_police_rounded,
              title: 'Police',
              subtitle: 'Police emergency',
              number: '112',
              iconBackground:
                  DojoWalkerColors.infoLight,
              iconColor: DojoWalkerColors.info,
              onTap: () {
                _callEmergency(context, '112');
              },
            ),

            const SizedBox(height: 10),

            // ----------------------------------------------------
            // FIRE
            // ----------------------------------------------------

            _EmergencyContactTile(
              icon: Icons.local_fire_department_rounded,
              title: 'Fire & Rescue',
              subtitle: 'Fire emergency',
              number: '101',
              iconBackground:
                  DojoWalkerColors.warningLight,
              iconColor: DojoWalkerColors.warning,
              onTap: () {
                _callEmergency(context, '101');
              },
            ),

            const SizedBox(height: 10),

            // ----------------------------------------------------
            // NATIONAL EMERGENCY
            // ----------------------------------------------------

            _EmergencyContactTile(
              icon: Icons.emergency_share_rounded,
              title: 'National Emergency',
              subtitle: 'All-in-one emergency number',
              number: '112',
              iconBackground:
                  DojoWalkerColors.light,
              iconColor: DojoWalkerColors.primary,
              onTap: () {
                _callEmergency(context, '112');
              },
            ),

            const SizedBox(height: 6),

            const Text(
              'Only call emergency services when immediate assistance is required.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DojoWalkerColors.textMuted,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DIAL
  // ============================================================

  static Future<void> _callEmergency(
    BuildContext context,
    String number,
  ) async {
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: number,
    );

    final bool canLaunch =
        await canLaunchUrl(phoneUri);

    if (!context.mounted) {
      return;
    }

    if (canLaunch) {
      await launchUrl(phoneUri);
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Unable to open phone dialer for $number.',
          ),
          backgroundColor: DojoWalkerColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}

// ================================================================
// EMERGENCY CONTACT TILE
// ================================================================

class _EmergencyContactTile extends StatelessWidget {
  const _EmergencyContactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.number,
    required this.iconBackground,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String number;
  final Color iconBackground;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DojoWalkerColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: DojoWalkerColors.background,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: DojoWalkerColors.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(13),
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
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        color:
                            DojoWalkerColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color:
                            DojoWalkerColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: DojoWalkerColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: DojoWalkerColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.phone_rounded,
                      color: DojoWalkerColors.primary,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      number,
                      style: const TextStyle(
                        color:
                            DojoWalkerColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
