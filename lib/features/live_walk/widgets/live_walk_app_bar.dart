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
      const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 64,

      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,

      centerTitle: false,

      titleSpacing: 16,

      // ========================================================
      // TITLE
      // ========================================================

      title: Row(
        children: <Widget>[
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_walk_rounded,
              color: Colors.white,
              size: 22,
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
                  color: Colors.white,
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
                  color: Colors.white70,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),

      // ========================================================
      // ACTIONS
      // ========================================================

      actions: <Widget>[
        // ------------------------------------------------------
        // SUPPORT
        // ------------------------------------------------------

        _HeaderAction(
          enabled: enabled,
          tooltip: 'Support',
          icon: Icons.support_agent_rounded,
          onPressed: onSupport,
        ),

        const SizedBox(width: 4),

        // ------------------------------------------------------
        // SOS
        // ------------------------------------------------------

        Padding(
          padding: const EdgeInsets.only(
            right: 12,
          ),
          child: _SosAction(
            enabled: enabled,
            onPressed: onSos,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// HEADER ACTION
// ============================================================

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
          color: Colors.white.withValues(
            alpha: 0.12,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: enabled
              ? Colors.white
              : Colors.white38,
          size: 22,
        ),
      ),
    );
  }
}

// ============================================================
// SOS ACTION
// ============================================================

class _SosAction extends StatelessWidget {
  const _SosAction({
    required this.enabled,
    required this.onPressed,
  });

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
          ),
          decoration: BoxDecoration(
            color: enabled
                ? Colors.white
                : Colors.white24,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.sos_rounded,
                color: enabled
                    ? Colors.red.shade700
                    : Colors.white54,
                size: 21,
              ),
              const SizedBox(width: 5),
              Text(
                'SOS',
                style: TextStyle(
                  color: enabled
                      ? Colors.red.shade700
                      : Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
