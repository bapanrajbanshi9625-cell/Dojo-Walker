import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class WalkerLocationService {
  WalkerLocationService._();

  static final WalkerLocationService instance =
      WalkerLocationService._();

  // ============================================================
  // INTERNAL
  // ============================================================

  StreamSubscription<Position>? _positionSubscription;

  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  Position? _currentPosition;

  bool _tracking = false;
  bool _startingTracking = false;

  String? _lastError;

  // ============================================================
  // GETTERS
  // ============================================================

  Stream<Position> get locationStream =>
      _locationController.stream;

  Position? get currentPosition => _currentPosition;

  bool get isTracking => _tracking;

  String? get lastError => _lastError;

  bool get hasCurrentLocation =>
      _currentPosition != null;

  // ============================================================
  // LOCATION SERVICE STATUS
  // ============================================================

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      _setError(
        'Unable to check GPS status: $e',
      );
      return false;
    }
  }

  // ============================================================
  // PERMISSION STATUS
  // ============================================================

  Future<LocationPermission> permissionStatus() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      _setError(
        'Unable to check location permission: $e',
      );

      return LocationPermission.denied;
    }
  }

  // ============================================================
  // CHECK LOCATION + PERMISSION
  //
  // This is the main gate for the entire Walker location system.
  // ============================================================

  Future<bool> ensurePermission() async {
    _clearError();

    // ----------------------------------------------------------
    // 1. CHECK GPS / LOCATION SERVICE
    // ----------------------------------------------------------

    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      _setError(
        'Location services are disabled. '
        'Please turn on GPS.',
      );

      debugPrint(
        'Walker Location: GPS is disabled.',
      );

      return false;
    }

    // ----------------------------------------------------------
    // 2. CHECK CURRENT PERMISSION
    // ----------------------------------------------------------

    LocationPermission permission =
        await Geolocator.checkPermission();

    debugPrint(
      'Walker Location Permission: $permission',
    );

    // ----------------------------------------------------------
    // 3. REQUEST PERMISSION
    // ----------------------------------------------------------

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();

      debugPrint(
        'Walker Location Permission After Request: '
        '$permission',
      );
    }

    // ----------------------------------------------------------
    // 4. PERMANENTLY DENIED
    // ----------------------------------------------------------

    if (permission ==
        LocationPermission.deniedForever) {
      _setError(
        'Location permission is permanently denied. '
        'Please allow location permission from Settings.',
      );

      debugPrint(
        'Walker Location: Permission permanently denied.',
      );

      return false;
    }

    // ----------------------------------------------------------
    // 5. NORMAL DENIED
    // ----------------------------------------------------------

    if (permission ==
        LocationPermission.denied) {
      _setError(
        'Location permission was denied.',
      );

      debugPrint(
        'Walker Location: Permission denied.',
      );

      return false;
    }

    // ----------------------------------------------------------
    // 6. VALID PERMISSION
    // ----------------------------------------------------------

    if (permission ==
            LocationPermission.whileInUse ||
        permission ==
            LocationPermission.always) {
      debugPrint(
        'Walker Location: Permission granted.',
      );

      return true;
    }

    _setError(
      'Location permission is unavailable.',
    );

    return false;
  }

  // ============================================================
  // OPEN LOCATION SETTINGS
  // ============================================================

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      _setError(
        'Unable to open location settings: $e',
      );

      return false;
    }
  }

  // ============================================================
  // OPEN APP SETTINGS
  //
  // Useful when permission is deniedForever.
  // ============================================================

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      _setError(
        'Unable to open app settings: $e',
      );

      return false;
    }
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<Position?> getCurrentLocation({
    Duration timeout =
        const Duration(seconds: 15),
  }) async {
    _clearError();

    // ----------------------------------------------------------
    // PERMISSION + GPS
    // ----------------------------------------------------------

    final bool allowed =
        await ensurePermission();

    if (!allowed) {
      return null;
    }

    // ----------------------------------------------------------
    // GET GPS POSITION
    // ----------------------------------------------------------

    try {
      debugPrint(
        'Walker Location: Requesting current GPS position...',
      );

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(
        timeout,
      );

      _updatePosition(position);

      debugPrint(
        'Walker Location: '
        '${position.latitude}, '
        '${position.longitude}',
      );

      return position;
    } on TimeoutException {
      _setError(
        'GPS location request timed out.',
      );

      debugPrint(
        'Walker Location: GPS timeout.',
      );

      return null;
    } on LocationServiceDisabledException {
      _setError(
        'Location services are disabled.',
      );

      debugPrint(
        'Walker Location: Location service disabled.',
      );

      return null;
    } on PermissionDeniedException {
      _setError(
        'Location permission was denied.',
      );

      debugPrint(
        'Walker Location: Permission denied.',
      );

      return null;
    } catch (e, stackTrace) {
      _setError(
        'Unable to get current location: $e',
      );

      debugPrint(
        'Walker Location Error: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      return null;
    }
  }

  // ============================================================
  // START CONTINUOUS GPS TRACKING
  // ============================================================

  Future<bool> startTracking() async {
    _clearError();

    // ----------------------------------------------------------
    // ALREADY TRACKING
    // ----------------------------------------------------------

    if (_tracking) {
      debugPrint(
        'Walker Location: Tracking already active.',
      );

      return true;
    }

    // ----------------------------------------------------------
    // PREVENT DOUBLE START
    // ----------------------------------------------------------

    if (_startingTracking) {
      return false;
    }

    _startingTracking = true;

    try {
      // --------------------------------------------------------
      // PERMISSION + GPS
      // --------------------------------------------------------

      final bool allowed =
          await ensurePermission();

      if (!allowed) {
        return false;
      }

      // --------------------------------------------------------
      // CANCEL OLD SUBSCRIPTION SAFELY
      // --------------------------------------------------------

      await _positionSubscription?.cancel();

      _positionSubscription = null;

      // --------------------------------------------------------
      // LOCATION SETTINGS
      // --------------------------------------------------------

      const LocationSettings settings =
          LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      debugPrint(
        'Walker Location: Starting continuous GPS...',
      );

      // --------------------------------------------------------
      // START STREAM
      // --------------------------------------------------------

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (Position position) {
          _updatePosition(position);

          debugPrint(
            'Walker GPS Update: '
            '${position.latitude}, '
            '${position.longitude}',
          );
        },
        onError: (Object error) {
          _setError(
            'GPS stream error: $error',
          );

          debugPrint(
            'Walker GPS Stream Error: $error',
          );
        },
        cancelOnError: false,
      );

      _tracking = true;

      debugPrint(
        'Walker Location: Continuous GPS started.',
      );

      return true;
    } on LocationServiceDisabledException {
      _setError(
        'Location services are disabled.',
      );

      return false;
    } on PermissionDeniedException {
      _setError(
        'Location permission was denied.',
      );

      return false;
    } catch (e, stackTrace) {
      _setError(
        'Unable to start GPS tracking: $e',
      );

      debugPrint(
        'Walker Start GPS Error: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      return false;
    } finally {
      _startingTracking = false;
    }
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> stopTracking() async {
    try {
      await _positionSubscription?.cancel();
    } catch (e) {
      debugPrint(
        'Walker Location Stop Error: $e',
      );
    }

    _positionSubscription = null;
    _tracking = false;

    debugPrint(
      'Walker Location: GPS tracking stopped.',
    );
  }

  // ============================================================
  // FORCE REFRESH CURRENT LOCATION
  // ============================================================

  Future<Position?> refreshLocation() async {
    return getCurrentLocation();
  }

  // ============================================================
  // UPDATE CURRENT POSITION
  // ============================================================

  void _updatePosition(Position position) {
    _currentPosition = position;

    if (!_locationController.isClosed) {
      _locationController.add(position);
    }
  }

  // ============================================================
  // DISTANCE BETWEEN WALKER AND REQUEST
  // ============================================================

  double distanceInKm({
    required double walkerLatitude,
    required double walkerLongitude,
    required double requestLatitude,
    required double requestLongitude,
  }) {
    final double meters =
        Geolocator.distanceBetween(
      walkerLatitude,
      walkerLongitude,
      requestLatitude,
      requestLongitude,
    );

    return meters / 1000;
  }

  // ============================================================
  // ERROR CONTROL
  // ============================================================

  void _setError(String message) {
    _lastError = message;

    debugPrint(
      'Walker Location Status: $message',
    );
  }

  void _clearError() {
    _lastError = null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stopTracking();

    if (!_locationController.isClosed) {
      await _locationController.close();
    }

    _currentPosition = null;
  }
}
