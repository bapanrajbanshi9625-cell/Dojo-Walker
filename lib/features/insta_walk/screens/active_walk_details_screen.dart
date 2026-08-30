import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../models/insta_walk_request.dart';
import '../services/insta_walk_service.dart';
import '../widgets/active_walk_bottom_sheet.dart';
import '../widgets/active_walk_map.dart';
import '../widgets/active_walk_top_bar.dart';

import '../../live_walk/controllers/live_walk_controller.dart';

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
  // LIVE WALK CONTROLLER
  // ============================================================

  late final LiveWalkController _liveWalkController;

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
  // FIRESTORE SUBSCRIPTION
  // ============================================================

  StreamSubscription<
          DocumentSnapshot<Map<String, dynamic>>>?
      _walkSubscription;

  // ============================================================
  // REACHED
  // ============================================================

  bool _reached = false;

  // ============================================================
  // BOTTOM SHEET
  // ============================================================

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  bool _sheetExpanded = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _createController();
    _loadInitialData();

    _sheetController.addListener(
      _onSheetChanged,
    );

    _listenToWalk();
    _initializeController();
  }

  // ============================================================
  // CREATE CONTROLLER
  // ============================================================

  void _createController() {
    _liveWalkController = LiveWalkController(
      ownerUid: widget.request.ownerUid,
      ownerName: widget.request.ownerName,
      walkId: widget.request.id,
      dogName: widget.request.dogName,
      dogBreed: widget.request.dogBreed,
      ownerPhone: widget.request.ownerPhone,
      sessionId: widget.request.liveWalkSessionId,
    );

    _liveWalkController.addListener(
      _onControllerChanged,
    );
  }

  // ============================================================
  // CONTROLLER LISTENER
  // ============================================================

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }

    setState(() {});
  }

  // ============================================================
  // INITIALIZE CONTROLLER
  // ============================================================

  Future<void> _initializeController() async {
    try {
      await _liveWalkController.initialize();
    } catch (e) {
      debugPrint(
        'LiveWalkController initialize error: $e',
      );
    }
  }

  // ============================================================
  // INITIAL DATA
  // ============================================================

  void _loadInitialData() {
    final InstaWalkRequest request = widget.request;

    final double latitude = request.latitude ?? 0.0;
    final double longitude = request.longitude ?? 0.0;

    if (_validCoordinate(
      latitude,
      longitude,
    )) {
      _pickupLocation = LatLng(
        latitude,
        longitude,
      );
    }

    _distanceKm = request.distanceKm;

    final String status = request.status.trim();

    if (status.isNotEmpty) {
      _liveStatus = status;
    }
  }

  // ============================================================
  // FIRESTORE LISTENER
  // ============================================================

  void _listenToWalk() {
    final String walkId = widget.request.id.trim();

    if (walkId.isEmpty) {
      debugPrint(
        'ActiveWalkDetailsScreen: walkId is empty.',
      );
      return;
    }

    _walkSubscription = _instaWalkService
        .watchWalk(walkId)
        .listen(
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
          'Active walk stream error: $error',
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
    final String status = _readString(
      data['status'],
    );

    final double distance = _readDouble(
      data['distanceKm'],
    );

    final int elapsed = _readInt(
      data['elapsedSeconds'],
    );

    final int steps = _readInt(
      data['steps'],
    );

    // ==========================================================
    // PICKUP LOCATION
    // ==========================================================

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

    // ==========================================================
    // DESTINATION LOCATION
    // ==========================================================

    LatLng? destination;

    final Map<String, dynamic>? destinationMap =
        _readMap(
      data['destinationLocation'],
    );

    if (destinationMap != null) {
      final double lat = _readDouble(
        destinationMap['lat'] ??
            destinationMap['latitude'],
      );

      final double lng = _readDouble(
        destinationMap['lng'] ??
            destinationMap['longitude'],
      );

      if (_validCoordinate(
        lat,
        lng,
      )) {
        destination = LatLng(
          lat,
          lng,
        );
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

      if (_validCoordinate(
        lat,
        lng,
      )) {
        destination = LatLng(
          lat,
          lng,
        );
      }
    }

    // ==========================================================
    // WALKER LIVE LOCATION
    // ==========================================================

    LatLng? walker;

    final Map<String, dynamic>? currentLocation =
        _readMap(
      data['currentLocation'],
    );

    if (currentLocation != null) {
      final double lat = _readDouble(
        currentLocation['lat'] ??
            currentLocation['latitude'],
      );

      final double lng = _readDouble(
        currentLocation['lng'] ??
            currentLocation['longitude'],
      );

      if (_validCoordinate(
        lat,
        lng,
      )) {
        walker = LatLng(
          lat,
          lng,
        );
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

      if (_validCoordinate(
        lat,
        lng,
      )) {
        walker = LatLng(
          lat,
          lng,
        );
      }
    }

    // ==========================================================
    // REACHED STATE
    // ==========================================================

    final bool firestoreReached =
        data['reached'] == true ||
        data['walkerReached'] == true ||
        data['ownerReached'] == true;

    // ==========================================================
    // UPDATE UI
    // ==========================================================

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

      if (firestoreReached) {
        _reached = true;
      }
    });

    // ==========================================================
    // UPDATE LIVE SESSION CONTROLLER
    // ==========================================================

    _liveWalkController.updateFromSession(
      data,
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
  // END WALK
  //
  // Start Walk intentionally NOT handled here.
  // Start Walk is handled by Live Walk screen.
  // ============================================================

  Future<void> endWalk() async {
    try {
      await _liveWalkController.endWalk();

      if (!mounted) {
        return;
      }

      setState(() {
        _liveStatus = 'completed';
      });

      _showMessage(
        'Walk completed successfully.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    }
  }

  // ============================================================
  // SHEET LISTENER
  // ============================================================

  void _onSheetChanged() {
    if (!_sheetController.isAttached) {
      return;
    }

    final bool expanded =
        _sheetController.size > 0.55;

    if (_sheetExpanded != expanded &&
        mounted) {
      setState(() {
        _sheetExpanded = expanded;
      });
    }
  }

  // ============================================================
  // EXPAND SHEET
  // ============================================================

  void _expandSheet() {
    if (!_sheetController.isAttached) {
      return;
    }

    _sheetController.animateTo(
      0.90,
      duration: const Duration(
        milliseconds: 350,
      ),
      curve: Curves.easeOut,
    );
  }

  // ============================================================
  // COLLAPSE SHEET
  // ============================================================

  void _collapseSheet() {
    if (!_sheetController.isAttached) {
      return;
    }

    _sheetController.animateTo(
      0.25,
      duration: const Duration(
        milliseconds: 300,
      ),
      curve: Curves.easeOut,
    );
  }

  // ============================================================
  // TOGGLE SHEET
  // ============================================================

  void _toggleSheet() {
    if (_sheetExpanded) {
      _collapseSheet();
    } else {
      _expandSheet();
    }
  }

  // ============================================================
  // MOVE MAP TO WALKER
  // ============================================================

  void _moveToWalker() {
    final LatLng? location = _walkerLocation;

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
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor: AppColors.cardBackground,
      body: Stack(
        children: [
          // ======================================================
          // MAP
          // ======================================================

          Positioned.fill(
            child: ActiveWalkMap(
              mapController: _mapController,
              walkerLocation: _walkerLocation,
              pickupLocation: _pickupLocation,
              destinationLocation: _destinationLocation,
            ),
          ),

          // ======================================================
          // TOP BAR
          // ======================================================

          ActiveWalkTopBar(
            status: _liveStatus,
            onBack: () {
              Navigator.of(context).pop();
            },
          ),

          // ======================================================
          // MY LOCATION BUTTON
          // ======================================================

          Positioned(
            right: 16,
            bottom: _sheetExpanded ? 700 : 190,
            child: _MapLocationButton(
              onPressed: _moveToWalker,
            ),
          ),

          // ======================================================
          // BOTTOM SHEET
          // ======================================================

          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.25,
            minChildSize: 0.25,
            maxChildSize: 0.90,
            snap: true,
            snapSizes: const [
              0.25,
              0.90,
            ],
            builder: (
              BuildContext context,
              ScrollController controller,
            ) {
              return ActiveWalkBottomSheet(
                controller: controller,
                request: widget.request,
                liveStatus: _liveStatus,
                distanceKm: _distanceKm,
                elapsedSeconds: _elapsedSeconds,
                steps: _steps,
                reached: _reached,
                onExpand: _expandSheet,
                onToggleSheet: _toggleSheet,
                onReached: _handleReached,
                onMessage: _showMessage,
              );
            },
          ),
        ],
      ),
    );
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
          duration: const Duration(
            seconds: 2,
          ),
        ),
      );
  }

  // ============================================================
  // READ STRING
  // ============================================================

  static String _readString(
    dynamic value,
  ) {
    return value?.toString().trim() ?? '';
  }

  // ============================================================
  // READ DOUBLE
  // ============================================================

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

  // ============================================================
  // READ INT
  // ============================================================

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

  // ============================================================
  // READ MAP
  // ============================================================

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

  // ============================================================
  // VALID COORDINATE
  // ============================================================

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

    _liveWalkController.removeListener(
      _onControllerChanged,
    );

    _liveWalkController.dispose();

    super.dispose();
  }
}

// ============================================================================
// MAP LOCATION BUTTON
// ============================================================================

class _MapLocationButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _MapLocationButton({
    required this.onPressed,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Material(
      color: AppColors.cardBackground,
      elevation: 5,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 46,
          height: 46,
          child: Icon(
            Icons.my_location_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
