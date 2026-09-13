import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../../../screens/help_support_screen.dart';

class AcceptWalkTopBar extends StatelessWidget {
  const AcceptWalkTopBar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        width: double.infinity,
        height: 64,
        color: DojoWalkerColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: <Widget>[
            // ======================================================
            // DOJO WALKER LOGO
            // ======================================================

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

            // ======================================================
            // TITLE
            // ======================================================

            const Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'ACCEPT WALK',
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
                    'Going to pickup point',
                    style: TextStyle(
                      color: DojoWalkerColors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),

            // ======================================================
            // HELP & SUPPORT
            // ======================================================

            IconButton(
              tooltip: 'Help & Support',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const WalkerHelpSupportScreen(),
                  ),
                );
              },
              splashRadius: 22,
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DojoWalkerColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: DojoWalkerColors.white,
                  size: 22,
                ),
              ),
            ),

            const SizedBox(width: 4),

            // ======================================================
            // EMERGENCY
            // ======================================================

            Container(
              width: 42,
              height: 40,
              decoration: BoxDecoration(
                color: DojoWalkerColors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.emergency_rounded,
                color: DojoWalkerColors.error,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
