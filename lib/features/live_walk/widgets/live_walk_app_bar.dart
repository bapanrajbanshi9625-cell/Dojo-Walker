import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

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
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      surfaceTintColor: AppColors.primary,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,

      // ========================================================
      // TITLE
      // ========================================================

      title: const Text(
        'LIVE WALK',
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: .4,
        ),
      ),

      // ========================================================
      // ACTIONS
      // ========================================================

      actions: [
        // ------------------------------------------------------
        // SOS
        // ------------------------------------------------------

        IconButton(
          tooltip: 'SOS',
          onPressed: enabled ? onSos : null,
          icon: const Icon(
            Icons.sos_rounded,
            color: Colors.white,
            size: 27,
          ),
        ),

        // ------------------------------------------------------
        // SUPPORT
        // ------------------------------------------------------

        IconButton(
          tooltip: 'Support',
          onPressed: enabled ? onSupport : null,
          icon: const Icon(
            Icons.support_agent_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ],
    );
  }
}
