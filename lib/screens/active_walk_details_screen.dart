import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../features/walks/models/walk_request.dart';

class ActiveWalkDetailsScreen extends StatefulWidget {
  final WalkRequest request;

  /// Reach होने के बाद अगला page खोलने के लिए.
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
  // ========================================================================
  // COLORS
  // ========================================================================

  static const Color orange = Color(0xFFFF6600);
  static const Color navy = Color(0xFF263746);
  static const Color green = Color(0xFF159447);
  static const Color greenLight = Color(0xFFE7F7ED);

  // ========================================================================
  // FIREBASE
  // ========================================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ========================================================================
  // MAP
  // ========================================================================

  final MapController _mapController =
      MapController();

  LatLng? _walkerLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;

  // ========================================================================
  // LIVE DATA
  // ========================================================================

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _activeWalkSubscription;

  StreamSubscription<
      DocumentSnapshot<Map<String, dynamic>>>?
      _sessionSubscription;

  String _liveStatus = 'active';

  double? _liveDistanceKm;
  int? _elapsedSeconds;

  // ========================================================================
  // REACHED
  // ========================================================================

  bool _reached = false;
  bool _reaching = false;

  // ========================================================================
  // SHEET
  // ========================================================================

  final DraggableScrollableController
      _sheetController =
      DraggableScrollableController();

  // ========================================================================
  // LIFECYCLE
  // ========================================================================

  @override
  void initState() {
    super.initState();

    _startLiveListeners();
  }

  @override
  void dispose() {
    _activeWalkSubscription?.cancel();
    _sessionSubscription?.cancel();
    _sheetController.dispose();

    super.dispose();
  }

  // ========================================================================
  // FIREBASE LIVE LISTENERS
  // ========================================================================

  void _startLiveListeners() {
    final String walkId = widget.request.id;

    if (walkId.trim().isEmpty) {
      return;
    }

    // ----------------------------------------------------------------------
    // active_walk/{walkId}
    // ----------------------------------------------------------------------

    _activeWalkSubscription = _firestore
        .collection('active_walk')
        .doc(walkId)
        .snapshots()
        .listen(
      _handleActiveWalkSnapshot,
      onError: (_) {},
    );

    // ----------------------------------------------------------------------
    // liveWalkSessions/session-{walkId}
    // ----------------------------------------------------------------------

    final String sessionId =
        'session-$walkId';

    _sessionSubscription = _firestore
        .collection('liveWalkSessions')
        .doc(sessionId)
        .snapshots()
        .listen(
      _handleSessionSnapshot,
      onError: (_) {},
    );
  }

  // ========================================================================
  // ACTIVE WALK SNAPSHOT
  // ========================================================================

  void _handleActiveWalkSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    final LatLng? location =
        _extractLocationFromActiveWalk(data);

    final String status =
        _readString(
      data['status'],
      fallback: _liveStatus,
    );

    final double? distance =
        _readDouble(data['distanceKm']);

    if (!mounted) {
      return;
    }

    setState(() {
      if (location != null) {
        _walkerLocation = location;
      }

      _liveStatus = status;

      if (distance != null) {
        _liveDistanceKm = distance;
      }
    });

    _moveMapToWalkerIfNeeded(location);
  }

  // ========================================================================
  // SESSION SNAPSHOT
  // ========================================================================

  void _handleSessionSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    if (!snapshot.exists) {
      return;
    }

    final Map<String, dynamic> data =
        snapshot.data() ??
            <String, dynamic>{};

    final LatLng? location =
        _extractLocationFromSession(data);

    final double? distance =
        _readDouble(data['distanceKm']);

    final int? elapsed =
        _readInt(data['elapsedSeconds']);

    final String status =
        _readString(
      data['status'],
      fallback: _liveStatus,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      if (location != null) {
        _walkerLocation = location;
      }

      if (distance != null) {
        _liveDistanceKm = distance;
      }

      if (elapsed != null) {
        _elapsedSeconds = elapsed;
      }

      _liveStatus = status;
    });

    _moveMapToWalkerIfNeeded(location);
  }

  // ========================================================================
  // ACTIVE WALK LOCATION
  // ========================================================================

  LatLng? _extractLocationFromActiveWalk(
    Map<String, dynamic> data,
  ) {
    final double? lat =
        _readDouble(data['currentLat']);

    final double? lng =
        _readDouble(data['currentLng']);

    if (lat == null || lng == null) {
      return null;
    }

    if (!_validCoordinate(lat, lng)) {
      return null;
    }

    return LatLng(lat, lng);
  }

  // ========================================================================
  // SESSION LOCATION
  // ========================================================================

  LatLng? _extractLocationFromSession(
    Map<String, dynamic> data,
  ) {
    final dynamic location =
        data['currentLocation'];

    if (location is Map) {
      final double? lat =
          _readDouble(location['lat']);

      final double? lng =
          _readDouble(location['lng']);

      if (lat != null &&
          lng != null &&
          _validCoordinate(lat, lng)) {
        return LatLng(lat, lng);
      }
    }

    return null;
  }

  // ========================================================================
  // MAP
  // ========================================================================

  Widget _buildMap() {
    final LatLng? center =
        _walkerLocation ??
            _pickupLocation ??
            _destinationLocation;

    // ----------------------------------------------------------------------
    // IMPORTANT:
    //
    // No fake coordinate.
    //
    // अगर Firebase में अभी location नहीं है,
    // map India को fake center नहीं करेगा.
    // खाली map + location message दिखेगा.
    // ----------------------------------------------------------------------

    if (center == null) {
      return Stack(
        children: [
          Container(
            color: const Color(0xFFEFF2F3),
          ),
          const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_searching_rounded,
                  color: Color(0xFF7D878D),
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Waiting for live location...',
                  style: TextStyle(
                    color: Color(0xFF667077),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
      ),
      children: [
        // ------------------------------------------------------------------
        // REAL OPENSTREETMAP
        // ------------------------------------------------------------------

        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),

        // ------------------------------------------------------------------
        // ROUTE
        // ------------------------------------------------------------------

        if (_walkerLocation != null &&
            _pickupLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  _walkerLocation!,
                  _pickupLocation!,
                ],
                color: orange,
                strokeWidth: 5,
              ),
            ],
          ),

        // ------------------------------------------------------------------
        // MARKERS
        // ------------------------------------------------------------------

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

  // ========================================================================
  // MOVE MAP
  // ========================================================================

  void _moveMapToWalkerIfNeeded(
    LatLng? location,
  ) {
    if (location == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!mounted) {
          return;
        }

        try {
          _mapController.move(
            location,
            16,
          );
        } catch (_) {
          // MapController may not be attached yet.
        }
      },
    );
  }

  // ========================================================================
  // BUILD
  // ========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ================================================================
          // FULL MAP
          // ================================================================

          Positioned.fill(
            child: _buildMap(),
          ),

          // ================================================================
          // TOP BAR
          // ================================================================

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

                  _liveBadge(),
                ],
              ),
            ),
          ),

          // ================================================================
          // MY LOCATION
          // ================================================================

          Positioned(
            right: 16,
            bottom: 330,
            child: _circleButton(
              Icons.my_location,
              () {
                final LatLng? location =
                    _walkerLocation;

                if (location != null) {
                  _mapController.move(
                    location,
                    17,
                  );
                }
              },
              iconColor: orange,
            ),
          ),

          // ================================================================
          // BOTTOM DETAILS
          // ================================================================

          DraggableScrollableSheet(
            controller: _sheetController,
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
                decoration:
                    const BoxDecoration(
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
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    9,
                    18,
                    18,
                  ),
                  children: [
                    // HANDLE
                    _sheetHandle(),

                    const SizedBox(height: 13),

                    // DOG
                    _dogHeader(),

                    const SizedBox(height: 10),

                    // LIVE STATUS
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
                                    .pickupAddress
                                    .isEmpty
                                ? 'Pickup address unavailable'
                                : widget.request
                                    .pickupAddress,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _addressCard(
                            Icons.flag,
                            'DESTINATION',
                            'Destination unavailable',
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
                            _distanceText(),
                            'Distance',
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _statCard(
                            _etaText(),
                            'ETA',
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: _statCard(
                            _durationText(),
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

  // ========================================================================
  // LIVE BADGE
  // ========================================================================

  Widget _liveBadge() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
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
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ========================================================================
  // SHEET HANDLE
  // ========================================================================

  Widget _sheetHandle() {
    return Center(
      child: Container(
        width: 48,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFD3D8DB),
          borderRadius:
              BorderRadius.circular(20),
        ),
      ),
    );
  }

  // ========================================================================
  // DOG HEADER
  // ========================================================================

  Widget _dogHeader() {
    final String dogName =
        _fallback(
      widget.request.dogName,
      'Dog',
    );

    final String breed =
        _fallback(
      widget.request.dogBreed,
      'Breed not available',
    );

    final String owner =
        _fallback(
      widget.request.ownerName,
      'Owner',
    );

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
          padding:
              const EdgeInsets.symmetric(
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
                _distanceText(),
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

  // ========================================================================
  // LIVE STATUS
  // ========================================================================

  Widget _liveStatus() {
    final bool isActive =
        _liveStatus.toLowerCase() == 'active';

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
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

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  isActive
                      ? 'Walking to pickup'
                      : _liveStatus.toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF237546),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
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

  // ========================================================================
  // ADDRESS
  // ========================================================================

  Widget _addressCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(10),
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

  // ========================================================================
  // STAT
  // ========================================================================

  Widget _statCard(
    String value,
    String title,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
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

  // ========================================================================
  // OWNER NOTE
  // ========================================================================

  Widget _ownerNote() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8F2),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFE8D7),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: const [
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

  // ========================================================================
  // CALL + CHAT
  // ========================================================================

  Widget _callChat() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                // ------------------------------------------------------------
                // यहाँ बाद में ownerPhone से वास्तविक call जोड़ा जाएगा.
                // ------------------------------------------------------------
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
                // ------------------------------------------------------------
                // Chat connection hook.
                // ------------------------------------------------------------
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

  // ========================================================================
  // REACH
  // ========================================================================

  Future<void> _handleReached() async {
    if (_reached || _reaching) {
      return;
    }

    setState(() {
      _reaching = true;
    });

    try {
      // --------------------------------------------------------------------
      // IMPORTANT:
      //
      // अभी कोई नया fake document नहीं बनाया जा रहा.
      //
      // Existing walk_request को ही update करेंगे.
      // --------------------------------------------------------------------

      await _firestore
          .collection('walk_requests')
          .doc(widget.request.id)
          .update({
        'status': 'reached',
        'reachedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _reached = true;
        _reaching = false;
      });

      // --------------------------------------------------------------------
      // NEXT PAGE
      // --------------------------------------------------------------------

      widget.onReached?.call();
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _reaching = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to mark reached: $e',
          ),
        ),
      );
    }
  }

  // ========================================================================
  // ROUND BUTTON
  // ========================================================================

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

  // ========================================================================
  // MAP MARKERS
  // ========================================================================

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

  // ========================================================================
  // DISTANCE
  // ========================================================================

  String _distanceText() {
    if (_liveDistanceKm != null) {
      return '${_liveDistanceKm!.toStringAsFixed(1)} km';
    }

    return '${widget.request.distanceKm.toStringAsFixed(1)} km';
  }

  // ========================================================================
  // ETA
  // ========================================================================

  String _etaText() {
    final String value =
        widget.request.estimatedTime.trim();

    if (value.isEmpty) {
      return '--';
    }

    return value;
  }

  // ========================================================================
  // DURATION
  // ========================================================================

  String _durationText() {
    if (_elapsedSeconds == null) {
      return '--';
    }

    return _formatDuration(
      _elapsedSeconds!,
    );
  }

  // ========================================================================
  // HELPERS
  // ========================================================================

  String _fallback(
    String value,
    String fallback,
  ) {
    final String result =
        value.trim();

    return result.isEmpty
        ? fallback
        : result;
  }

  String _readString(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    return result.isEmpty
        ? fallback
        : result;
  }

  double? _readDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  int? _readInt(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
      value.toString().trim(),
    );
  }

  bool _validCoordinate(
    double lat,
    double lng,
  ) {
    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }

  String _formatDuration(
    int totalSeconds,
  ) {
    final int hours =
        totalSeconds ~/ 3600;

    final int minutes =
        (totalSeconds % 3600) ~/ 60;

    final int seconds =
        totalSeconds % 60;

    final String hh =
        hours.toString().padLeft(2, '0');

    final String mm =
        minutes.toString().padLeft(2, '0');

    final String ss =
        seconds.toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
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
  static const Color green =
      Color(0xFF159447);

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
            (constraints.maxWidth -
                    handleSize)
                .clamp(
          0.0,
          double.infinity,
        );

        // ==================================================================
        // SUCCESS
        // ==================================================================

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
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // ==================================================================
        // SLIDER
        // ==================================================================

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

              // ==============================================================
              // HANDLE
              // ==============================================================

              Positioned(
                left: position,
                top: 2,
                child: GestureDetector(
                  onHorizontalDragUpdate:
                      (DragUpdateDetails details) {
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
                      (DragEndDetails details) {
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
                    decoration: BoxDecoration(
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
