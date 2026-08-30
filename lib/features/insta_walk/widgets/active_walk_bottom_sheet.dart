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
          // DOG
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
          // PICKUP / DESTINATION
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
                  value: _destinationText,
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
                  title: reached
                      ? 'Distance'
                      : 'To Owner',
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: ActiveWalkStatCard(
                  value: _etaText,
                  title: reached
                      ? 'Status'
                      : 'ETA',
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
          // STEP 1 — REACH OWNER
          // ======================================================

          if (!reached)
            ActiveWalkReachSlider(
              reached: false,
              starting: starting,
              onReached: onReached,
            ),

          // ======================================================
          // STEP 2 — OWNER REACHED
          //
          // IMPORTANT:
          // Start Walk button yahan intentionally nahi hai.
          //
          // Reach ke baad Live Walk screen par Start Walk hoga.
          // ======================================================

          if (reached)
            ActiveWalkReachSlider(
              reached: true,
              starting: starting,
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
      final bool launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        onMessage(
          'Unable to open phone dialer.',
        );
      }
    } catch (e) {
      debugPrint(
        'Call owner error: $e',
      );

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
  // PICKUP
  //
  // This is the OWNER REQUEST LOCATION.
  // It must remain fixed.
  // ============================================================

  String get _pickupText {
    final String pickup =
        request.pickupAddress.trim();

    if (pickup.isNotEmpty) {
      return pickup;
    }

    final String address =
        request.address.trim();

    if (address.isNotEmpty) {
      return address;
    }

    return _ownerCoordinatesText;
  }

  // ============================================================
  // DESTINATION
  // ============================================================

  String get _destinationText {
    final double? latitude =
        request.latitude;

    final double? longitude =
        request.longitude;

    if (latitude != null &&
        longitude != null &&
        latitude != 0 &&
        longitude != 0) {
      return '${latitude.toStringAsFixed(5)}, '
          '${longitude.toStringAsFixed(5)}';
    }

    return 'Destination not available';
  }

  // ============================================================
  // OWNER COORDINATES FALLBACK
  // ============================================================

  String get _ownerCoordinatesText {
    final double? latitude =
        request.latitude;

    final double? longitude =
        request.longitude;

    if (latitude == null ||
        longitude == null) {
      return 'Pickup location not available';
    }

    if (latitude == 0 ||
        longitude == 0) {
      return 'Pickup location not available';
    }

    return '${latitude.toStringAsFixed(5)}, '
        '${longitude.toStringAsFixed(5)}';
  }

  // ============================================================
  // DISTANCE
  //
  // distanceKm MUST come from:
  //
  // WALKER LIVE LOCATION
  //          ↓
  // FIXED OWNER REQUEST LOCATION
  //
  // It should NOT use the current owner's moving location.
  // ============================================================

  String get _distanceText {
    if (reached) {
      return _formatDistance(distanceKm);
    }

    if (distanceKm <= 0) {
      return '--';
    }

    return _formatDistance(distanceKm);
  }

  // ============================================================
  // DISTANCE FORMAT
  // ============================================================

  String _formatDistance(double km) {
    if (km <= 0) {
      return '--';
    }

    if (km < 1) {
      final int meters =
          (km * 1000).round();

      if (meters <= 0) {
        return '<1 m';
      }

      return '$meters m';
    }

    if (km < 10) {
      return '${km.toStringAsFixed(1)} km';
    }

    return '${km.toStringAsFixed(0)} km';
  }

  // ============================================================
  // ETA
  //
  // ETA = current distance to fixed owner location.
  //
  // Approximate walking speed:
  // 5 km/h
  // ============================================================

  String get _etaText {
    if (reached) {
      return 'Reached';
    }

    if (distanceKm <= 0) {
      return '--';
    }

    const double walkingSpeedKmPerHour =
        5.0;

    final double minutes =
        (distanceKm /
                walkingSpeedKmPerHour) *
            60;

    final int roundedMinutes =
        minutes.ceil();

    if (roundedMinutes <= 1) {
      return '<1 min';
    }

    if (roundedMinutes < 60) {
      return '~$roundedMinutes min';
    }

    final int hours =
        roundedMinutes ~/ 60;

    final int remainingMinutes =
        roundedMinutes % 60;

    if (remainingMinutes == 0) {
      return '~${hours}h';
    }

    return '~${hours}h '
        '${remainingMinutes}m';
  }

  // ============================================================
  // WALK STATUS
  // ============================================================

  String get _walkStatusText {
    if (reached) {
      return 'Reached';
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
