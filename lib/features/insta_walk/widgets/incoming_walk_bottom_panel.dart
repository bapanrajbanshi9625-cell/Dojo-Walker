import 'package:flutter/material.dart';

import 'incoming_walk_action_buttons.dart';
import 'incoming_walk_address.dart';
import 'incoming_walk_dog_header.dart';
import 'incoming_walk_reach_button.dart';
import 'incoming_walk_stats.dart';

class IncomingWalkBottomPanel extends StatelessWidget {
  const IncomingWalkBottomPanel({
    super.key,
    required this.dogName,
    required this.dogBreed,
    required this.ownerName,
    required this.distanceText,
    required this.etaText,
    required this.paymentText,
    required this.address,
    required this.accepted,
    required this.canReachOwner,
    required this.onAccept,
    required this.onReject,
    required this.onReach,
    this.accepting = false,
    this.rejecting = false,
    this.reaching = false,
  });

  final String dogName;
  final String dogBreed;
  final String ownerName;

  final String distanceText;
  final String etaText;
  final String paymentText;
  final String address;

  final bool accepted;
  final bool canReachOwner;

  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onReach;

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
            maxHeight: 455,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black26,
                blurRadius: 25,
                offset: Offset(0, -7),
              ),
            ],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              18,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 15),

                IncomingWalkDogHeader(
                  dogName: dogName,
                  dogBreed: dogBreed,
                  ownerName: ownerName,
                ),

                const SizedBox(height: 14),

                IncomingWalkStats(
                  distanceText: distanceText,
                  etaText: etaText,
                  paymentText: paymentText,
                ),

                if (address.trim().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  IncomingWalkAddress(
                    address: address,
                  ),
                ],

                const SizedBox(height: 14),

                if (accepted)
                  IncomingWalkReachButton(
                    canReachOwner: canReachOwner,
                    onReach: onReach,
                    reaching: reaching,
                  )
                else
                  IncomingWalkActionButtons(
                    onAccept: onAccept,
                    onReject: onReject,
                    accepting: accepting,
                    rejecting: rejecting,
                  ),

                const SizedBox(height: 7),

                Text(
                  accepted
                      ? canReachOwner
                          ? 'You are within 100 m of the owner.'
                          : 'Reach the owner to open Live Walk.'
                      : 'Review the location before accepting.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black45,
                    fontSize: 11,
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
}
