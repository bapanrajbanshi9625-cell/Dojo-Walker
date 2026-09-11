import 'package:flutter/material.dart';

import 'accept_walk_address.dart';
import 'accept_walk_call_chat.dart';
import 'accept_walk_owner_dog_details.dart';
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
    required this.onChat,
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
  final VoidCallback onChat;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              blurRadius: 18,
              offset: Offset(0, -5),
              color: Color(0x22000000),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              14,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6D9DD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                AcceptWalkOwnerDogDetails(
                  dogName: dogName,
                  dogBreed: dogBreed,
                  ownerName: ownerName,
                ),

                const SizedBox(height: 12),

                Row(
                  children: <Widget>[
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.near_me_rounded,
                        label: distanceText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.schedule_rounded,
                        label: timeText,
                      ),
                    ),
                  ],
                ),

                if (address.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  AcceptWalkAddress(
                    address: address,
                  ),
                ],

                const SizedBox(height: 12),

                AcceptWalkCallChat(
                  ownerPhone: ownerPhone,
                  onChat: onChat,
                ),

                const SizedBox(height: 12),

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
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE7E9EC),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF6B7280),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF252A31),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
