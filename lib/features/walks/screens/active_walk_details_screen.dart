import 'package:flutter/material.dart';

import '../models/walk_request.dart';
import '../widgets/fake_map.dart';
import '../widgets/floating_start_walk_button.dart';

class ActiveWalkDetailsScreen
    extends StatelessWidget {
  final WalkRequest request;

  /// Existing Live Walk screen को यहां connect करें.
  final VoidCallback? onStartWalk;

  const ActiveWalkDetailsScreen({
    super.key,
    required this.request,
    this.onStartWalk,
  });

  static const Color orange =
      Color(0xFFFF6600);

  static const Color blue =
      Color(0xFF238EAE);

  static const Color green =
      Color(0xFF16A34A);

  static const Color greenLight =
      Color(0xFFEAF7EF);

  static const Color dark =
      Color(0xFF263746);

  static const Color muted =
      Color(0xFF7A8289);

  static const Color background =
      Color(0xFFF5F6F8);

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed:
              () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: dark,
          ),
        ),
        title: const Text(
          'Active Walk',
          style: TextStyle(
            color: dark,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: dark,
            ),
            onSelected: (value) {
              if (value == 'cancel') {
                _showCancelDialog(
                  context,
                );
              }
            },
            itemBuilder:
                (context) => const [
              PopupMenuItem(
                value: 'cancel',
                child: Row(
                  children: [
                    Icon(
                      Icons.cancel_outlined,
                      color: dark,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Cancel Walk',
                    ),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      color: dark,
                      size: 19,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Report',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: Stack(
        children: [
          ListView(
            padding:
                const EdgeInsets.only(
              bottom: 105,
            ),
            children: [
              const SizedBox(height: 16),

              // =================================================
              // STATUS
              // =================================================

              Padding(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                child: Align(
                  alignment:
                      Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration:
                        BoxDecoration(
                      color: greenLight,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize:
                          MainAxisSize.min,
                      children: [
                        Icon(
                          Icons
                              .check_circle_rounded,
                          color: green,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'WALK ACCEPTED',
                          style: TextStyle(
                            color: green,
                            fontSize: 10,
                            fontWeight:
                                FontWeight.w900,
                            letterSpacing: .4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // =================================================
              // MAP
              // =================================================

              Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                height: 255,
                decoration:
                    BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                  color:
                      const Color(0xFFE7EEF0),
                  border: Border.all(
                    color:
                        const Color(0xFFD6E0E2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withOpacity(.08),
                      blurRadius: 16,
                      offset:
                          const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius:
                      BorderRadius.circular(
                    22,
                  ),
                  child: Stack(
                    children: [
                      const FakeMap(),

                      const Positioned(
                        left: 110,
                        top: 100,
                        child: MapMarker(
                          icon:
                              Icons.pets_rounded,
                          color: orange,
                        ),
                      ),

                      const Positioned(
                        right: 95,
                        bottom: 70,
                        child: MapMarker(
                          icon: Icons
                              .directions_walk_rounded,
                          color: blue,
                        ),
                      ),

                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration:
                              BoxDecoration(
                            color: Colors.white
                                .withOpacity(.94),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons
                                    .map_outlined,
                                size: 15,
                                color: dark,
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Text(
                                'PICKUP MAP',
                                style:
                                    TextStyle(
                                  color: dark,
                                  fontSize: 9,
                                  fontWeight:
                                      FontWeight
                                          .w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // =================================================
              // NAVIGATION
              // =================================================

              Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                ),
                height: 56,
                decoration:
                    BoxDecoration(
                  color: blue,
                  borderRadius:
                      BorderRadius.circular(
                    16,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withOpacity(
                        .25,
                      ),
                      blurRadius: 12,
                      offset:
                          const Offset(0, 5),
                    ),
                  ],
                ),
                child: Material(
                  color:
                      Colors.transparent,
                  child: InkWell(
                    borderRadius:
                        BorderRadius.circular(
                      16,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Navigation will open after Google Maps is connected.',
                          ),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Icon(
                          Icons
                              .navigation_rounded,
                          color:
                              Colors.white,
                          size: 21,
                        ),
                        SizedBox(width: 9),
                        Text(
                          'Navigation',
                          style: TextStyle(
                            color:
                                Colors.white,
                            fontSize: 14,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),
                        SizedBox(width: 7),
                        Icon(
                          Icons
                              .arrow_forward_rounded,
                          color:
                              Colors.white,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // OWNER + DOG
              // =================================================

              _sectionTitle(
                'Owner & Dog',
              ),

              _card(
                child: Column(
                  children: [
                    _personRow(
                      Icons.person_rounded,
                      blue,
                      request.ownerName,
                      'Dog Owner',
                    ),

                    const SizedBox(height: 14),

                    const Divider(
                      height: 1,
                      color:
                          Color(0xFFE9ECEE),
                    ),

                    const SizedBox(height: 14),

                    _personRow(
                      Icons.pets_rounded,
                      green,
                      request.dogName,
                      '${request.dogBreed} • ${request.dogAge}',
                    ),

                    const SizedBox(height: 15),

                    // =========================================
                    // PRIMARY CALL + CHAT
                    // =========================================

                    Row(
                      children: [
                        Expanded(
                          child:
                              _primaryButton(
                            icon:
                                Icons.call_rounded,
                            label: 'Call',
                            color: green,
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child:
                              _primaryButton(
                            icon: Icons
                                .chat_bubble_rounded,
                            label: 'Chat',
                            color: blue,
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // PICKUP LOCATION
              // =================================================

              _sectionTitle(
                'Pickup Location',
              ),

              _card(
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration:
                          BoxDecoration(
                        color:
                            const Color(
                          0xFFFFF1EA,
                        ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          12,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .location_on_rounded,
                        color: orange,
                      ),
                    ),
                    const SizedBox(
                      width: 11,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          const Text(
                            'PICK-UP ADDRESS',
                            style:
                                TextStyle(
                              color:
                                  muted,
                              fontSize: 9,
                              fontWeight:
                                  FontWeight
                                      .w900,
                              letterSpacing:
                                  .5,
                            ),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Text(
                            request
                                .pickupAddress,
                            style:
                                const TextStyle(
                              color: dark,
                              fontSize: 13,
                              height: 1.4,
                              fontWeight:
                                  FontWeight
                                      .w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // =================================================
              // WALK INFORMATION
              // =================================================

              _sectionTitle(
                'Walk Information',
              ),

              _card(
                child: Column(
                  children: [
                    _detailRow(
                      Icons.route_rounded,
                      'Distance',
                      '${request.distanceKm.toStringAsFixed(1)} km',
                    ),
                    _divider(),
                    _detailRow(
                      Icons.access_time_rounded,
                      'Estimated arrival',
                      request.estimatedTime,
                    ),
                    _divider(),
                    _detailRow(
                      Icons.flash_on_rounded,
                      'Walk type',
                      request.walkType,
                    ),
                    _divider(),
                    _detailRow(
                      Icons
                          .check_circle_outline_rounded,
                      'Status',
                      request.status,
                      valueColor: green,
                    ),
                  ],
                ),
              ),

              const SizedBox(
                height: 30,
              ),
            ],
          ),

          // ====================================================
          // FLOATING START WALK
          // ====================================================

          FloatingStartWalkButton(
            onPressed:
                onStartWalk ?? () {},
          ),
        ],
      ),
    );
  }

  static Widget _sectionTitle(
    String title,
  ) {
    return Padding(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        0,
        20,
        9,
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: dark,
          fontSize: 14,
          fontWeight:
              FontWeight.w900,
        ),
      ),
    );
  }

  static Widget _card({
    required Widget child,
  }) {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFFE1E6E8),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withOpacity(.045),
            blurRadius: 13,
            offset:
                const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  static Widget _personRow(
    IconData icon,
    Color color,
    String title,
    String subtitle,
  ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration:
              BoxDecoration(
            color:
                color.withOpacity(.10),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style:
                    const TextStyle(
                  color: dark,
                  fontSize: 15,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style:
                    const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _primaryButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 19,
        ),
        label: Text(
          label,
          style:
              const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.w800,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor:
              Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _detailRow(
    IconData icon,
    String title,
    String value, {
    Color valueColor = dark,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFF1F5F6),
            borderRadius:
                BorderRadius.circular(
              10,
            ),
          ),
          child: Icon(
            icon,
            color: blue,
            size: 18,
          ),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Text(
            title,
            style:
                const TextStyle(
              color: muted,
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight:
                FontWeight.w800,
          ),
        ),
      ],
    );
  }

  static Widget _divider() {
    return const Padding(
      padding:
          EdgeInsets.symmetric(
        vertical: 11,
      ),
      child: Divider(
        height: 1,
        color:
            Color(0xFFE9ECEE),
      ),
    );
  }

  static void _showCancelDialog(
    BuildContext context,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title:
            const Text('Cancel Walk?'),
        content: const Text(
          'Are you sure you want to cancel this accepted walk?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child:
                const Text('Keep'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context),
            child:
                const Text('Cancel Walk'),
          ),
        ],
      ),
    );
  }
}
