import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/insta_walk_request.dart';
import 'active_walk_address_card.dart';
import 'active_walk_call_chat.dart';
import 'active_walk_dog_header.dart';
import 'active_walk_live_status.dart';
import 'active_walk_owner_note.dart';
import 'active_walk_reach_slider.dart';
import 'active_walk_stat_card.dart';

class ActiveWalkBottomSheet extends StatelessWidget {
  final ScrollController controller;
  final InstaWalkRequest request;

  final String liveStatus;
  final double distanceKm;
  final int elapsedSeconds;
  final int steps;

  final bool reached;
  final bool starting;

  final VoidCallback onExpand;
  final VoidCallback onToggleSheet;
  final VoidCallback onReached;

  final void Function(String message) onMessage;

  const ActiveWalkBottomSheet({
    super.key,
    required this.controller,
    required this.request,
    required this.liveStatus,
    required this.distanceKm,
    required this.elapsedSeconds,
    required this.steps,
    required this.reached,
    required this.starting,
    required this.onExpand,
    required this.onToggleSheet,
    required this.onReached,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withValues(
              alpha: .16,
            ),
            blurRadius: 25,
            offset: const Offset(0, -7),
          ),
        ],
      ),
      child: ListView(
        controller: controller,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          18,
          9,
          18,
          20,
        ),
        children: [
          // ======================================================
          // DRAG HANDLE
          // ======================================================

          GestureDetector(
            onTap: onToggleSheet,
            child: Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),

          const SizedBox(height: 13),

          // ======================================================
          // HEADER
          // ======================================================

          _activeWalkHeader(),

          const SizedBox(height: 12),

          // ======================================================
          // DOG HEADER
          // ======================================================

          ActiveWalkDogHeader(
            request: request,
            distanceKm: distanceKm,
          ),

          const SizedBox(height: 10),

          // ======================================================
          // LIVE STATUS
          // ======================================================

          ActiveWalkLiveStatus(
            hasLocation:
                request.latitude != null &&
                request.longitude != null,
          ),

          const SizedBox(height: 10),

          // ======================================================
          // ADDRESS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: ActiveWalkAddressCard(
                  icon: Icons.location_on_rounded,
                  title: 'PICKUP',
                  value: _pickupText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ActiveWalkAddressCard(
                  icon: Icons.flag_rounded,
                  title: 'DESTINATION',
                  value: 'Destination location',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ======================================================
          // LIVE STATS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: ActiveWalkStatCard(
                  value: _distanceText,
                  title: 'Distance',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: ActiveWalkStatCard(
                  value: _durationText,
                  title: reached ? 'Status' : 'ETA',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: ActiveWalkStatCard(
                  value: '$steps',
                  title: 'Steps',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ======================================================
          // WALK STATUS
          // ======================================================

          ActiveWalkStatCard(
            value: _walkStatusText,
            title: 'Walk',
          ),

          const SizedBox(height: 10),

          // ======================================================
          // OWNER NOTE
          // ======================================================

          const ActiveWalkOwnerNote(),

          const SizedBox(height: 10),

          // ======================================================
          // CALL / CHAT
          // ======================================================

          ActiveWalkCallChat(
            onCall: _callOwner,
            onChat: () {
              onMessage(
                'Chat will be available soon.',
              );
            },
          ),

          const SizedBox(height: 10),

          // ======================================================
          // REACH OWNER
          // ======================================================

          if (!reached)
            ActiveWalkReachSlider(
              reached: false,
              onReached: onReached,
            ),

          // ======================================================
          // AFTER REACH
          //
          // Start Walk intentionally removed.
          //
          // Start Walk will be handled by the Live Walk screen.
          // ======================================================

          if (reached)
            ActiveWalkReachSlider(
              reached: true,
              onReached: onReached,
            ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIVE WALK HEADER
  // ============================================================

  Widget _activeWalkHeader() {
    return GestureDetector(
      onTap: onExpand,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: AppColors.successSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.success.withValues(
              alpha: .20,
            ),
          ),
        ),
        child: Row(
          children: [
            // ====================================================
            // ICON
            // ====================================================

            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: AppColors.success,
                size: 21,
              ),
            ),

            const SizedBox(width: 10),

            // ====================================================
            // OWNER + DOG
            // ====================================================

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE INSTA WALK',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_ownerNameText • $_dogNameText',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // ====================================================
            // STATUS
            // ====================================================

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                liveStatus.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            const SizedBox(width: 5),

            const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: AppColors.success,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CALL OWNER
  // ============================================================

  Future<void> _callOwner() async {
    final String phone =
        request.ownerPhone.trim();

    if (phone.isEmpty) {
      onMessage(
        'Owner phone number is not available.',
      );
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool available =
          await canLaunchUrl(uri);

      if (!available) {
        onMessage(
          'Unable to open phone dialer.',
        );
        return;
      }

      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      onMessage(
        'Unable to call owner.',
      );
    }
  }

  // ============================================================
  // OWNER NAME
  // ============================================================

  String get _ownerNameText {
    final String value =
        request.ownerName.trim();

    return value.isEmpty
        ? 'Owner'
        : value;
  }

  // ============================================================
  // DOG NAME
  // ============================================================

  String get _dogNameText {
    final String value =
        request.dogName.trim();

    return value.isEmpty
        ? 'Dog'
        : value;
  }

  // ============================================================
  // PICKUP ADDRESS
  // ============================================================

  String get _pickupText {
    final String pickup =
        request.pickupAddress.trim();

    if (pickup.isNotEmpty) {
      return pickup;
    }

    final String address =
        request.address.trim();

    return address.isEmpty
        ? 'Pickup address not available'
        : address;
  }

  // ============================================================
  // DISTANCE
  //
  // This is supplied by ActiveWalkDetailsScreen.
  // It should be calculated from:
  //
  // LIVE WALKER LOCATION
  //          ↓
  // FIXED OWNER REQUEST LOCATION
  //
  // ============================================================

  String get _distanceText {
    if (distanceKm <= 0) {
      return '--';
    }

    if (distanceKm < 1) {
      final int meters =
          (distanceKm * 1000).round();

      return '$meters m';
    }

    return '${distanceKm.toStringAsFixed(1)} km';
  }

  // ============================================================
  // ETA
  //
  // Average walking speed ≈ 5 km/h.
  //
  // This is estimated time to reach the owner.
  // ============================================================

  String get _durationText {
    if (reached) {
      return 'Reached';
    }

    if (distanceKm <= 0) {
      return '--';
    }

    const double walkingSpeedKmPerHour = 5.0;

    final double hours =
        distanceKm /
            walkingSpeedKmPerHour;

    final int minutes =
        (hours * 60).ceil();

    if (minutes <= 1) {
      return '<1 min';
    }

    if (minutes < 60) {
      return '~$minutes min';
    }

    final int hoursPart =
        minutes ~/ 60;

    final int minutesPart =
        minutes % 60;

    if (minutesPart == 0) {
      return '~${hoursPart}h';
    }

    return '~${hoursPart}h ${minutesPart}m';
  }

  // ============================================================
  // WALK STATUS
  // ============================================================

  String get _walkStatusText {
    if (reached) {
      return 'Ready';
    }

    switch (
        liveStatus.trim().toLowerCase()) {
      case 'searching':
        return 'Searching';

      case 'accepted':
        return 'Accepted';

      case 'active':
        return 'Active';

      case 'completed':
        return 'Completed';

      case 'cancelled':
        return 'Cancelled';

      case 'rejected':
        return 'Rejected';

      default:
        return 'Accepted';
    }
  }
}
