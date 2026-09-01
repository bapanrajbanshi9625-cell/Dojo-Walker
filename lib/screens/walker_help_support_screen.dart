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
            // HEADER CARD
            // =====================================================

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: DojoColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: DojoColors.border,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: DojoColors.orangeLight,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: DojoColors.orange,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How can we help?',
                          style: TextStyle(
                            color: DojoColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Get help with your walks, account, '
                          'verification and other issues.',
                          style: TextStyle(
                            color: DojoColors.textSecondary,
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
            // WALK SUPPORT
            // =====================================================

            const _SectionTitle(
              title: 'Walk Support',
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.directions_walk_rounded,
              title: 'Walk Issue',
              subtitle:
                  'Problems with an active or completed walk',
              onTap: () {
                _showSupportMessage(
                  context,
                  'Walk Support',
                  'If you are facing a problem during a walk, '
                      'please contact Dojo Support with your walk details.',
                );
              },
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.qr_code_scanner_rounded,
              title: 'QR Walk Help',
              subtitle:
                  'Help with QR connection or starting a walk',
              onTap: () {
                _showSupportMessage(
                  context,
                  'QR Walk Help',
                  'Make sure the owner QR is active and scan it '
                      'from the Walker app.',
                );
              },
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.location_on_outlined,
              title: 'Reach / Arrival Issue',
              subtitle:
                  'Problems while reaching the owner',
              onTap: () {
                _showSupportMessage(
                  context,
                  'Arrival Support',
                  'If you have reached the owner but the walk '
                      'cannot continue, contact Dojo Support.',
                );
              },
            ),

            const SizedBox(height: 18),

            // =====================================================
            // ACCOUNT SUPPORT
            // =====================================================

            const _SectionTitle(
              title: 'Account',
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.verified_user_outlined,
              title: 'Verification Help',
              subtitle:
                  'Questions about Walker verification',
              onTap: () {
                _showSupportMessage(
                  context,
                  'Verification Help',
                  'For verification-related problems, please '
                      'contact Dojo Support with your registered '
                      'Walker details.',
                );
              },
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.person_outline_rounded,
              title: 'Profile Help',
              subtitle:
                  'Problems with your Walker profile',
              onTap: () {
                _showSupportMessage(
                  context,
                  'Profile Help',
                  'Check your profile information and make sure '
                      'all required details are completed.',
                );
              },
            ),

            const SizedBox(height: 18),

            // =====================================================
            // GENERAL SUPPORT
            // =====================================================

            const _SectionTitle(
              title: 'General',
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.help_outline_rounded,
              title: 'Frequently Asked Questions',
              subtitle:
                  'Common questions about Dojo Walker',
              onTap: () {
                _showFaq(context);
              },
            ),

            const SizedBox(height: 8),

            _SupportTile(
              icon: Icons.support_agent_rounded,
              title: 'Contact Support',
              subtitle:
                  'Get assistance from Dojo Support',
              onTap: () {
                _showContactSupport(context);
              },
            ),

            const SizedBox(height: 24),

            // =====================================================
            // FOOTER
            // =====================================================

            Center(
              child: Text(
                'Dojo Walker',
                style: TextStyle(
                  color: DojoColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =============================================================
  // SUPPORT MESSAGE
  // =============================================================

  void _showSupportMessage(
    BuildContext context,
    String title,
    String message,
  ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DojoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: DojoColors.orangeLight,
                        borderRadius:
                            BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.support_agent_rounded,
                        color: DojoColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: DojoColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: const TextStyle(
                    color: DojoColors.textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          DojoColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Okay',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
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

  // =============================================================
  // FAQ
  // =============================================================

  void _showFaq(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DojoColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              28,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: const [
                Text(
                  'Frequently Asked Questions',
                  style: TextStyle(
                    color: DojoColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 16),
                _FaqItem(
                  question:
                      'How do I start a walk?',
                  answer:
                      'Complete the required connection or arrival '
                      'step first. Once the walk is ready, the Start '
                      'Walk control will become available.',
                ),
                _FaqItem(
                  question:
                      'How do I complete a walk?',
                  answer:
                      'Use the Slide to Complete Walk control '
                      'available at the bottom of the active walk screen.',
                ),
                _FaqItem(
                  question:
                      'What should I do if something goes wrong?',
                  answer:
                      'Open Help & Support and contact Dojo Support '
                      'with your walk details.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================================================
  // CONTACT SUPPORT
  // =============================================================

  void _showContactSupport(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: DojoColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              20,
              20,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: DojoColors.orangeLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: DojoColors.orange,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Contact Dojo Support',
                  style: TextStyle(
                    color: DojoColors.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Support contact options can be connected '
                  'here when the official Dojo support channel '
                  'is configured.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: DojoColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          DojoColors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
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
// SECTION TITLE
// ================================================================

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: DojoColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
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
                      maxLines: 2,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color:
                            DojoColors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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

// ================================================================
// FAQ ITEM
// ================================================================

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqItem({
    required this.question,
    required this.answer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: DojoColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DojoColors.border,
        ),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(
          horizontal: 14,
        ),
        childrenPadding:
            const EdgeInsets.fromLTRB(
          14,
          0,
          14,
          14,
        ),
        iconColor: DojoColors.orange,
        collapsedIconColor:
            DojoColors.iconSecondary,
        title: Text(
          question,
          style: const TextStyle(
            color: DojoColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(
                color: DojoColors.textSecondary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
