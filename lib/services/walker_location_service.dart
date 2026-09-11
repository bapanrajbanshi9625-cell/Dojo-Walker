import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class WalkerLocationService {
  WalkerLocationService._();

  static final WalkerLocationService instance =
      WalkerLocationService._();

  StreamSubscription<Position>? _positionSubscription;

  StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  Stream<Position> get locationStream =>
      _locationController.stream;

  Position? _currentPosition;

  bool _tracking = false;
  bool _startingTracking = false;
  bool _disposed = false;

  String? _lastError;

  Position? get currentPosition => _currentPosition;

  bool get isTracking => _tracking;

  bool get hasCurrentLocation =>
      _currentPosition != null;

  String? get lastError => _lastError;

  // ==========================================================
  // ENSURE STREAM IS READY
  //
  // This service is a singleton.
  // The stream must remain reusable after stopTracking().
  // ==========================================================

  void _ensureStreamController() {
    if (_locationController.isClosed) {
      _locationController =
          StreamController<Position>.broadcast();
    }

    _disposed = false;
  }

  // ==========================================================
  // GPS SERVICE STATUS
  // ==========================================================

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      _setError(
        'Unable to check GPS status: $e',
      );

      debugPrint(
        'Walker Location GPS Check Error: $e',
      );

      return false;
    }
  }

  // ==========================================================
  // PERMISSION STATUS
  // ==========================================================

  Future<LocationPermission> permissionStatus() async {
    try {
      return await Geolocator.checkPermission();
    } catch (e) {
      _setError(
        'Unable to check location permission: $e',
      );

      debugPrint(
        'Walker Location Permission Check Error: $e',
      );

      return LocationPermission.denied;
    }
  }

  // ==========================================================
  // ENSURE LOCATION PERMISSION
  // ==========================================================

  Future<bool> ensurePermission() async {
    _clearError();
    _ensureStreamController();

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _setError(
          'Location services are disabled. Please turn on GPS.',
        );

        debugPrint(
          'Walker Location: GPS is disabled.',
        );

        return false;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      debugPrint(
        'Walker Location Permission: $permission',
      );

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();

        debugPrint(
          'Walker Location Permission After Request: '
          '$permission',
        );
      }

      if (permission ==
          LocationPermission.deniedForever) {
        _setError(
          'Location permission is permanently denied. '
          'Please allow location permission from app settings.',
        );

        debugPrint(
          'Walker Location: Permission permanently denied.',
        );

        return false;
      }

      if (permission == LocationPermission.denied) {
        _setError(
          'Location permission was denied.',
        );

        debugPrint(
          'Walker Location: Permission denied.',
        );

        return false;
      }

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
    } catch (e, stackTrace) {
      _setError(
        'Unable to verify location permission: $e',
      );

      debugPrint(
        'Walker Location Permission Error: $e',
      );

      debugPrint('$stackTrace');

      return false;
    }
  }

  // ==========================================================
  // OPEN LOCATION SETTINGS
  // ==========================================================

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (e) {
      _setError(
        'Unable to open location settings: $e',
      );

      debugPrint(
        'Walker Location Settings Error: $e',
      );

      return false;
    }
  }

  // ==========================================================
  // OPEN APP SETTINGS
  // ==========================================================

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (e) {
      _setError(
        'Unable to open app settings: $e',
      );

      debugPrint(
        'Walker App Settings Error: $e',
      );

      return false;
    }
  }

  // ==========================================================
  // GET CURRENT LOCATION
  // ==========================================================

  Future<Position?> getCurrentLocation({
    Duration timeout =
        const Duration(seconds: 15),
  }) async {
    _clearError();

    final bool allowed =
        await ensurePermission();

    if (!allowed) {
      return null;
    }

    try {
      debugPrint(
        'Walker Location: Requesting current GPS position...',
      );

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(timeout);

      _updatePosition(position);

      debugPrint(
        'Walker Location Acquired: '
        '${position.latitude}, '
        '${position.longitude}',
      );

      debugPrint(
        'Walker GPS Accuracy: '
        '${position.accuracy}m',
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
        'Walker Location: GPS disabled while '
        'requesting position.',
      );

      return null;
    } on PermissionDeniedException {
      _setError(
        'Location permission was denied.',
      );

      debugPrint(
        'Walker Location: Permission denied while '
        'requesting position.',
      );

      return null;
    } catch (e, stackTrace) {
      _setError(
        'Unable to get current location: $e',
      );

      debugPrint(
        'Walker Location Error: $e',
      );

      debugPrint('$stackTrace');

      return null;
    }
  }

  // ==========================================================
  // START CONTINUOUS TRACKING
  //
  // ACCEPT
  //   ↓
  // GPS ON
  //
  // REACHED
  //   ↓
  // GPS stays ON
  //
  // LIVE
  //   ↓
  // GPS stays ON
  //
  // COMPLETE
  //   ↓
  // GPS OFF
  // ==========================================================

  Future<bool> startTracking() async {
    _clearError();
    _ensureStreamController();

    if (_tracking) {
      debugPrint(
        'Walker Location: Tracking already active.',
      );

      return true;
    }

    if (_startingTracking) {
      debugPrint(
        'Walker Location: Tracking is already starting.',
      );

      return false;
    }

    _startingTracking = true;

    try {
      final bool allowed =
          await ensurePermission();

      if (!allowed) {
        return false;
      }

      await _positionSubscription?.cancel();

      _positionSubscription = null;

      final LocationSettings settings =
          _buildLocationSettings();

      debugPrint(
        'Walker Location: Starting continuous GPS...',
      );

      final Stream<Position> positionStream =
          Geolocator.getPositionStream(
        locationSettings: settings,
      );

      _positionSubscription =
          positionStream.listen(
        (Position position) {
          if (_disposed) {
            return;
          }

          _updatePosition(position);

          debugPrint(
            'Walker GPS Update: '
            '${position.latitude}, '
            '${position.longitude} '
            '| accuracy=${position.accuracy}m '
            '| speed=${position.speed}m/s '
            '| heading=${position.heading}',
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

      debugPrint(
        'Walker Location: GPS disabled while '
        'starting tracking.',
      );

      await _cleanupTrackingSubscription();

      return false;
    } on PermissionDeniedException {
      _setError(
        'Location permission was denied.',
      );

      debugPrint(
        'Walker Location: Permission denied while '
        'starting tracking.',
      );

      await _cleanupTrackingSubscription();

      return false;
    } catch (e, stackTrace) {
      _setError(
        'Unable to start GPS tracking: $e',
      );

      debugPrint(
        'Walker Start GPS Error: $e',
      );

      debugPrint('$stackTrace');

      await _cleanupTrackingSubscription();

      return false;
    } finally {
      _startingTracking = false;
    }
  }

  // ==========================================================
  // STOP CONTINUOUS TRACKING
  //
  // This only stops the canonical GPS service.
  // LiveWalkBackgroundService remains separate.
  // ==========================================================

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
    _startingTracking = false;

    debugPrint(
      'Walker Location: GPS tracking stopped.',
    );
  }

  Future<void> _cleanupTrackingSubscription() async {
    try {
      await _positionSubscription?.cancel();
    } catch (e) {
      debugPrint(
        'Walker Location Cleanup Error: $e',
      );
    }

    _positionSubscription = null;
    _tracking = false;
  }

  // ==========================================================
  // REFRESH LOCATION
  // ==========================================================

  Future<Position?> refreshLocation() async {
    return getCurrentLocation();
  }

  // ==========================================================
  // LOCATION SETTINGS
  // ==========================================================

  LocationSettings _buildLocationSettings() {
    if (defaultTargetPlatform ==
        TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
        intervalDuration:
            const Duration(seconds: 5),
        foregroundNotificationConfig:
            const ForegroundNotificationConfig(
          notificationTitle: 'Dojo Walker',
          notificationText:
              'Live walk location tracking is active.',
          notificationChannelName:
              'Dojo Walker Live Tracking',
          enableWakeLock: true,
          enableWifiLock: true,
          setOngoing: true,
        ),
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
  }

  // ==========================================================
  // UPDATE CURRENT POSITION
  // ==========================================================

  void _updatePosition(Position position) {
    if (_disposed) {
      return;
    }

    _currentPosition = position;

    if (!_locationController.isClosed) {
      _locationController.add(position);
    }
  }

  // ==========================================================
  // DISTANCE TO REQUEST / OWNER
  // ==========================================================

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

  // ==========================================================
  // ERROR STATE
  // ==========================================================

  void _setError(String message) {
    _lastError = message;

    debugPrint(
      'Walker Location Status: $message',
    );
  }

  void _clearError() {
    _lastError = null;
  }

  // ==========================================================
  // DISPOSE
  //
  // IMPORTANT:
  // This singleton must NOT permanently close the stream
  // during normal walk transitions.
  //
  // stopTracking() is the normal lifecycle operation.
  // dispose() is kept only for final app/service shutdown.
  // ==========================================================

  Future<void> dispose() async {
    _disposed = true;

    await stopTracking();

    if (!_locationController.isClosed) {
      await _locationController.close();
    }

    _currentPosition = null;
  }
}
