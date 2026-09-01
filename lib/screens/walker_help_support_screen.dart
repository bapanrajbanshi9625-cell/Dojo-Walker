import 'package:flutter/material.dart';

import '../core/theme/dojo_colors.dart';

class WalkerHelpSupportScreen extends StatelessWidget {
  const WalkerHelpSupportScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoColors.background,
      appBar: AppBar(
        backgroundColor: DojoColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24,
        ),
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: DojoColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: DojoColors.border,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.support_agent_rounded,
                  color: DojoColors.orange,
                  size: 32,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Walker Support',
                        style: TextStyle(
                          color: DojoColors.textPrimary,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Need help with your walks or account?',
                        style: TextStyle(
                          color: DojoColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // =====================================================
          // WALK HELP
          // =====================================================

          _SupportTile(
            icon: Icons.directions_walk_rounded,
            title: 'Walk Help',
            subtitle:
                'Get help with starting, managing or completing a walk.',
            onTap: () {
              _showInfo(
                context,
                'Walk Help',
                'For problems during an active walk, make sure your internet connection is working. If the problem continues, contact Dojo Support.',
              );
            },
          ),

          const SizedBox(height: 8),

          // =====================================================
          // QR WALK
          // =====================================================

          _SupportTile(
            icon: Icons.qr_code_rounded,
            title: 'QR Walk Help',
            subtitle:
                'Problems connecting with an Owner through QR?',
            onTap: () {
              _showInfo(
                context,
                'QR Walk Help',
                'Make sure the Owner is showing the correct Dojo QR code and scan it clearly. If the connection does not complete, try scanning again.',
              );
            },
          ),

          const SizedBox(height: 8),

          // =====================================================
          // INSTA WALK
          // =====================================================

          _SupportTile(
            icon: Icons.radar_rounded,
            title: 'Insta Walk Help',
            subtitle:
                'Need help with Walker requests or Insta Walk?',
            onTap: () {
              _showInfo(
                context,
                'Insta Walk Help',
                'Keep Insta Walk Search active when you want to receive nearby walk requests. You can accept or decline incoming requests from the request screen.',
              );
            },
          ),

          const SizedBox(height: 8),

          // =====================================================
          // ACCOUNT
          // =====================================================

          _SupportTile(
            icon: Icons.manage_accounts_outlined,
            title: 'Account Help',
            subtitle:
                'Problems with your Walker profile or account?',
            onTap: () {
              _showInfo(
                context,
                'Account Help',
                'Check your Walker profile information and make sure your required profile details are complete.',
              );
            },
          ),

          const SizedBox(height: 8),

          // =====================================================
          // CONTACT SUPPORT
          // =====================================================

          _SupportTile(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Contact Support',
            subtitle:
                'Contact Dojo Support for an unresolved problem.',
            onTap: () {
              _showContactSupport(context);
            },
          ),

          const SizedBox(height: 20),

          // =====================================================
          // SAFETY
          // =====================================================

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: DojoColors.orangeLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: DojoColors.orange,
                  size: 20,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'For urgent safety issues during a walk, prioritize the safety of the dog, Owner and Walker first.',
                    style: TextStyle(
                      color: DojoColors.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFO DIALOG
  // ============================================================

  void _showInfo(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: DojoColors.orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CONTACT SUPPORT
  // ============================================================

  void _showContactSupport(
    BuildContext context,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DojoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              14,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: DojoColors.border,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Contact Support',
                  style: TextStyle(
                    color: DojoColors.dark,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Support contact details can be connected here later.',
                  style: TextStyle(
                    color: DojoColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    icon: const Icon(
                      Icons.support_agent_rounded,
                    ),
                    label: const Text(
                      'Close',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          DojoColors.orange,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(
                        vertical: 13,
                      ),
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ================================================================
// SUPPORT TILE
// ================================================================

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DojoColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: DojoColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: DojoColors.orangeLight,
                  borderRadius:
                      BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: DojoColors.orange,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: DojoColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: DojoColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: DojoColors.iconSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
