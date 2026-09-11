import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import 'accept_walk_address.dart';
import 'accept_walk_call_chat.dart';
import 'accept_walk_dog_header.dart';
import 'accept_walk_reach_button.dart';

class AcceptWalkBottomPanel extends StatelessWidget {
  const AcceptWalkBottomPanel({
    super.key,
    required this.dogName,
    required this.dogBreed,
    required this.ownerName,
    required this.ownerPhone,
    required this.distanceText,
    required this.timeText,
    required this.address,
    required this.canReachOwner,
    required this.reaching,
    required this.onReach,
  });

  final String dogName;
  final String dogBreed;
  final String ownerName;
  final String ownerPhone;

  final String distanceText;
  final String timeText;
  final String address;

  final bool canReachOwner;
  final bool reaching;

  final VoidCallback onReach;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: 18,
              offset: const Offset(0, -5),
              color: Colors.black.withValues(alpha: 0.14),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  AcceptWalkDogHeader(
                    dogName: dogName,
                    dogBreed: dogBreed,
                    ownerName: ownerName,
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Expanded(
                        child: _TravelInfo(
                          icon: Icons.location_on_outlined,
                          value: distanceText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TravelInfo(
                          icon: Icons.access_time,
                          value: timeText,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  AcceptWalkAddress(
                    address: address,
                  ),

                  const SizedBox(height: 10),

                  AcceptWalkCallChat(
                    ownerPhone: ownerPhone,
                    onChat: () {
                      // Chat implementation remains connected
                      // through the existing communication flow.
                    },
                  ),

                  const SizedBox(height: 10),

                  AcceptWalkReachButton(
                    canReachOwner: canReachOwner,
                    reaching: reaching,
                    onReach: onReach,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TravelInfo extends StatelessWidget {
  const _TravelInfo({
    required this.icon,
    required this.value,
  });

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: DojoWalkerColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: DojoWalkerColors.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
