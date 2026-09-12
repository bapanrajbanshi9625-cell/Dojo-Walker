import 'package:flutter/material.dart';

import 'accept_walk_address.dart';
import 'accept_walk_call_chat.dart';
import 'accept_walk_owner_dog_details.dart';
import 'accept_walk_reach_button.dart';

class AcceptWalkBottomPanel extends StatefulWidget {
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
  State<AcceptWalkBottomPanel> createState() =>
      _AcceptWalkBottomPanelState();
}

class _AcceptWalkBottomPanelState
    extends State<AcceptWalkBottomPanel> {
  double _dragOffset = 0;
  double _panelHeight = 0;

  static const double _minimumVisibleHeight = 72;

  void _updateDrag(DragUpdateDetails details) {
    if (_panelHeight <= 0) {
      return;
    }

    final double availableDrag =
        _panelHeight - _minimumVisibleHeight;

    if (availableDrag <= 0) {
      return;
    }

    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(
        0.0,
        availableDrag,
      );
    });
  }

  void _endDrag(DragEndDetails details) {
    if (_dragOffset <= 0) {
      return;
    }

    if (_dragOffset < _panelHeight * 0.18) {
      setState(() {
        _dragOffset = 0;
      });
      return;
    }

    if (_dragOffset > _panelHeight * 0.65) {
      setState(() {
        _dragOffset =
            (_panelHeight - _minimumVisibleHeight)
                .clamp(0.0, _panelHeight);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (
          BuildContext context,
          BoxConstraints constraints,
        ) {
          return Transform.translate(
            offset: Offset(0, _dragOffset),
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
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: _updateDrag,
                  onVerticalDragEnd: _endDrag,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      16,
                      12,
                      16,
                      14,
                    ),
                    child: Builder(
                      builder: (BuildContext context) {
                        WidgetsBinding.instance.addPostFrameCallback(
                          (_) {
                            if (!mounted) {
                              return;
                            }

                            final RenderBox? box =
                                context.findRenderObject()
                                    as RenderBox?;

                            if (box == null ||
                                !box.hasSize) {
                              return;
                            }

                            final double height =
                                box.size.height;

                            if (_panelHeight != height) {
                              setState(() {
                                _panelHeight = height;
                                _dragOffset =
                                    _dragOffset.clamp(
                                  0.0,
                                  (height -
                                          _minimumVisibleHeight)
                                      .clamp(
                                    0.0,
                                    height,
                                  ),
                                );
                              });
                            }
                          },
                        );

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Center(
                              child: Container(
                                width: 42,
                                height: 4,
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFFD6D9DD),
                                  borderRadius:
                                      BorderRadius.circular(20),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            AcceptWalkOwnerDogDetails(
                              dogName: widget.dogName,
                              dogBreed: widget.dogBreed,
                              ownerName: widget.ownerName,
                            ),

                            const SizedBox(height: 12),

                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _InfoItem(
                                    icon:
                                        Icons.near_me_rounded,
                                    label: widget.distanceText,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _InfoItem(
                                    icon:
                                        Icons.schedule_rounded,
                                    label: widget.timeText,
                                  ),
                                ),
                              ],
                            ),

                            if (widget.address
                                .trim()
                                .isNotEmpty) ...<Widget>[
                              const SizedBox(height: 10),
                              AcceptWalkAddress(
                                address: widget.address,
                              ),
                            ],

                            const SizedBox(height: 12),

                            AcceptWalkCallChat(
                              ownerPhone: widget.ownerPhone,
                              onChat: widget.onChat,
                            ),

                            const SizedBox(height: 12),

                            AcceptWalkReachButton(
                              canReachOwner:
                                  widget.canReachOwner,
                              reaching: widget.reaching,
                              onReach: widget.onReach,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          );
        },
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
