import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/insta_walk_request.dart';

class IncomingWalkBottomSheet extends StatelessWidget {
  final InstaWalkRequest request;

  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String address;

  final String distanceText;
  final String etaText;
  final String paymentText;

  final bool accepted;
  final bool accepting;
  final bool rejecting;
  final bool reaching;
  final bool canReachOwner;

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onReachOwner;

  const IncomingWalkBottomSheet({
    super.key,
    required this.request,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    required this.address,
    required this.distanceText,
    required this.etaText,
    required this.paymentText,
    required this.accepted,
    required this.accepting,
    required this.rejecting,
    required this.reaching,
    required this.canReachOwner,
    required this.onAccept,
    required this.onReject,
    required this.onReachOwner,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          constraints: const BoxConstraints(
            maxHeight: 440,
          ),
          padding: const EdgeInsets.fromLTRB(
            18,
            12,
            18,
            14,
          ),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.overlay.withValues(
                  alpha: 0.18,
                ),
                blurRadius: 28,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // =================================================
                // HANDLE
                // =================================================

                Container(
                  width: 46,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 14),

                // =================================================
                // REQUEST LABEL
                // =================================================

                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INCOMING WALK',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'New walk request from nearby',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(),
                  ],
                ),

                const SizedBox(height: 14),

                // =================================================
                // DOG / OWNER
                // =================================================

                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: 0.10,
                        ),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.pets_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            dogName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            dogBreed.isEmpty
                                ? ownerName
                                : '$dogBreed • $ownerName',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 13),

                // =================================================
                // STATS
                // =================================================

                Row(
                  children: [
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.near_me_rounded,
                        value: distanceText,
                        label: 'DISTANCE',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.schedule_rounded,
                        value: etaText,
                        label: 'ETA',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoCard(
                        icon: Icons.payments_rounded,
                        value: paymentText,
                        label: 'PAYMENT',
                      ),
                    ),
                  ],
                ),

                if (address.isNotEmpty) ...[
                  const SizedBox(height: 10),

                  // =================================================
                  // ADDRESS
                  // =================================================

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: 0.10,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // =================================================
                // ACTIONS
                // =================================================

                if (accepted)
                  _buildReachButton()
                else
                  _buildAcceptRejectButtons(),

                const SizedBox(height: 7),

                Text(
                  accepted
                      ? canReachOwner
                          ? 'You are within 100 m of the owner.'
                          : 'Reach the owner to continue to Live Walk.'
                      : 'Review the location before accepting.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // STATUS BADGE
  // =============================================================

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: accepted
            ? AppColors.successSoft
            : AppColors.primary.withValues(
                alpha: 0.10,
              ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        accepted ? 'ACCEPTED' : 'NEW',
        style: TextStyle(
          color: accepted
              ? AppColors.success
              : AppColors.primary,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  // =============================================================
  // ACCEPT / REJECT
  // =============================================================

  Widget _buildAcceptRejectButtons() {
    final bool disabled = accepting || rejecting;

    return Row(
      children: [
        Expanded(
          flex: 5,
          child: SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: disabled ? null : onReject,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: BorderSide(
                  color: AppColors.error.withValues(
                    alpha: 0.65,
                  ),
                  width: 1.3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: rejecting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'REJECT',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 7,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: disabled ? null : onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.buttonPrimary,
                foregroundColor: AppColors.buttonText,
                disabledBackgroundColor: AppColors.border,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: accepting
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          AppColors.buttonText,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_rounded,
                          size: 21,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'ACCEPT WALK',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  // =============================================================
  // REACH OWNER
  // =============================================================

  Widget _buildReachButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: canReachOwner && !reaching
            ? onReachOwner
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: AppColors.buttonText,
          disabledBackgroundColor: AppColors.border,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: reaching
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(
                    AppColors.buttonText,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    canReachOwner
                        ? Icons.location_on_rounded
                        : Icons.directions_walk_rounded,
                    size: 21,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    canReachOwner
                        ? 'REACHED OWNER'
                        : 'REACH OWNER',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ===============================================================
// INFO CARD
// ===============================================================

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _InfoCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 7,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
