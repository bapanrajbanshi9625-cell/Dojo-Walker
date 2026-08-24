// File:
// lib/features/insta_walk/widgets/insta_walk_request_card.dart

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../models/insta_walk_request.dart';

class InstaWalkRequestCard extends StatelessWidget {
  final InstaWalkRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const InstaWalkRequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.overlay.withOpacity(.055),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.pets_rounded,
                  color: AppColors.primary,
                  size: 23,
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'INSTA WALK REQUEST',
                      style: TextStyle(
                        color: AppColors.textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _title(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successSoft,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  'NEW',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          // ======================================================
          // PICKUP LOCATION
          // ======================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceSoft,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.success,
                  size: 18,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    _pickupAddress(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 9),

          // ======================================================
          // QUICK INFO
          // ======================================================

          Row(
            children: [
              Expanded(
                child: _info(
                  Icons.route_rounded,
                  '${request.distanceKm.toStringAsFixed(1)} km',
                  'Distance',
                ),
              ),

              const SizedBox(width: 7),

              Expanded(
                child: _info(
                  Icons.access_time_rounded,
                  _estimatedTime(),
                  'Estimated',
                ),
              ),
            ],
          ),

          const SizedBox(height: 11),

          // ======================================================
          // ACTION BUTTONS
          // ======================================================

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 43,
                  child: OutlinedButton(
                    onPressed: onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: BorderSide(
                        color: AppColors.error.withOpacity(.25),
                      ),
                      backgroundColor: AppColors.errorSoft,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Reject',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 9),

              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 43,
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: AppColors.buttonText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.buttonText,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Accept Walk',
                          style: TextStyle(
                            color: AppColors.buttonText,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TITLE
  // ============================================================

  String _title() {
    final String owner = request.ownerName.trim();
    final String dog = request.dogName.trim();

    if (owner.isNotEmpty && dog.isNotEmpty) {
      return '$owner • $dog';
    }

    if (dog.isNotEmpty) {
      return dog;
    }

    if (owner.isNotEmpty) {
      return owner;
    }

    return 'Nearby walk request';
  }

  // ============================================================
  // PICKUP
  // ============================================================

  String _pickupAddress() {
    final String address = request.pickupAddress.trim();

    if (address.isEmpty) {
      return 'Pickup location';
    }

    return address;
  }

  // ============================================================
  // ESTIMATED TIME
  // ============================================================

  String _estimatedTime() {
    final int minutes = request.durationMinutes;

    if (minutes <= 0) {
      return '--';
    }

    if (minutes == 1) {
      return '1 min';
    }

    return '$minutes min';
  }

  // ============================================================
  // INFO BOX
  // ============================================================

  static Widget _info(
    IconData icon,
    String value,
    String label,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.info,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textDark,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
