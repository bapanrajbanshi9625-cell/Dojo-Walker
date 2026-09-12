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
  double _dragOffset = 0;

  static const double _headerHeight = 184;
  static const double _collapsedContentHeight = 0;

  void _updateDrag(DragUpdateDetails details) {
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(
        0.0,
        500.0,
      );
    });
  }

  void _endDrag(DragEndDetails details) {
    if (_dragOffset > 90) {
      setState(() {
        _dragOffset = 500.0;
      });
    } else {
      setState(() {
        _dragOffset = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // ==================================================
              // FIXED HEADER
              // ==================================================
              SizedBox(
                height: _headerHeight,
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragUpdate: _updateDrag,
                      onVerticalDragEnd: _endDrag,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          16,
                          12,
                          16,
                          12,
                        ),
                        child: Center(
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
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      child: IncomingWalkOwnerDogDetails(
                        dogName: widget.dogName,
                        dogBreed: widget.dogBreed,
                        ownerName: widget.ownerName,
                      ),
                    ),
                  ],
                ),
              ),

              // ==================================================
              // SCROLLABLE / COLLAPSIBLE CONTENT
              // ==================================================
              ClipRect(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  height: (_dragOffset > 0)
                      ? _collapsedContentHeight
                      : null,
                  child: _dragOffset > 0
                      ? const SizedBox.shrink()
                      : SingleChildScrollView(
                          physics:
                              const ClampingScrollPhysics(),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              12,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 12),

                                Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons
                                            .location_on_outlined,
                                        label: 'Distance',
                                        value:
                                            widget.distanceText,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons
                                            .access_time,
                                        label: 'Time',
                                        value:
                                            widget.etaText,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: _InfoItem(
                                        icon: Icons
                                            .payments_outlined,
                                        label: 'Payment',
                                        value:
                                            widget.paymentText,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                IncomingWalkAddress(
                                  address: widget.address,
                                ),

                                const SizedBox(height: 14),

                                IncomingWalkActionButtons(
                                  onAccept: widget.onAccept,
                                  onReject: widget.onReject,
                                  accepting: widget.accepting,
                                  rejecting: widget.rejecting,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
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
