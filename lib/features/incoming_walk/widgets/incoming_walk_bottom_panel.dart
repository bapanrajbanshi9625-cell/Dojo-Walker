// File:
// lib/features/incoming_walk/widgets/incoming_walk_bottom_panel.dart

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import 'incoming_walk_action_buttons.dart';
import 'incoming_walk_address.dart';
import 'incoming_walk_owner_dog_details.dart';

class IncomingWalkBottomPanel extends StatefulWidget {
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
  State<IncomingWalkBottomPanel> createState() =>
      _IncomingWalkBottomPanelState();
}

class _IncomingWalkBottomPanelState
    extends State<IncomingWalkBottomPanel> {
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  static const double _collapsedSize = 0.24;
  static const double _expandedSize = 0.78;

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  void _snapTo(double size) {
    if (!_sheetController.isAttached) {
      return;
    }

    _sheetController.animateTo(
      size,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize: _collapsedSize,
      minChildSize: _collapsedSize,
      maxChildSize: _expandedSize,
      snap: true,
      snapSizes: const <double>[
        _collapsedSize,
        _expandedSize,
      ],
      snapAnimationDuration:
          const Duration(milliseconds: 260),
      expand: false,
      builder: (
        BuildContext context,
        ScrollController scrollController,
      ) {
        return Material(
          color: Colors.transparent,
          child: Container(
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
              child: CustomScrollView(
                controller: scrollController,
                physics:
                    const ClampingScrollPhysics(),
                slivers: <Widget>[
                  // ==================================================
                  // DRAG HANDLE
                  // ==================================================

                  SliverToBoxAdapter(
                    child: GestureDetector(
                      behavior:
                          HitTestBehavior.opaque,
                      onTap: () {
                        if (!_sheetController.isAttached) {
                          return;
                        }

                        final double current =
                            _sheetController.size;

                        if (current <
                            ((_collapsedSize +
                                    _expandedSize) /
                                2)) {
                          _snapTo(_expandedSize);
                        } else {
                          _snapTo(_collapsedSize);
                        }
                      },
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          10,
                        ),
                        child: Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.grey.shade300,
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // OWNER + DOG
                  // ==================================================

                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child:
                          IncomingWalkOwnerDogDetails(
                        dogName: widget.dogName,
                        dogBreed: widget.dogBreed,
                        ownerName:
                            widget.ownerName,
                      ),
                    ),
                  ),

                  // ==================================================
                  // DETAILS
                  // ==================================================

                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      16,
                    ),
                    sliver:
                        SliverToBoxAdapter(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: <Widget>[
                          // ==================================================
                          // DISTANCE / TIME / PAYMENT
                          // ==================================================

                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _InfoItem(
                                  icon: Icons
                                      .location_on_outlined,
                                  label:
                                      'Distance',
                                  value:
                                      widget
                                          .distanceText,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: _InfoItem(
                                  icon: Icons
                                      .access_time,
                                  label: 'Time',
                                  value:
                                      widget.etaText,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: _InfoItem(
                                  icon: Icons
                                      .payments_outlined,
                                  label:
                                      'Payment',
                                  value:
                                      widget
                                          .paymentText,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ==================================================
                          // ADDRESS
                          // ==================================================

                          IncomingWalkAddress(
                            address:
                                widget.address,
                          ),

                          const SizedBox(
                            height: 14,
                          ),

                          // ==================================================
                          // ACTION BUTTONS
                          // ==================================================

                          IncomingWalkActionButtons(
                            onAccept:
                                widget.onAccept,
                            onReject:
                                widget.onReject,
                            accepting:
                                widget.accepting,
                            rejecting:
                                widget.rejecting,
                          ),

                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color:
            DojoWalkerColors.primary.withValues(
          alpha: 0.06,
        ),
        borderRadius:
            BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color:
                DojoWalkerColors.primary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color:
                  Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
