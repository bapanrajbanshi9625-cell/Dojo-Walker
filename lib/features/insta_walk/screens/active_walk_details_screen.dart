// File:
// lib/features/insta_walk/screens/active_walk_details_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../walks/models/walk_request.dart';
import '../../walks/services/walk_request_service.dart';

class ActiveWalkDetailsScreen extends StatefulWidget {
  final WalkRequest request;

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

  final WalkRequestService _walkService =
      WalkRequestService.instance;

  // ============================================================
  // COLORS
  // ============================================================

  static const Color orange = Color(0xFFFF6600);
  static const Color navy = Color(0xFF263746);
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

  String _liveStatus = 'active';

  StreamSubscription<dynamic>? _activeWalkSubscription;
  StreamSubscription<dynamic>? _liveSessionSubscription;

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

    _loadInitialLocations();

    _sheetController.addListener(_onSheetChanged);

    _listenToActiveWalk();
    _listenToLiveSession();
  }

  // ============================================================
  // INITIAL LOCATIONS
  // ============================================================

  void _loadInitialLocations() {
    final WalkRequest request = widget.request;

    if (request.hasCurrentLocation) {
      _walkerLocation = LatLng(
        request.currentLat,
        request.currentLng,
      );
    }

    if (request.hasPickupLocation) {
      _pickupLocation = LatLng(
        request.pickupLat,
        request.pickupLng,
      );
    }

    if (request.hasDestinationLocation) {
      _destinationLocation = LatLng(
        request.destinationLat,
        request.destinationLng,
      );
    }

    _distanceKm = request.distanceKm;
  }

  // ============================================================
  // ACTIVE WALK REALTIME
  // ============================================================

  void _listenToActiveWalk() {
    final String walkId = _resolveWalkId();

    if (walkId.isEmpty) {
      return;
    }

    _activeWalkSubscription =
        _walkService.activeWalkStream(walkId).listen(
      (snapshot) {
        if (!mounted || !snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        _applyActiveWalkData(data);
      },
      onError: (Object error) {
        debugPrint(
          'Active walk stream error: $error',
        );
      },
    );
  }

  // ============================================================
  // LIVE SESSION REALTIME
  // ============================================================

  void _listenToLiveSession() {
    final String sessionId = _resolveSessionId();

    if (sessionId.isEmpty) {
      return;
    }

    _liveSessionSubscription =
        _walkService.liveWalkSessionStream(sessionId).listen(
      (snapshot) {
        if (!mounted || !snapshot.exists) {
          return;
        }

        final Map<String, dynamic>? data =
            snapshot.data();

        if (data == null) {
          return;
        }

        _applyLiveSessionData(data);
      },
      onError: (Object error) {
        debugPrint(
          'Live session stream error: $error',
        );
      },
    );
  }

  // ============================================================
  // ACTIVE WALK DATA
  // ============================================================

  void _applyActiveWalkData(
    Map<String, dynamic> data,
  ) {
    final double latitude =
        _readDouble(data['currentLat']);

    final double longitude =
        _readDouble(data['currentLng']);

    if (_validCoordinate(latitude, longitude)) {
      final LatLng newLocation =
          LatLng(latitude, longitude);

      if (mounted) {
        setState(() {
          _walkerLocation = newLocation;
        });
      }
    }

    final double distance =
        _readDouble(data['distanceKm']);

    final int elapsed =
        _readInt(data['elapsedSeconds']);

    final int steps =
        _readInt(data['steps']);

    final String status =
        _readString(data['status']);

    if (!mounted) {
      return;
    }

    setState(() {
      if (distance > 0) {
        _distanceKm = distance;
      }

      _elapsedSeconds = elapsed;
      _steps = steps;

      if (status.isNotEmpty) {
        _liveStatus = status;
      }
    });
  }

  // ============================================================
  // LIVE SESSION DATA
  // ============================================================

  void _applyLiveSessionData(
    Map<String, dynamic> data,
  ) {
    final Map<String, dynamic>? location =
        _readMap(data['currentLocation']);

    if (location != null) {
      final double latitude = _readDouble(
        location['lat'] ?? location['latitude'],
      );

      final double longitude = _readDouble(
        location['lng'] ?? location['longitude'],
      );

      if (_validCoordinate(latitude, longitude)) {
        final LatLng newLocation =
            LatLng(latitude, longitude);

        if (!mounted) {
          return;
        }

        setState(() {
          _walkerLocation = newLocation;
        });
      }
    }

    final double distance =
        _readDouble(data['distanceKm']);

    final int elapsed =
        _readInt(data['elapsedSeconds']);

    final int steps =
        _readInt(data['steps']);

    final String status =
        _readString(data['status']);

    if (!mounted) {
      return;
    }

    setState(() {
      if (distance > 0) {
        _distanceKm = distance;
      }

      _elapsedSeconds = elapsed;
      _steps = steps;

      if (status.isNotEmpty) {
        _liveStatus = status;
      }
    });
  }

  // ============================================================
  // WALK ID
  // ============================================================

  String _resolveWalkId() {
    final String walkId =
        widget.request.walkId.trim();

    if (walkId.isNotEmpty) {
      return walkId;
    }

    final String qrWalkId =
        widget.request.qrWalkId.trim();

    return qrWalkId;
  }

  // ============================================================
  // SESSION ID
  // ============================================================

  String _resolveSessionId() {
    final String sessionId =
        widget.request.liveWalkSessionId.trim();

    if (sessionId.isNotEmpty) {
      return sessionId;
    }

    final String walkId =
        _resolveWalkId();

    if (walkId.isEmpty) {
      return '';
    }

    return 'session-$walkId';
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
              iconColor: orange,
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
    final bool isActive =
        _liveStatus.toLowerCase() == 'active';

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
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: 8,
                    color: isActive
                        ? const Color(0xFF18A957)
                        : const Color(0xFFFFA000),
                 
