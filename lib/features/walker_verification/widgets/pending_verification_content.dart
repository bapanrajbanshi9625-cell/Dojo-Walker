import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';

class PendingVerificationContent
    extends StatelessWidget {
  const PendingVerificationContent({
    super.key,
    required this.isApproved,
    required this.isRejected,
    required this.isPending,
    required this.verificationStatus,
    required this.walkerIdActive,
    required this.animationController,
    required this.pulseAnimation,
    required this.scaleAnimation,
    required this.onSupport,
  });

  final bool isApproved;
  final bool isRejected;
  final bool isPending;

  final String verificationStatus;
  final bool walkerIdActive;

  final AnimationController animationController;

  final Animation<double> pulseAnimation;
  final Animation<double> scaleAnimation;

  final VoidCallback onSupport;

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _verificationIcon(),

        const SizedBox(height: 18),

        Text(
          _pageTitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 27,
            height: 1.15,
            fontWeight: FontWeight.w900,
            color: DojoWalkerColors.textPrimary,
          ),
        ),

        const SizedBox(height: 9),

        Text(
          _pageSubtitle(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: DojoWalkerColors.textMuted,
          ),
        ),

        const SizedBox(height: 20),

        _mainStatusCard(),

        const SizedBox(height: 14),

        _statusCard(),

        const SizedBox(height: 14),

        _nextStepCard(),

        if (!isApproved) ...[
          const SizedBox(height: 14),
          _lockedCard(),
        ],

        const SizedBox(height: 14),

        _supportButton(),

        const SizedBox(height: 24),

        const Text(
          'DOJO Platform',
          style: TextStyle(
            color: DojoWalkerColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          'Trusted walks. Happy dogs. 🐾',
          style: TextStyle(
            color: DojoWalkerColors.textMuted.withValues(
              alpha: .75,
            ),
            fontSize: 11,
          ),
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  String _pageTitle() {
    if (isApproved) {
      return 'Verification Approved';
    }

    if (isRejected) {
      return 'Verification Needs Attention';
    }

    return 'Verification Pending';
  }

  // ============================================================
  // SUBTITLE
  // ============================================================

  String _pageSubtitle() {
    if (isApproved) {
      return 'Your DOJO Walker account is now active.';
    }

    if (isRejected) {
      return 'Please contact DOJO Platform support for more information.';
    }

    return 'Your profile has been submitted successfully. '
        'We are reviewing your information.';
  }

  // ============================================================
  // VERIFICATION ICON
  // ============================================================

  Widget _verificationIcon() {
    final Color iconColor = isApproved
        ? DojoWalkerColors.success
        : isRejected
            ? DojoWalkerColors.error
            : DojoWalkerColors.info;

    final Color outerColor = isApproved
        ? DojoWalkerColors.success.withValues(alpha: .10)
        : isRejected
            ? DojoWalkerColors.error.withValues(alpha: .10)
            : DojoWalkerColors.info.withValues(alpha: .10);

    if (!isPending) {
      return _staticIcon(
        iconColor: iconColor,
        outerColor: outerColor,
        icon: isApproved
            ? Icons.check_rounded
            : Icons.close_rounded,
      );
    }

    return AnimatedBuilder(
      animation: animationController,
      builder: (
        BuildContext context,
        Widget? child,
      ) {
        final double progress =
            pulseAnimation.value;

        final double ringSize =
            128 + (progress * 32);

        final double opacity =
            (1 - progress) * .28;

        return SizedBox(
          width: 165,
          height: 165,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: ringSize,
                height: ringSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: iconColor.withValues(
                      alpha: opacity,
                    ),
                    width: 3,
                  ),
                ),
              ),

              Container(
                width: 136,
                height: 136,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: outerColor,
                  border: Border.all(
                    color: iconColor.withValues(
                      alpha: .12,
                    ),
                    width: 6,
                  ),
                ),
              ),

              Transform.scale(
                scale: scaleAnimation.value,
                child: Container(
                  width: 94,
                  height: 94,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: iconColor,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(
                          alpha: .20,
                        ),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: DojoWalkerColors.white,
                    size: 45,
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
  // STATIC ICON
  // ============================================================

  Widget _staticIcon({
    required Color iconColor,
    required Color outerColor,
    required IconData icon,
  }) {
    return Container(
      width: 130,
      height: 130,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: outerColor,
        border: Border.all(
          color: iconColor.withValues(alpha: .15),
          width: 7,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: iconColor,
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: .18),
              blurRadius: 20,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: DojoWalkerColors.white,
          size: 50,
        ),
      ),
    );
  }

  // ============================================================
  // MAIN STATUS CARD
  // ============================================================

  Widget _mainStatusCard() {
    final Color color = isApproved
        ? DojoWalkerColors.success
        : isRejected
            ? DojoWalkerColors.error
            : DojoWalkerColors.info;

    final Color light =
        color.withValues(alpha: .08);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DojoWalkerColors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: .12),
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkerColors.black.withValues(
              alpha: .035,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: light,
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                child: Icon(
                  isApproved
                      ? Icons.verified_rounded
                      : isRejected
                          ? Icons.error_outline_rounded
                          : Icons.verified_user_rounded,
                  color: color,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      isApproved
                          ? 'DOJO Platform Verification Approved'
                          : isRejected
                              ? 'Verification Requires Attention'
                              : 'Waiting for DOJO Platform Verification',
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.3,
                        fontWeight:
                            FontWeight.w900,
                        color:
                            DojoWalkerColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      isApproved
                          ? 'Your Walker account is active.'
                          : isRejected
                              ? 'Please contact support.'
                              : 'Verification is currently in progress.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color:
                            DojoWalkerColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: light,
              borderRadius:
                  BorderRadius.circular(13),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Icon(
                  isApproved
                      ? Icons.check_circle_outline_rounded
                      : isRejected
                          ? Icons.error_outline_rounded
                          : Icons.info_outline_rounded,
                  color: color,
                  size: 19,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    isApproved
                        ? 'Your profile has been approved by DOJO Platform. Walker ID activation is complete.'
                        : isRejected
                            ? 'Your submitted profile needs attention. Please contact DOJO Platform support.'
                            : 'DOJO Platform is verifying your profile and submitted documents. Please wait for verification to complete.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.5,
                      color:
                          color.withValues(alpha: .82),
                      fontWeight:
                          FontWeight.w600,
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
  // VERIFICATION STATUS CARD
  // ============================================================

  Widget _statusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DojoWalkerColors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: DojoWalkerColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: DojoWalkerColors.black.withValues(
              alpha: .025,
            ),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Verification Status',
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: DojoWalkerColors.textPrimary,
            ),
          ),

          const SizedBox(height: 18),

          _step(
            icon: Icons.check_circle_rounded,
            color: DojoWalkerColors.success,
            title: 'Profile Submitted',
            subtitle:
                'Completed successfully',
          ),

          _line(),

          _step(
            icon: isApproved
                ? Icons.check_circle_rounded
                : isRejected
                    ? Icons.error_rounded
                    : Icons.verified_user_rounded,
            color: isApproved
                ? DojoWalkerColors.success
                : isRejected
                    ? DojoWalkerColors.error
                    : DojoWalkerColors.info,
            title:
                'DOJO Platform Verification',
            subtitle: isApproved
                ? 'Verification approved'
                : isRejected
                    ? 'Verification requires attention'
                    : 'Waiting for DOJO Platform verification',
            animated: isPending,
          ),

          _line(),

          _step(
            icon: isApproved
                ? Icons.check_circle_rounded
                : Icons.lock_rounded,
            color: isApproved
                ? DojoWalkerColors.success
                : DojoWalkerColors.textMuted,
            title: 'Walker ID Activation',
            subtitle: isApproved
                ? 'Walker ID is active'
                : 'Waiting for DOJO Platform approval',
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STEP
  // ============================================================

  Widget _step({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    bool animated = false,
  }) {
    final Widget baseIcon = Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: color,
        size: 23,
      ),
    );

    final Widget iconWidget = animated
        ? AnimatedBuilder(
            animation: animationController,
            builder: (
              BuildContext context,
              Widget? child,
            ) {
              return Transform.scale(
                scale: 0.94 +
                    (animationController.value *
                        .10),
                child: baseIcon,
              );
            },
          )
        : baseIcon;

    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        iconWidget,

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w900,
                  color:
                      DojoWalkerColors.textPrimary,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.35,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LINE
  // ============================================================

  Widget _line() {
    return Container(
      margin: const EdgeInsets.only(
        left: 20,
        top: 4,
        bottom: 4,
      ),
      width: 2,
      height: 24,
      color: DojoWalkerColors.border,
    );
  }

  // ============================================================
  // NEXT STEP
  // ============================================================

  Widget _nextStepCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: DojoWalkerColors.primary.withValues(
          alpha: .05,
        ),
        borderRadius:
            BorderRadius.circular(19),
        border: Border.all(
          color: DojoWalkerColors.primary.withValues(
            alpha: .10,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                color: DojoWalkerColors.primary,
                size: 22,
              ),

              SizedBox(width: 8),

              Expanded(
                child: Text(
                  'What happens next?',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color:
                        DojoWalkerColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _nextLine(
            'Your profile has been submitted.',
            true,
          ),

          _nextLine(
            'DOJO Platform will verify your information.',
            isApproved,
          ),

          _nextLine(
            'Your Walker ID will activate after approval.',
            isApproved,
          ),

          _nextLine(
            'You can then enter the DOJO Walker app.',
            isApproved,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // NEXT LINE
  // ============================================================

  Widget _nextLine(
    String text,
    bool completed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 2,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            completed ? '✓ ' : '• ',
            style: TextStyle(
              fontSize: 12,
              color: completed
                  ? DojoWalkerColors.success
                  : DojoWalkerColors.textMuted,
              fontWeight: FontWeight.w900,
            ),
          ),

          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.6,
                color: DojoWalkerColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOCKED CARD
  // ============================================================

  Widget _lockedCard() {
    final Color color = isRejected
        ? DojoWalkerColors.error
        : DojoWalkerColors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .07),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: .10),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            isRejected
                ? Icons.error_outline_rounded
                : Icons.lock_outline_rounded,
            color: color,
            size: 21,
          ),

          const SizedBox(width: 9),

          Expanded(
            child: Text(
              isRejected
                  ? 'Walker account needs verification attention. Please contact DOJO Platform support.'
                  : 'Walker account is locked until DOJO Platform verification is completed.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.45,
                color:
                    color.withValues(alpha: .85),
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUPPORT BUTTON
  // ============================================================

  Widget _supportButton() {
    return OutlinedButton.icon(
      onPressed: onSupport,
      style: OutlinedButton.styleFrom(
        minimumSize:
            const Size(
          double.infinity,
          50,
        ),
        foregroundColor:
            DojoWalkerColors.info,
        side: BorderSide(
          color:
              DojoWalkerColors.info.withValues(
            alpha: .25,
          ),
        ),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(15),
        ),
      ),
      icon: const Icon(
        Icons.support_agent_rounded,
        size: 21,
      ),
      label: const Text(
        'Need Help? Contact Support',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
