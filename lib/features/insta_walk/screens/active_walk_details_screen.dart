// File:
// lib/features/insta_walk/screens/active_walk_details_screen.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../models/insta_walk_request.dart';
import '../services/insta_walk_service.dart';

class ActiveWalkDetailsScreen extends StatefulWidget {
  final InstaWalkRequest request;
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
  // ============================================================
  // SERVICE
  // ============================================================

  final InstaWalkService _instaWalkService =
      InstaWalkService.instance;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color green = Color(0xFF159447);
  static const Color greenLight = Color(0xFFE7F7ED);
  static const Color muted = Color(0xFF737C82);

  // ============================================================
  // MAP
  // ============================================================

  final MapController _mapController = MapController();

  LatLng? _walkerLocation;
  LatLng? _pickupLocation;
  LatLng? _destinationLocation;

  // ============================================================
  // LIVE DATA
  // ============================================================

  double _distanceKm = 0.0;
  int _elapsedSeconds = 0;
  int _steps = 0;

  String _liveStatus = 'accepted';

  // ============================================================
  // SUBSCRIPTIONS
  // ============================================================

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _walkSubscription;

  // ============================================================
  // UI STATE
  // ============================================================

  bool _reached = false;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _sheetExpanded = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _loadInitialData();

    _sheetController.addListener(_onSheetChanged);

    _listenToWalk();
  }

  // ============================================================
  // INITIAL DATA
  // ============================================================

  void _loadInitialData() {
    final InstaWalkRequest request = widget.request;

    // ----------------------------------------------------------
    // PICKUP LOCATION
    // ----------------------------------------------------------

    if (_validCoordinate(
      request.latitude ?? 0.0,
      request.longitude ?? 0.0,
    )) {
      _pickupLocation = LatLng(
        request.latitude!,
        request.longitude!,
      );
    }

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    _distanceKm = request.distanceKm;

    // ----------------------------------------------------------
    // STATUS
    // ----------------------------------------------------------

    if (request.status.trim().isNotEmpty) {
      _liveStatus = request.status.trim();
    }
  }

  // ============================================================
  // LIVE WALK REQUEST
  //
  // walk_requests/{id}
  // ============================================================

  void _listenToWalk() {
    final String walkId = widget.request.id.trim();

    if (walkId.isEmpty) {
      return;
    }

    _walkSubscription =
        _instaWalkService.watchWalk(walkId).listen(
      (
        DocumentSnapshot<Map<String, dynamic>> snapshot,
      ) {
        if (!mounted || !snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        _applyLiveData(data);
      },
      onError: (Object error) {
        debugPrint(
          'Insta Walk stream error: $error',
        );
      },
    );
  }

  // ============================================================
  // APPLY LIVE DATA
  // ============================================================

  void _applyLiveData(
    Map<String, dynamic> data,
  ) {
    // ----------------------------------------------------------
    // STATUS
    // ----------------------------------------------------------

    final String status =
        _readString(data['status']);

    // ----------------------------------------------------------
    // DISTANCE
    // ----------------------------------------------------------

    final double distance =
        _readDouble(data['distanceKm']);

    // ----------------------------------------------------------
    // ELAPSED
    // ----------------------------------------------------------

    final int elapsed =
        _readInt(data['elapsedSeconds']);

    // ----------------------------------------------------------
    // STEPS
    // ----------------------------------------------------------

    final int steps =
        _readInt(data['steps']);

    // ----------------------------------------------------------
    // PICKUP LOCATION
    // ----------------------------------------------------------

    final double pickupLat = _readDouble(
      data['latitude'] ??
          data['lat'] ??
          data['pickupLatitude'],
    );

    final double pickupLng = _readDouble(
      data['longitude'] ??
          data['lng'] ??
          data['pickupLongitude'],
    );

    // ----------------------------------------------------------
    // DESTINATION LOCATION
    // ----------------------------------------------------------

    LatLng? destination;

    final Map<String, dynamic>? destinationMap =
        _readMap(data['destinationLocation']);

    if (destinationMap != null) {
      final double lat = _readDouble(
        destinationMap['lat'] ??
            destinationMap['latitude'],
      );

      final double lng = _readDouble(
        destinationMap['lng'] ??
            destinationMap['longitude'],
      );

      if (_validCoordinate(lat, lng)) {
        destination = LatLng(lat, lng);
      }
    } else {
      final double lat = _readDouble(
        data['destinationLatitude'] ??
            data['destinationLat'],
      );

      final double lng = _readDouble(
        data['destinationLongitude'] ??
            data['destinationLng'],
      );

      if (_validCoordinate(lat, lng)) {
        destination = LatLng(lat, lng);
      }
    }

    // ----------------------------------------------------------
    // CURRENT / WALKER LOCATION
    // ----------------------------------------------------------

    LatLng? walker;

    final Map<String, dynamic>? currentLocation =
        _readMap(data['currentLocation']);

    if (currentLocation != null) {
      final double lat = _readDouble(
        currentLocation['lat'] ??
            currentLocation['latitude'],
      );

      final double lng = _readDouble(
        currentLocation['lng'] ??
            currentLocation['longitude'],
      );

      if (_validCoordinate(lat, lng)) {
        walker = LatLng(lat, lng);
      }
    }

    if (walker == null) {
      final double lat = _readDouble(
        data['currentLat'] ??
            data['walkerLat'] ??
            data['liveLatitude'],
      );

      final double lng = _readDouble(
        data['currentLng'] ??
            data['walkerLng'] ??
            data['liveLongitude'],
      );

      if (_validCoordinate(lat, lng)) {
        walker = LatLng(lat, lng);
      }
    }

    // ----------------------------------------------------------
    // UPDATE UI
    // ----------------------------------------------------------

    if (!mounted) {
      return;
    }

    setState(() {
      if (walker != null) {
        _walkerLocation = walker;
      }

      if (_validCoordinate(
        pickupLat,
        pickupLng,
      )) {
        _pickupLocation = LatLng(
          pickupLat,
          pickupLng,
        );
      }

      if (destination != null) {
        _destinationLocation = destination;
      }

      if (distance > 0) {
        _distanceKm = distance;
      }

      if (elapsed >= 0) {
        _elapsedSeconds = elapsed;
      }

      if (steps >= 0) {
        _steps = steps;
      }

      if (status.isNotEmpty) {
        _liveStatus = status;
      }
    });
  }

  // ============================================================
  // SHEET LISTENER
  // ============================================================

  void _onSheetChanged() {
    final bool expanded =
        _sheetController.size > 0.55;

    if (_sheetExpanded != expanded && mounted) {
      setState(() {
        _sheetExpanded = expanded;
      });
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: _buildMap(),
          ),

          _buildTopBar(),

          Positioned(
            right: 16,
            bottom: _sheetExpanded ? 700 : 190,
            child: _circleButton(
              Icons.my_location,
              _moveToWalker,
              iconColor: AppColors.primary,
            ),
          ),

          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: .25,
            minChildSize: .25,
            maxChildSize: .90,
            snap: true,
            snapSizes: const [
              .25,
              .90,
            ],
            builder: (
              BuildContext context,
              ScrollController controller,
            ) {
              return _buildBottomSheet(controller);
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    final String status =
        _liveStatus.trim().toLowerCase();

    final bool isActive =
        status == 'active';

    return SafeArea(
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
              () => Navigator.pop(context),
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
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isActive
                        ? green
                        : const Color(0xFFFFA000),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    isActive
                        ? 'LIVE WALK'
                        : status.isEmpty
                            ? 'INSTA WALK'
                            : status.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    final List<LatLng> locations = [];

    if (_walkerLocation != null) {
      locations.add(_walkerLocation!);
    }

    if (_pickupLocation != null) {
      locations.add(_pickupLocation!);
    }

    if (_destinationLocation != null) {
      locations.add(_destinationLocation!);
    }

    LatLng mapCenter;

    if (_walkerLocation != null) {
      mapCenter = _walkerLocation!;
    } else if (_pickupLocation != null) {
      mapCenter = _pickupLocation!;
    } else if (_destinationLocation != null) {
      mapCenter = _destinationLocation!;
    } else {
      mapCenter = const LatLng(
        20.5937,
        78.9629,
      );
    }

    final List<Marker> markers = [];

    if (_walkerLocation != null) {
      markers.add(
        Marker(
          point: _walkerLocation!,
          width: 56,
          height: 56,
          child: _walkerMarker(),
        ),
      );
    }

    if (_pickupLocation != null) {
      markers.add(
        Marker(
          point: _pickupLocation!,
          width: 62,
          height: 62,
          child: _pickupMarker(),
        ),
      );
    }

    if (_destinationLocation != null) {
      markers.add(
        Marker(
          point: _destinationLocation!,
          width: 45,
          height: 45,
          child: _destinationMarker(),
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: mapCenter,
        initialZoom:
            locations.length > 1 ? 14 : 16,
        interactionOptions:
            const InteractionOptions(
          flags: InteractiveFlag.all,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName:
              'com.doojowalker.app',
        ),
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers,
          ),
        if (_walkerLocation != null &&
            _pickupLocation != null)
          PolylineLayer(
            polylines: [
              Polyline(
                points: [
                  _walkerLocation!,
                  _pickupLocation!,
                ],
                strokeWidth: 4,
                color: AppColors.primary,
              ),
            ],
          ),
      ],
    );
  }

  // ============================================================
  // MOVE TO WALKER
  // ============================================================

  void _moveToWalker() {
    final LatLng? location =
        _walkerLocation;

    if (location == null) {
      _showMessage(
        'Live location is not available yet.',
      );
      return;
    }

    _mapController.move(
      location,
      17,
    );
  }

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  Widget _buildBottomSheet(
    ScrollController controller,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
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
          14,
        ),
        children: [
          GestureDetector(
            onTap: _toggleSheet,
            child: Center(
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
          ),

          const SizedBox(height: 13),

          _buildCollapsedActiveWalk(),

          const SizedBox(height: 12),

          _buildDogHeader(),

          const SizedBox(height: 10),

          _buildLiveStatus(),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _addressCard(
                  Icons.location_on,
                  'PICKUP',
                  _pickupText,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _addressCard(
                  Icons.flag,
                  'DESTINATION',
                  _destinationText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _statCard(
                  _distanceText,
                  'Distance',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _statCard(
                  _durationText,
                  'Duration',
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _statCard(
                  '$_steps',
                  'Steps',
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          _statCard(
            _walkStatusText,
            'Walk',
          ),

          const SizedBox(height: 10),

          _buildOwnerNote(),

          const SizedBox(height: 10),

          _buildCallChat(),

          const SizedBox(height: 10),

          ReachSlider(
            reached: _reached,
            onReached: _handleReached,
          ),

          const SizedBox(height: 10),

          _buildBottomNavigation(),

          const SizedBox(height: 3),
        ],
      ),
    );
  }

  // ============================================================
  // COLLAPSED ACTIVE WALK
  // ============================================================

  Widget _buildCollapsedActiveWalk() {
    return GestureDetector(
      onTap: _expandSheet,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 11,
        ),
        decoration: BoxDecoration(
          color: greenLight,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color:
                const Color(0xFFCBEBD7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.pets_rounded,
                color: green,
                size: 21,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ACTIVE INSTA WALK',
                    style: TextStyle(
                      color: AppColors.secondary,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w900,
                      letterSpacing: .4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_ownerNameText • $_dogNameText',
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: muted,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(10),
              ),
              child: Text(
                _liveStatus.toUpperCase(),
                style: const TextStyle(
                  color: green,
                  fontSize: 8,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              Icons.keyboard_arrow_up_rounded,
              color: green,
              size: 21,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DOG / OWNER
  // ============================================================

  Widget _buildDogHeader() {
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color:
                const Color(0xFFFFF0E7),
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Center(
            child: Icon(
              Icons.pets_rounded,
              color: AppColors.primary,
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
                _dogNameText,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _breedText,
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Owner: $_ownerNameText',
                maxLines: 1,
                overflow:
                    TextOverflow.ellipsis,
                style: const TextStyle(
                  color:
                      Color(0xFF9AA0A4),
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
            color:
                const Color(0xFFFFF0E7),
            borderRadius:
                BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              Text(
                _distanceText,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'distance',
                style: TextStyle(
                  color:
                      Color(0xFF92999D),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // LIVE STATUS
  // ============================================================

  Widget _buildLiveStatus() {
    final bool hasLocation =
        _walkerLocation != null;

    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF0FAF4),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFD7EFDF),
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
                  hasLocation
                      ? 'Live location active'
                      : 'Waiting for live location',
                  style: const TextStyle(
                    color:
                        Color(0xFF237546),
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasLocation
                      ? 'Walker location is updating in real time'
                      : 'GPS location will appear here',
                  style: const TextStyle(
                    color:
                        Color(0xFF6B8B77),
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: hasLocation
                  ? green
                  : const Color(0xFFFFA000),
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ADDRESS CARD
  // ============================================================

  Widget _addressCard(
    IconData icon,
    String title,
    String value,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F8F9),
        borderRadius:
            BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
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
                    color:
                        Color(0xFF9AA0A4),
                    fontSize: 7,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 2,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.secondary,
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

  // ============================================================
  // STAT CARD
  // ============================================================

  Widget _statCard(
    String value,
    String title,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.symmetric(
        vertical: 9,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color:
            const Color(0xFFF7F8F9),
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
              color: AppColors.secondary,
              fontSize: 11,
              fontWeight:
                  FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              color:
                  Color(0xFF999FA3),
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // OWNER NOTE
  // ============================================================

  Widget _buildOwnerNote() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            const Color(0xFFFFF8F2),
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFFFE8D7),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.sticky_note_2_outlined,
                color: AppColors.primary,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                'OWNER NOTE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 9,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            _ownerNoteText,
            style: const TextStyle(
              color:
                  Color(0xFF666D72),
              fontSize: 10,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CALL + CHAT
  // ============================================================

  Widget _buildCallChat() {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _callOwner,
              icon: const Icon(
                Icons.call,
                size: 19,
              ),
              label: const Text(
                'Call',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w900,
                ),
              ),
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.black,
                foregroundColor:
                    Colors.white,
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
              onPressed: _openChat,
              icon: const Icon(
                Icons.chat_bubble_outline,
                size: 19,
              ),
              label: const Text(
                'Chat',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      FontWeight.w800,
                ),
              ),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors.secondary,
                backgroundColor:
                    Colors.white,
                side: const BorderSide(
                  color:
                      Color(0xFFD5DADD),
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

  // ============================================================
  // CALL OWNER
  // ============================================================

  Future<void> _callOwner() async {
    final String phone =
        widget.request.ownerPhone.trim();

    if (phone.isEmpty) {
      _showMessage(
        'Owner phone number is not available.',
      );
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      final bool canLaunch =
          await canLaunchUrl(uri);

      if (!canLaunch) {
        _showMessage(
          'Unable to open phone dialer.',
        );
        return;
      }

      await launchUrl(uri);
    } catch (_) {
      _showMessage(
        'Unable to call owner.',
      );
    }
  }

  // ============================================================
  // CHAT
  // ============================================================

  void _openChat() {
    _showMessage(
      'Chat is not connected yet.',
    );
  }

  // ============================================================
  // REACHED
  // ============================================================

  void _handleReached() {
    if (_reached) {
      return;
    }

    setState(() {
      _reached = true;
    });

    widget.onReached?.call();
  }

  // ============================================================
  // SHEET
  // ============================================================

  void _expandSheet() {
    _sheetController.animateTo(
      .90,
      duration:
          const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _toggleSheet() {
    if (_sheetExpanded) {
      _sheetController.animateTo(
        .25,
        duration:
            const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _expandSheet();
    }
  }

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Container(
      height: 54,
      decoration:
          const BoxDecoration(
        border: Border(
          top: BorderSide(
            color:
                Color(0xFFF0F1F2),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceAround,
        children: [
          _tab(
            Icons.home_outlined,
            'Home',
          ),
          _tab(
            Icons.pets_outlined,
            'Walks',
          ),
          _tab(
            Icons.person_outline,
            'Profile',
          ),
        ],
      ),
    );
  }

  Widget _tab(
    IconData icon,
    String title,
  ) {
    return Column(
      mainAxisAlignment:
          MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          color: AppColors.secondary,
          size: 20,
        ),
        const SizedBox(height: 1),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.secondary,
            fontSize: 8,
            fontWeight:
                FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ROUND BUTTON
  // ============================================================

  Widget _circleButton(
    IconData icon,
    VoidCallback onTap, {
    Color? iconColor,
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
            color:
                iconColor ?? AppColors.secondary,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MAP MARKERS
  // ============================================================

  Widget _walkerMarker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.primary,
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
          color: AppColors.secondary,
          size: 22,
        ),
      ),
    );
  }

  Widget _pickupMarker() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
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
        color: AppColors.secondary,
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

  // ============================================================
  // DATA
  // ============================================================

  String get _ownerNameText {
    final String value =
        widget.request.ownerName.trim();

    return value.isEmpty ? 'Owner' : value;
  }

  String get _dogNameText {
    final String value =
        widget.request.dogName.trim();

    return value.isEmpty ? 'Dog' : value;
  }

  String get _breedText {
    final String value =
        widget.request.dogBreed.trim();

    return value.isEmpty
        ? 'Breed not available'
        : value;
  }

  String get _pickupText {
    final String value =
        widget.request.pickupAddress.trim();

    if (value.isNotEmpty) {
      return value;
    }

    final String address =
        widget.request.address.trim();

    return address.isEmpty
        ? 'Pickup address not available'
        : address;
  }

  String get _destinationText {
    if (_destinationLocation != null) {
      return 'Destination location';
    }

    return 'Destination not available';
  }

  String get _distanceText {
    if (_distanceKm <= 0) {
      return '--';
    }

    return '${_distanceKm.toStringAsFixed(1)} km';
  }

  String get _durationText {
    return _formatDuration(
      _elapsedSeconds,
    );
  }

  String get _walkStatusText {
    if (_reached) {
      return 'Reached';
    }

    final String status =
        _liveStatus.trim().toLowerCase();

    if (status == 'completed') {
      return 'Completed';
    }

    if (status == 'cancelled') {
      return 'Cancelled';
    }

    if (status == 'rejected') {
      return 'Rejected';
    }

    if (status == 'searching') {
      return 'Searching';
    }

    if (status == 'accepted') {
      return 'Accepted';
    }

    return 'Active';
  }

  String get _ownerNoteText {
    return 'No additional note provided by owner.';
  }

  // ============================================================
  // SAFE READERS
  // ============================================================

  static String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static double _readDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().trim(),
        ) ??
        0.0;
  }

  static int _readInt(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString().trim(),
        ) ??
        0;
  }

  static Map<String, dynamic>? _readMap(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(
        value,
      );
    }

    return null;
  }

  static bool _validCoordinate(
    double latitude,
    double longitude,
  ) {
    return latitude != 0.0 &&
        longitude != 0.0 &&
        latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }

  static String _formatDuration(
    int totalSeconds,
  ) {
    final int safeSeconds =
        totalSeconds < 0
            ? 0
            : totalSeconds;

    final int hours =
        safeSeconds ~/ 3600;

    final int minutes =
        (safeSeconds % 3600) ~/ 60;

    final int seconds =
        safeSeconds % 60;

    final String hh =
        hours.toString().padLeft(2, '0');

    final String mm =
        minutes.toString().padLeft(2, '0');

    final String ss =
        seconds.toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration:
              const Duration(seconds: 2),
        ),
      );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _walkSubscription?.cancel();

    _sheetController.removeListener(
      _onSheetChanged,
    );

    _sheetController.dispose();

    super.dispose();
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

  double _position = 0;

  @override
  Widget build(
    BuildContext context,
  ) {
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

        if (widget.reached) {
          return Container(
            height: 54,
            decoration: BoxDecoration(
              color:
                  const Color(0xFFE7F7ED),
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color:
                    const Color(0xFFCBEBD7),
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
            color:
                const Color(0xFFE7F7ED),
            borderRadius:
                BorderRadius.circular(17),
            border: Border.all(
              color:
                  const Color(0xFFCBEBD7),
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
                        color:
                            Color(0xFF23834A),
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right,
                      color:
                          Color(0xFF23834A),
                      size: 19,
                    ),
                    Icon(
                      Icons.chevron_right,
                      color:
                          Color(0xFF75B58E),
                      size: 19,
                    ),
                  ],
                ),
              ),
              Positioned(
                left: _position,
                top: 2,
                child: GestureDetector(
                  onHorizontalDragUpdate:
                      (DragUpdateDetails details) {
                    setState(() {
                      _position +=
                          details.delta.dx;

                      _position =
                          _position.clamp(
                        0.0,
                        maxPosition,
                      );
                    });
                  },
                  onHorizontalDragEnd:
                      (DragEndDetails details) {
                    if (_position >=
                        maxPosition * .80) {
                      widget.onReached();
                    } else {
                      setState(() {
                        _position = 0;
                      });
                    }
                  },
                  child: const SizedBox(
                    width: 50,
                    height: 50,
                    child: DecoratedBox(
                      decoration:
                          BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.all(
                          Radius.circular(15),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black26,
                            blurRadius: 8,
                            offset:
                                Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward,
                        color: green,
                        size: 22,
                      ),
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
