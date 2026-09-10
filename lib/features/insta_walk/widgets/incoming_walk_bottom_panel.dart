import 'package:flutter/material.dart';

import 'incoming_walk_action_buttons.dart';
import 'incoming_walk_address.dart';
import 'incoming_walk_call_chat.dart';
import 'incoming_walk_dog_header.dart';
import 'incoming_walk_reach_button.dart';
import 'incoming_walk_stats.dart';

class IncomingWalkBottomPanel extends StatelessWidget {
  const IncomingWalkBottomPanel({
    super.key,
    required this.dogName,
    required this.dogBreed,
    required this.ownerName,
    required this.ownerPhone,
    required this.distanceText,
    required this.etaText,
    required this.paymentText,
    required this.address,
    required this.accepted,
    required this.canReachOwner,
    required this.onAccept,
    required this.onReject,
    required this.onReach,
    this.onChat,
    this.accepting = false,
    this.rejecting = false,
    this.reaching = false,
  });

  final String dogName;
  final String dogBreed;
  final String ownerName;
  final String ownerPhone;

  final String distanceText;
  final String etaText;
  final String paymentText;
  final String address;

  final bool accepted;
  final bool canReachOwner;

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onReach;

  final VoidCallback? onChat;

  final bool accepting;
  final bool rejecting;
  final bool reaching;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            maxHeight: 500,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 24,
                spreadRadius: 0,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              10,
              18,
              16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // ------------------------------------------------
                // DRAG HANDLE
                // ------------------------------------------------

                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD7DADF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // DOG + OWNER
                // ------------------------------------------------

                IncomingWalkDogHeader(
                  dogName: dogName,
                  dogBreed: dogBreed,
                  ownerName: ownerName,
                ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // WALK INFORMATION
                //
                // ETA IS INTENTIONALLY NOT SHOWN.
                //
                // Existing etaText is retained in the API so
                // existing screen logic does not break.
                // ------------------------------------------------

                _WalkInfoCard(
                  distanceText: distanceText,
                ),

                const SizedBox(height: 12),

                // ------------------------------------------------
                // PICKUP LOCATION
                // ------------------------------------------------

                if (address.trim().isNotEmpty)
                  IncomingWalkAddress(
                    address: address.trim(),
                  ),

                const SizedBox(height: 14),

                // ------------------------------------------------
                // ACTIONS
                // ------------------------------------------------

                if (accepted) ...[
                  IncomingWalkCallChat(
                    ownerPhone: ownerPhone,
                    onChat: onChat,
                  ),

                  const SizedBox(height: 10),

                  IncomingWalkReachButton(
                    canReachOwner: canReachOwner,
                    onReach: onReach,
                    reaching: reaching,
                  ),
                ] else
                  IncomingWalkActionButtons(
                    onAccept: onAccept,
                    onReject: onReject,
                    accepting: accepting,
                    rejecting: rejecting,
                  ),

                const SizedBox(height: 9),

                // ------------------------------------------------
                // STATUS
                // ------------------------------------------------

                _StatusMessage(
                  accepted: accepted,
                  canReachOwner: canReachOwner,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// WALK INFO CARD
// ================================================================

class _WalkInfoCard extends StatelessWidget {
  const _WalkInfoCard({
    required this.distanceText,
  });

  final String distanceText;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EBEF),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: _InfoItem(
              icon: Icons.near_me_rounded,
              label: 'DISTANCE',
              value: distanceText == '—'
                  ? '—'
                  : distanceText,
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: const Color(0xFFE1E4E8),
          ),
          Expanded(
            child: const _InfoItem(
              icon: Icons.schedule_rounded,
              label: 'DURATION',
              value: '—',
            ),
          ),
          Container(
            width: 1,
            height: 34,
            color: const Color(0xFFE1E4E8),
          ),
          const Expanded(
            child: _InfoItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'EARNING',
              value: '—',
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// INFO ITEM
// ================================================================

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(
          icon,
          size: 18,
          color: const Color(0xFFE85D04),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.45,
            color: Color(0xFF747981),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: Color(0xFF202328),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// STATUS MESSAGE
// ================================================================

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.accepted,
    required this.canReachOwner,
  });

  final bool accepted;
  final bool canReachOwner;

  @override
  Widget build(BuildContext context) {
    final String message;

    if (!accepted) {
      message = 'Review the pickup location before accepting.';
    } else if (canReachOwner) {
      message = 'You are within 100 m of the owner.';
    } else {
      message = 'Reach the owner to open Live Walk.';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF8A8F98),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
