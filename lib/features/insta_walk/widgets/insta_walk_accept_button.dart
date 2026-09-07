// File:
// lib/features/insta_walk/widgets/insta_walk_accept_button.dart

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class InstaWalkAcceptButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;

  const InstaWalkAcceptButton({
    super.key,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: SizedBox(
        height: 43,
        child: ElevatedButton(
          onPressed: loading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: DojoWalkerColors.primary,
            foregroundColor: DojoWalkerColors.white,
            disabledBackgroundColor:
                DojoWalkerColors.primary.withValues(
              alpha: .50,
            ),
            disabledForegroundColor:
                DojoWalkerColors.white.withValues(
              alpha: .70,
            ),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DojoWalkerColors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: DojoWalkerColors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Accept Walk',
                      style: TextStyle(
                        color: DojoWalkerColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
