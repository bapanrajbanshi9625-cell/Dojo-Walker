// File:
// lib/features/accept_walk/widgets/accept_walk_bottom_panel.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
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
    required this.ownerLocation,
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

  /// Exact owner pickup coordinates.
  final LatLng? ownerLocation;

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
  final DraggableScrollableController
      _sheetController =
      DraggableScrollableController();

  static const double _collapsedSize = 0.12;
  static const double _expandedSize = 0.78;

  // ============================================================
  // SHEET TOGGLE
  // ============================================================

  Future<void> _toggleSheet() async {
    if (!_sheetController.isAttached) {
      return;
    }

    final double currentSize =
        _sheetController.size;

    final double target =
        currentSize >
                ((_collapsedSize +
                        _expandedSize) /
                    2)
            ? _collapsedSize
            : _expandedSize;

    await _sheetController.animateTo(
      target,
      duration:
          const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  // ============================================================
  // EXACT PICKUP MAP
  // ============================================================

  Future<void> _openMap() async {
    final LatLng? location =
        widget.ownerLocation;

    if (location == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Pickup location is unavailable.',
            ),
          ),
        );
      return;
    }

    // Google Maps opens directly at the owner's
    // exact pickup latitude/longitude.
    final Uri googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=${location.latitude},${location.longitude}',
    );

    try {
      final bool opened =
          await launchUrl(
        googleMapsUri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Unable to open Google Maps.',
              ),
            ),
          );
      }
    } catch (error) {
      debugPrint(
        'Open pickup map error: $error',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to open Google Maps.',
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
    return DraggableScrollableSheet(
      controller: _sheetController,
      initialChildSize:
          _collapsedSize,
      minChildSize:
          _collapsedSize,
      maxChildSize:
          _expandedSize,
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
            decoration:
                const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(
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
              child: CustomScrollView(
                controller:
                    scrollController,
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
                      onTap: _toggleSheet,
                      child: SizedBox(
                        height: 38,
                        width: double.infinity,
                        child: Center(
                          child: Container(
                            width: 42,
                            height: 4,
                            decoration:
                                BoxDecoration(
                              color: const Color(
                                0xFFD6D9DD,
                              ),
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
                  // CONTENT
                  // ==================================================

                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      18,
                    ),
                    sliver:
                        SliverList(
                      delegate:
                          SliverChildListDelegate(
                        <Widget>[
                          // ------------------------------------------------
                          // OWNER + DOG
                          // ------------------------------------------------

                          AcceptWalkOwnerDogDetails(
                            dogName:
                                widget.dogName,
                            dogBreed:
                                widget.dogBreed,
                            ownerName:
                                widget.ownerName,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ------------------------------------------------
                          // DISTANCE + TIME
                          // ------------------------------------------------

                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _InfoItem(
                                  icon: Icons
                                      .near_me_rounded,
                                  label:
                                      widget.distanceText,
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              Expanded(
                                child: _InfoItem(
                                  icon: Icons
                                      .schedule_rounded,
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
                            const SizedBox(
                              height: 10,
                            ),
                            AcceptWalkAddress(
                              address:
                                  widget.address,
                            ),
                          ],

                          const SizedBox(
                            height: 12,
                          ),

                          // ------------------------------------------------
                          // MAP
                          // ------------------------------------------------

                          SizedBox(
                            height: 46,
                            child:
                                OutlinedButton.icon(
                              onPressed:
                                  widget.ownerLocation ==
                                          null
                                      ? null
                                      : _openMap,
                              icon: const Icon(
                                Icons
                                    .navigation_rounded,
                                size: 21,
                              ),
                              label:
                                  const Text(
                                'Map',
                                style:
                                    TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                      FontWeight
                                          .w700,
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
                                side:
                                    BorderSide(
                                  color: widget
                                              .ownerLocation ==
                                          null
                                      ? const Color(
                                          0xFFE0E0E0,
                                        )
                                      : const Color(
                                          0xFFE86100,
                                        ),
                                  width: 1.3,
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

                          const SizedBox(
                            height: 12,
                          ),

                          // ------------------------------------------------
                          // CALL + CHAT
                          // ------------------------------------------------

                          AcceptWalkCallChat(
                            ownerPhone:
                                widget.ownerPhone,
                            onChat:
                                widget.onChat,
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          // ------------------------------------------------
                          // REACH OWNER
                          // ------------------------------------------------

                          AcceptWalkReachButton(
                            canReachOwner:
                                widget
                                    .canReachOwner,
                            reaching:
                                widget.reaching,
                            onReach:
                                widget.onReach,
                          ),

                          const SizedBox(
                            height: 8,
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

  @override
  void dispose() {
    _sheetController.dispose();
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
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F8FA),
        borderRadius:
            BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFFE7E9EC),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: 18,
            color:
                const Color(0xFF6B7280),
          ),
          const SizedBox(
            width: 7,
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.w700,
                color:
                    Color(0xFF252A31),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
