import 'package:flutter/material.dart';

import '../../../core/theme/dojo_colors.dart';
import '../widgets/my_box_card.dart';

class MyBoxContainer extends StatelessWidget {
  const MyBoxContainer({
    super.key,
    this.onProfileTap,
    this.onPastWalksTap,
    this.onUniformTap,
    this.onHelpSupportTap,
    this.onReloadTap,
  });

  final VoidCallback? onProfileTap;
  final VoidCallback? onPastWalksTap;
  final VoidCallback? onUniformTap;
  final VoidCallback? onHelpSupportTap;
  final VoidCallback? onReloadTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DojoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: DojoColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // =====================================================
          // HEADER
          // =====================================================

          const Text(
            'My Box',
            style: TextStyle(
              color: DojoColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 4),

          const Text(
            'Everything you need as a Walker',
            style: TextStyle(
              color: DojoColors.textSecondary,
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 14),

          // =====================================================
          // PROFILE
          // =====================================================

          MyBoxCard(
            icon: Icons.person_outline_rounded,
            title: 'My Profile',
            subtitle: 'View and manage your Walker profile',
            onTap: onProfileTap,
          ),

          const SizedBox(height: 8),

          // =====================================================
          // PAST WALKS
          // =====================================================

          MyBoxCard(
            icon: Icons.history_rounded,
            title: 'Past Walks',
            subtitle: 'View your completed walks and details',
            onTap: onPastWalksTap,
          ),

          const SizedBox(height: 8),

          // =====================================================
          // WALKER UNIFORM
          // =====================================================

          MyBoxCard(
            icon: Icons.checkroom_outlined,
            title: 'Walker Uniform',
            subtitle: 'Uniform and Walker appearance guidelines',
            onTap: onUniformTap,
          ),

          const SizedBox(height: 8),

          // =====================================================
          // HELP & SUPPORT
          // =====================================================

          MyBoxCard(
            icon: Icons.support_agent_rounded,
            title: 'Help & Support',
            subtitle: 'Get help with your Walker account and walks',
            onTap: onHelpSupportTap,
          ),

          const SizedBox(height: 8),

          // =====================================================
          // RELOAD APP
          // =====================================================

          MyBoxCard(
            icon: Icons.refresh_rounded,
            title: 'Reload App',
            subtitle: 'Refresh the app and reload current data',
            onTap: onReloadTap,
          ),
        ],
      ),
    );
  }
}
