// File location:
// lib/screens/walker_help_support_screen.dart

import 'package:flutter/material.dart';

class WalkerHelpSupportScreen extends StatelessWidget {
  const WalkerHelpSupportScreen({
    super.key,
  });

  static const Color _orange = Color(0xFFFF7A00);
  static const Color _orangeLight = Color(0xFFFFF1E6);
  static const Color _background = Color(0xFFF5F6F8);
  static const Color _textPrimary = Color(0xFF202124);
  static const Color _textSecondary = Color(0xFF6B7280);
  static const Color _border = Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Help & Support',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            28,
          ),
          children: [
            // =====================================================
            // WALKER SUPPORT HEADER
            // =====================================================

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: _border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: _orangeLight,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: _orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Walker Support',
                          style: TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Need help with your Walker account or walks?',
                          style: TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // =====================================================
            // WALKER HELP
            // =====================================================

            const _SectionTitle(
              title: 'Walker Help',
            ),

            _SupportTile(
              icon: Icons.directions_walk_rounded,
              title: 'How to complete a walk',
              subtitle:
                  'Learn how the Walker walk process works.',
              onTap: () {
                _showInfo(
                  context,
                  'How to complete a walk',
                  'Accept the walk request, reach the owner, start the walk, complete the walk, and submit the required walk details.',
                );
              },
            ),

            _SupportTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'QR Walk help',
              subtitle:
                  'Get help with QR connection and starting a walk.',
              onTap: () {
                _showInfo(
                  context,
                  'QR Walk',
                  'Scan the owner QR code to establish the walk connection. After reaching the active walk, you can start the walk.',
                );
              },
            ),

            _SupportTile(
              icon: Icons.person_search_rounded,
              title: 'Insta Walk help',
              subtitle:
                  'Learn about Walker requests and accepting walks.',
              onTap: () {
                _showInfo(
                  context,
                  'Insta Walk',
                  'Insta Walk allows an owner to find a Walker nearby and send a walk request. Accept the request to continue with the walk flow.',
                );
              },
            ),

            _SupportTile(
              icon: Icons.cancel_outlined,
              title: 'Cancel a walk',
              subtitle:
                  'Understand when and how a walk can be cancelled.',
              onTap: () {
                _showInfo(
                  context,
                  'Cancel a walk',
                  'If you cannot complete an accepted walk, use the available cancellation option and follow the confirmation steps shown in the app.',
                );
              },
            ),

            const SizedBox(height: 18),

            // =====================================================
            // ACCOUNT
            // =====================================================

            const _SectionTitle(
              title: 'Account',
            ),

            _SupportTile(
              icon: Icons.person_outline_rounded,
              title: 'Walker profile',
              subtitle:
                  'Help with your Walker profile and verification.',
              onTap: () {
                _showInfo(
                  context,
                  'Walker Profile',
                  'Keep your Walker profile information accurate and complete. If verification is pending, allow the verification process to finish.',
                );
              },
            ),

            _SupportTile(
              icon: Icons.verified_user_outlined,
              title: 'Verification',
              subtitle:
                  'Information about Walker verification.',
              onTap: () {
                _showInfo(
                  context,
                  'Walker Verification',
                  'Your Walker verification status is managed by Dojo. If additional information is required, the app will guide you through the required steps.',
                );
              },
            ),

            const SizedBox(height: 18),

            // =====================================================
            // WALK INFORMATION
            // =====================================================

            const _SectionTitle(
              title: 'Walk Information',
            ),

            _SupportTile(
              icon: Icons.history_rounded,
              title: 'Past walks',
              subtitle:
                  'Need help understanding your completed walks?',
              onTap: () {
                _showInfo(
                  context,
                  'Past Walks',
                  'Your completed walks are available in Past Walks. You can review walk information such as dog, owner, time, distance, duration, rating, pee and poop records when available.',
                );
              },
            ),

            _SupportTile(
              icon: Icons.star_outline_rounded,
              title: 'Walk rating',
              subtitle:
                  'Understand ratings after completing walks.',
              onTap: () {
                _showInfo(
                  context,
                  'Walk Rating',
                  'Ratings are associated with completed walks. Your available rating information can be viewed with the relevant completed walk.',
                );
              },
            ),

            const SizedBox(height: 18),

            // =====================================================
            // CONTACT SUPPORT
            // =====================================================

            const _SectionTitle(
              title: 'Contact Support',
            ),

            _SupportTile(
              icon: Icons.help_outline_rounded,
              title: 'Contact Dojo Support',
              subtitle:
                  'Get help when you cannot resolve an issue yourself.',
              onTap: () {
                _showContactSupport(context);
              },
            ),

            const SizedBox(height: 22),

            // =====================================================
            // FOOTER
            // =====================================================

            const Center(
              child: Text(
                'Dojo Walker',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 4),

            const Center(
              child: Text(
                'Walker Help & Support',
                style: TextStyle(
                  color: _textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // INFO DIALOG
  // =============================================================

  static void _showInfo(
    BuildContext context,
    String title,
    String message,
  ) {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
              height: 1.5,
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
                  color: _orange,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =============================================================
  // CONTACT SUPPORT
  // =============================================================

  static void _showContactSupport(
    BuildContext context,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Contact Dojo Support',
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'For account, verification, walk, or other Walker-related issues, contact Dojo Support.',
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 18),

                _ContactOption(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: 'Support',
                  subtitle: 'Open a support request',
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _showInfo(
                      context,
                      'Support Request',
                      'Support request functionality can be connected here when the support service is added.',
                    );
                  },
                ),

                const SizedBox(height: 8),

                _ContactOption(
                  icon: Icons.email_outlined,
                  title: 'Email Support',
                  subtitle: 'Contact Dojo by email',
                  onTap: () {
                    Navigator.pop(sheetContext);

                    _showInfo(
                      context,
                      'Email Support',
                      'Email support can be connected here when the official Dojo support email is configured.',
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
}

// =================================================================
// SECTION TITLE
// =================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 8,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: _textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// =================================================================
// SUPPORT TILE
// =================================================================

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
    return Container(
      margin: const EdgeInsets.only(
        bottom: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _border,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 4,
        ),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _orangeLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: _orange,
            size: 21,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11.5,
            height: 1.3,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF9CA3AF),
        ),
      ),
    );
  }
}

// =================================================================
// CONTACT OPTION
// =================================================================

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _background,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _orangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: _orange,
                  size: 21,
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
                        color: _textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: _textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
