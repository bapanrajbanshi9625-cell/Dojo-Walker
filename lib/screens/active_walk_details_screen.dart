import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../features/walks/models/walk_request.dart';

class ActiveWalkDetailsScreen extends StatefulWidget {
  final WalkRequest request;

  /// Optional callback:
  /// Reach के बाद तुम्हारा अगला screen खोलने के लिए।
  final VoidCallback? onReached;

  const ActiveWalkDetailsScreen({
    super.key,
    required this.request,
    this.onReached,
  });

  @override
  State<ActiveWalkDetailsScreen> createState() =>
      _ActiveWalkDetailsScreenState();
}

class _ActiveWalkDetailsScreenState
    extends State<ActiveWalkDetailsScreen> {
  static const Color orange = Color(0xFFFF6600);
  static const Color navy = Color(0xFF263746);
  static const Color green = Color(0xFF159447);

  final MapController _mapController = MapController();

  bool _reached = false;

  // --------------------------------------------------------------------------
  // IMPORTANT
  //
  // WalkRequest model में अभी latitude/longitude fields नहीं हैं।
  //
  // इसलिए यहां कोई fake location नहीं रखी गई है।
  //
  // जब WalkRequest में pickupLat / pickupLng और live walker location
  // आएगी, इसी map को real Firebase/GPS data से connect किया जाएगा।
  // --------------------------------------------------------------------------

  LatLng? _walkerLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ==================================================================
          // MAP
          // ==================================================================

          Positioned.fill(
            child: _buildMap(),
          ),

          // ==================================================================
          // TOP BAR
          // ==================================================================

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                0,
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  _circleButton(
                    Icons.arrow_back_ios_new,
                    () {
                      Navigator.pop(context);
                    },
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Color(0xFF18A957),
                        ),
                        SizedBox(width: 7),
                        Text(
                          'LIVE WALK',
                          style: TextStyle(
                            color: navy,
                            fontSize: 11,
                            fontWeight:
                                FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ==================================================================
          // MY LOCATION
          // ==================================================================

          Positioned(
            right: 16,
            bottom: 330,
            child: _circleButton(
              Icons.my_location,
              () {
                if (_walkerLocation != null) {
                  _mapController.move(
                    _walkerLocation!,
                    17,
                  );
                }
              },
              iconColor: orange,
            ),
          ),

          // ==================================================================
          // DETAILS BOTTOM SHEET
          // ==================================================================

          DraggableScrollableSheet(
            initialChildSize: .46,
            minChildSize: .25,
            maxChildSize: .90,
            snap: true,
            snapSizes: const [
              .25,
              .46,
              .90,
            ],
            builder: (
              BuildContext context,
              ScrollController controller,
            ) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 25,
                      offset: Offset(0, -7),
                    ),
                  ],
                ),
                child: ListView(
                  controller: controller,
                  physics:
                      const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    18,
                    9,
                    18,
                    12,
                  ),
                  children: [
                    // HANDLE
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFD3D8DB),
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 13),

                    // DOG / OWNER
                    _dogHeader(),

                    const SizedBox(height: 10),

                    // STATUS
                    _liveStatus(),

                    const SizedBox(height: 10),

                    // LOCATIONS
                    Row(
                      children: [
                        Expanded(
                          child: _addressCard(
                            Icons.location_on,
                            'PICKUP',
                            widget.request
                                .pickupAddress,
                          ),
                        ),

                        const SizedBox(width: 8),

                        Expanded(
                          child: _addressCard(
                            Icons.flag,
                            'DESTINATION',
                            'Destination not available',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // STATS
                    Row(
                      children: [
                        Expanded(
                          child: _statCard(
                            '${widget.request.distanceKm.toStringAsFixed(1)} km',
                            'Distance',
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _statCard(
                            widget.request
                                .estimatedTime
                                .isEmpty
                                ? '--'
                                : widget.request
                                    .estimatedTime,
                            'ETA',
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _statCard(
                            'LIVE',
                            'Walk',
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // OWNER NOTE
                    _ownerNote(),

                    const SizedBox(height: 10),

                    // CALL + CHAT
                    _callChat(),

                    const SizedBox(height: 10),

                    // REACH
                    ReachSlider(
                      reached: _reached,
                      onReached: _handleReached,
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // MAP
  // ==========================================================================

  Widget _buildMap() {
    final LatLng center =
        _walkerLocation ??
            _pickupLocation ??
            const LatLng(
              20.5937,
              78.9629,
            );

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom:
            _walkerLocation == null &&
                    _pickupLocation == null
                ? 5
                : 16,
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        if (_walkerLocation != null ||
            _pickupLocation != null ||
            _destinationLocation != null)
          MarkerLayer(
            markers: [
              if (_walkerLocation != null)
                Marker(
                  point: _walkerLocation!,
                  width: 56,
                  height: 56,
                  child: _walkerMarker(),
                ),

              if (_pickupLocation != null)
                Marker(
                  point: _pickupLocation!,
                  width: 62,
                  height: 62,
                  child: _pickupMarker(),
                ),

              if (_destinationLocation != null)
                Marker(
                  point: _destinationLocation!,
                  width: 45,
                  height: 45,
                  child: _destinationMarker(),
                ),
            ],
          ),
      ],
    );
  }

  // ==========================================================================
  // DOG HEADER
  // ==========================================================================

  Widget _dogHeader() {
    final String dogName =
        widget.request.dogName.isEmpty
            ? 'Dog'
            : widget.request.dogName;

    final String breed =
        widget.request.dogBreed.isEmpty
            ? 'Breed not available'
            : widget.request.dogBreed;

    final String owner =
        widget.request.ownerName.isEmpty
            ? 'Owner'
            : widget.request.ownerName;

    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E7),
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: const Center(
            child: Icon(
              Icons.pets_rounded,
              color: orange,
              size: 31,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                dogName,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: navy,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                breed,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF737C82),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 2),

              Text(
                'Owner: $owner',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF9AA0A4),
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),

        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E7),
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                '${widget.request.distanceKm.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'away',
                style: TextStyle(
                  color: Color(0xFF92999D),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // LIVE STATUS
  // ==========================================================================

  Widget _liveStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FAF4),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFD7EFDF),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.navigation,
            color: green,
            size: 18,
          ),
          const SizedBox(width: 9),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Walking to pickup',
                  style: TextStyle(
                    color: Color(0xFF237546),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Live location active',
                  style: TextStyle(
                    color: Color(0xFF6B8B77),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF18A957),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ADDRESS
  // ==========================================================================

  Widget _addressCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F9),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: orange,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF9AA0A4),
                    fontSize: 7,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // STAT
  // ==========================================================================

  Widget _statCard(
    String value,
    String title,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8F9),
        borderRadius:
            BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            style: const TextStyle(
              color: navy,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF999FA3),
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // OWNER NOTE
  // ==========================================================================

  Widget _ownerNote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFE8D7),
        ),
      ),
      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                color: orange,
                size: 15,
              ),
              SizedBox(width: 6),
              Text(
                'OWNER NOTE',
                style: TextStyle(
                  color: orange,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Text(
            'No additional note provided by owner.',
            style: TextStyle(
              color: Color(0xFF666D72),
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // CALL + CHAT
  // ==========================================================================

  Widget _callChat() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // Phone connection बाद में real owner phone से जोड़ा जाएगा।
              },
              icon: const Icon(
                Icons.call,
                size: 19,
              ),
              label: const Text(
                'Call',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          flex: 5,
          child: SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                // Chat screen बाद में connect होगा।
              },
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 19,
              ),
              label: const Text(
                'Chat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor: navy,
                backgroundColor: Colors.white,
                side: const BorderSide(
                  color: Color(0xFFD5DADD),
                  width: 1.3,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // REACHED
  // ==========================================================================

  void _handleReached() {
    if (_reached) {
      return;
    }

    setState(() {
      _reached = true;
    });

    if (widget.onReached != null) {
      widget.onReached!();
    }
  }

  // ==========================================================================
  // ROUND BUTTON
  // ==========================================================================

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    Color iconColor = navy,
  }) {
    return Material(
      color: Colors.white,
      elevation: 5,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder:
            const CircleBorder(),
        child: SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // MAP MARKERS
  // ==========================================================================

  Widget _walkerMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: orange,
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 10,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.person,
          color: navy,
          size: 22,
        ),
      ),
    );
  }

  Widget _pickupMarker() {
    return Container(
      decoration: BoxDecoration(
        color: orange,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.pets,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _destinationMarker() {
    return Container(
      decoration: const BoxDecoration(
        color: navy,
        shape: BoxShape.circle,
      ),
      child: const Center(
        child: Icon(
          Icons.flag,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

// ============================================================================
// REACH SLIDER
// ============================================================================

class ReachSlider extends StatefulWidget {
  final bool reached;
  final VoidCallback onReached;

  const ReachSlider({
    super.key,
    required this.reached,
    required this.onReached,
  });

  @override
  State<ReachSlider> createState() =>
      _ReachSliderState();
}

class _ReachSliderState
    extends State<ReachSlider> {
  double position = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (
        BuildContext context,
        BoxConstraints constraints,
      ) {
        const double handleSize = 50;

        final double maxPosition =
            constraints.maxWidth -
                handleSize;

        if (widget.reached) {
          return Container(
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE7F7ED),
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFCBEBD7),
              ),
            ),
            child: const Center(
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    color: green,
                    size: 19,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Reached Pickup Point',
                    style: TextStyle(
                      color: green,
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F7ED),
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color: const Color(0xFFCBEBD7),
            ),
          ),
          child: Stack(
            children: [
              const Center(
                child: Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'Slide to Reach',
                      style: TextStyle(
                        color: Color(0xFF23834A),
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color: Color(0xFF23834A),
                      size: 19,
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Color(0xFF75B58E),
                      size: 19,
                    ),
                  ],
                ),
              ),

              Positioned(
                left: position,
                top: 2,
                child: GestureDetector(
                  onHorizontalDragUpdate:
                      (details) {
                    setState(() {
                      position +=
                          details.delta.dx;

                      position =
                          position.clamp(
                        0.0,
                        maxPosition,
                      );
                    });
                  },
                  onHorizontalDragEnd:
                      (_) {
                    if (position >=
                        maxPosition * .80) {
                      widget.onReached();
                    } else {
                      setState(() {
                        position = 0;
                      });
                    }
                  },
                  child: Container(
                    width: handleSize,
                    height: handleSize,
                    decoration:
                        BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: green,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
