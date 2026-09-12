// File:
// lib/features/accept_walk/widgets/accept_walk_bottom_panel.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const double _minimumVisibleHeight = 72;
  static const double _topHandleArea = 36;

  double _dragOffset = 0;

  final ScrollController _scrollController =
      ScrollController();

  bool _draggingPanel = false;

  // ============================================================
  // PANEL DRAG
  // ============================================================

  void _updatePanelDrag(
    DragUpdateDetails details,
    double maxDrag,
  ) {
    if (!_draggingPanel) {
      return;
    }

    final double nextOffset =
        (_dragOffset + details.delta.dy)
            .clamp(0.0, maxDrag);

    if (nextOffset != _dragOffset) {
      setState(() {
        _dragOffset = nextOffset;
      });
    }
  }

  void _endPanelDrag(
    DragEndDetails details,
    double maxDrag,
  ) {
    if (!_draggingPanel) {
      return;
    }

    _draggingPanel = false;

    final double midpoint =
        maxDrag > 0 ? maxDrag * 0.35 : 0;

    setState(() {
      _dragOffset =
          _dragOffset > midpoint ? maxDrag : 0;
    });
  }

  void _startPanelDrag() {
    _draggingPanel = true;
  }

  // ============================================================
  // MAP
  // ============================================================

  Future<void> _openMap() async {
    final String address =
        widget.address.trim();

    if (address.isEmpty) {
      return;
    }

    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );

    try {
      final bool opened = await launchUrl(
        googleMapsUri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open Google Maps',
            ),
          ),
        );
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open Google Maps',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double screenHeight =
        MediaQuery.sizeOf(context).height;

    // ----------------------------------------------------------
    // Panel occupies a comfortable portion of the screen.
    // The inner content itself becomes scrollable.
    // ----------------------------------------------------------

    final double panelHeight =
        (screenHeight * 0.72)
            .clamp(300.0, 620.0);

    final double maxDrag =
        (panelHeight - _minimumVisibleHeight)
            .clamp(0.0, panelHeight);

    final double visibleHeight =
        (panelHeight - _dragOffset)
            .clamp(
              _minimumVisibleHeight,
              panelHeight,
            );

    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: Offset(0, _dragOffset),
          child: Container(
            width: double.infinity,
            height: panelHeight,
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
              child: Column(
                children: <Widget>[
                  // ==================================================
                  // DRAG HANDLE
                  // ==================================================

                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragStart: (_) {
                      _startPanelDrag();
                    },
                    onVerticalDragUpdate: (details) {
                      _updatePanelDrag(
                        details,
                        maxDrag,
                      );
                    },
                    onVerticalDragEnd: (details) {
                      _endPanelDrag(
                        details,
                        maxDrag,
                      );
                    },
                    child: SizedBox(
                      height: _topHandleArea,
                      width: double.infinity,
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFD6D9DD,
                            ),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // ==================================================
                  // SCROLLABLE CONTENT
                  // ==================================================

                  Expanded(
                    child: ClipRect(
                      child: SizedBox(
                        height: visibleHeight,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          physics:
                              const BouncingScrollPhysics(),
                          padding:
                              const EdgeInsets.fromLTRB(
                            16,
                            0,
                            16,
                            18,
                          ),
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min,
                            crossAxisAlignment:
                                CrossAxisAlignment.stretch,
                            children: <Widget>[
                              // ------------------------------------------------
                              // OWNER + DOG
                              // ------------------------------------------------

                              AcceptWalkOwnerDogDetails(
                                dogName: widget.dogName,
                                dogBreed: widget.dogBreed,
                                ownerName: widget.ownerName,
                              ),

                              const SizedBox(height: 12),

                              // ------------------------------------------------
                              // DISTANCE + TIME
                              // ------------------------------------------------

                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: _InfoItem(
                                      icon:
                                          Icons.near_me_rounded,
                                      label:
                                          widget.distanceText,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _InfoItem(
                                      icon:
                                          Icons.schedule_rounded,
                                      label:
                                          widget.timeText,
                                    ),
                                  ),
                                ],
                              ),

                              // ------------------------------------------------
                              // ADDRESS
                              // ------------------------------------------------

                              if (widget.address
                                  .trim()
                                  .isNotEmpty) ...<Widget>[
                                const SizedBox(height: 10),
                                AcceptWalkAddress(
                                  address:
                                      widget.address,
                                ),
                              ],

                              const SizedBox(height: 12),

                              // ------------------------------------------------
                              // MAP BUTTON
                              // ------------------------------------------------

                              SizedBox(
                                height: 46,
                                child:
                                    OutlinedButton.icon(
                                  onPressed:
                                      widget.address
                                              .trim()
                                              .isEmpty
                                          ? null
                                          : _openMap,
                                  icon: const Icon(
                                    Icons.map_rounded,
                                    size: 20,
                                  ),
                                  label: const Text(
                                    'Map',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight:
                                          FontWeight.w700,
                                    ),
                                  ),
                                  style:
                                      OutlinedButton
                                          .styleFrom(
                                    foregroundColor:
                                        const Color(
                                      0xFFE86100,
                                    ),
                                    disabledForegroundColor:
                                        const Color(
                                      0xFFBDBDBD,
                                    ),
                                    side: BorderSide(
                                      color: widget.address
                                              .trim()
                                              .isEmpty
                                          ? const Color(
                                              0xFFE0E0E0,
                                            )
                                          : const Color(
                                              0xFFE86100,
                                            ),
                                    ),
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        12,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // ------------------------------------------------
                              // CALL + CHAT
                              // ------------------------------------------------

                              AcceptWalkCallChat(
                                ownerPhone:
                                    widget.ownerPhone,
                                onChat:
                                    widget.onChat,
                              ),

                              const SizedBox(height: 12),

                              // ------------------------------------------------
                              // REACH OWNER
                              // ------------------------------------------------

                              AcceptWalkReachButton(
                                canReachOwner:
                                    widget.canReachOwner,
                                reaching:
                                    widget.reaching,
                                onReach:
                                    widget.onReach,
                              ),

                              const SizedBox(height: 8),
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
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// ================================================================
// INFO ITEM
// ================================================================

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
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFE7E9EC),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
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
              overflow:
                  TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w700,
                color: Color(0xFF252A31),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
