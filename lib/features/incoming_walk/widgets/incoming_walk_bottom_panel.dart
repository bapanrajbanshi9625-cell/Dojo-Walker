// File:
// lib/features/incoming_walk/widgets/incoming_walk_bottom_panel.dart

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import 'incoming_walk_action_buttons.dart';
import 'incoming_walk_address.dart';
import 'incoming_walk_owner_dog_details.dart';

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
    required this.onAccept,
    required this.onReject,
    required this.accepting,
    required this.rejecting,
  });

  final String dogName;
  final String dogBreed;
  final String ownerName;
  final String ownerPhone;

  final String distanceText;
  final String etaText;
  final String paymentText;
  final String address;

  final VoidCallback onAccept;
  final VoidCallback onReject;

  final bool accepting;
  final bool rejecting;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.24,
      minChildSize: 0.24,
      maxChildSize: 0.78,

      // Same snap-style behaviour.
      snap: true,
      snapSizes: const <double>[
        0.24,
        0.78,
      ],
      snapAnimationDuration:
          const Duration(milliseconds: 260),

      // Let the sheet behave naturally with the
      // ListView scroll controller.
      expand: false,

      builder: (
        BuildContext context,
        ScrollController scrollController,
      ) {
        return Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(24),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                blurRadius: 18,
                offset: Offset(0, -5),
                color: Color(0x1F000000),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            bottom: true,
            child: ListView(
              controller: scrollController,

              // Same scrolling pattern as LiveWalkBottomSheet.
              physics: const ClampingScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                28,
              ),

              children: <Widget>[
                // ==================================================
                // DRAG HANDLE
                // ==================================================

                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ==================================================
                // OWNER + DOG
                // ==================================================

                IncomingWalkOwnerDogDetails(
                  dogName: dogName,
                  dogBreed: dogBreed,
                  ownerName: ownerName,
                ),

                const SizedBox(height: 18),

                // ==================================================
                // DISTANCE / TIME / PAYMENT
                // ==================================================

                Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: _InfoItem(
                        icon:
                            Icons.location_on_outlined,
                        label: 'Distance',
                        value: distanceText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoItem(
                        icon: Icons.access_time,
                        label: 'Time',
                        value: etaText,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _InfoItem(
                        icon:
                            Icons.payments_outlined,
                        label: 'Payment',
                        value: paymentText,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ==================================================
                // ADDRESS
                // ==================================================

                IncomingWalkAddress(
                  address: address,
                ),

                const SizedBox(height: 18),

                // ==================================================
                // ACCEPT / REJECT
                // ==================================================

                IncomingWalkActionButtons(
                  onAccept: onAccept,
                  onReject: onReject,
                  accepting: accepting,
                  rejecting: rejecting,
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: DojoWalkerColors.primary.withValues(
          alpha: 0.06,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color: DojoWalkerColors.primary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
