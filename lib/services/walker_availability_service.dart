// File:
// lib/services/walker_availability_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'walker_location_service.dart';

class WalkerAvailabilityService extends ChangeNotifier {
  WalkerAvailabilityService._();

  static final WalkerAvailabilityService instance =
      WalkerAvailabilityService._();

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  bool _isOnline = false;
  bool _isActiveWalk = false;
  bool _isChangingStatus = false;

  String? _error;

  StreamSubscription<Position>? _locationSubscription;

  // ============================================================
  // GLOBAL STATE
  // ============================================================

  bool get isOnline => _isOnline;

  bool get isOffline => !_isOnline;

  bool get isActiveWalk => _isActiveWalk;

  bool get isChangingStatus => _isChangingStatus;

  String? get error => _error;

  Position? get currentPosition =>
      _locationService.currentPosition;

  bool get hasCurrentLocation =>
      _locationService.hasCurrentLocation;

  bool get isGpsTracking =>
      _locationService.isTracking;

  Stream<Position> get locationStream =>
      _locationService.locationStream;

  // ============================================================
  // ONLINE
  // ============================================================

  Future<bool> goOnline() async {
    if (_isChangingStatus) {
      return false;
    }

    if (_isOnline) {
      return true;
    }

    _isChangingStatus = true;
    _clearError();
    notifyListeners();

    try {
      // --------------------------------------------------------
      // CHECK GPS SERVICE + PERMISSION
      // --------------------------------------------------------

      final bool permissionReady =
          await _locationService.ensurePermission();

      if (!permissionReady) {
        _setError(
          _locationService.lastError ??
              'Location permission is required to go online.',
        );
        return false;
      }

      // --------------------------------------------------------
      // GET IMMEDIATE CURRENT LOCATION
      // --------------------------------------------------------

      final Position? position =
          await _locationService.getCurrentLocation();

      if (position == null) {
        _setError(
          _locationService.lastError ??
              'Unable to get your current location.',
        );
        return false;
      }

      // --------------------------------------------------------
      // START GLOBAL CONTINUOUS TRACKING
      // --------------------------------------------------------

      final bool trackingStarted =
          await _locationService.startTracking();

      if (!trackingStarted) {
        _setError(
          _locationService.lastError ??
              'Unable to start location tracking.',
        );
        return false;
      }

      _isOnline = true;

      _listenToGlobalLocation();

      debugPrint(
        'Walker Availability: ONLINE',
      );

      debugPrint(
        'Walker Availability: Current location '
        '${position.latitude}, ${position.longitude}',
      );

      return true;
    } catch (e, stackTrace) {
      _setError(
        'Unable to go online: $e',
      );

      debugPrint(
        'Walker Availability Online Error: $e',
      );

      debugPrint('$stackTrace');

      return false;
    } finally {
      _isChangingStatus = false;
      notifyListeners();
    }
  }

  // ============================================================
  // OFFLINE
  // ============================================================

  Future<bool> goOffline() async {
    if (_isChangingStatus) {
      return false;
    }

    // ----------------------------------------------------------
    // ACTIVE WALK LOCK
    // ----------------------------------------------------------

    if (_isActiveWalk) {
      _setError(
        'You cannot go offline during an active walk.',
      );

      notifyListeners();

      debugPrint(
        'Walker Availability: Offline blocked because '
        'an active walk is running.',
      );

      return false;
    }

    if (!_isOnline) {
      return true;
    }

    _isChangingStatus = true;
    _clearError();
    notifyListeners();

    try {
      await _stopGlobalLocation();

      _isOnline = false;

      debugPrint(
        'Walker Availability: OFFLINE',
      );

      return true;
    } catch (e, stackTrace) {
      _setError(
        'Unable to go offline: $e',
      );

      debugPrint(
        'Walker Availability Offline Error: $e',
      );

      debugPrint('$stackTrace');

      return false;
    } finally {
      _isChangingStatus = false;
      notifyListeners();
    }
  }

  // ============================================================
  // TOGGLE
  // ============================================================

  Future<bool> toggleAvailability() async {
    if (_isOnline) {
      return goOffline();
    }

    return goOnline();
  }

  // ============================================================
  // ACTIVE WALK CONTROL
  // ============================================================

  /// Call this when a walk becomes active.
  ///
  /// Active walk always requires the walker to remain Online.
  Future<void> setActiveWalk(bool active) async {
    _isActiveWalk = active;

    debugPrint(
      'Walker Availability: Active Walk = $active',
    );

    if (active && !_isOnline) {
      final bool online = await goOnline();

      if (!online) {
        debugPrint(
          'Walker Availability: Could not automatically '
          'go online for active walk.',
        );
      }
    }

    notifyListeners();
  }

  // ============================================================
  // FORCE ONLINE FOR ACTIVE WALK
  // ============================================================

  Future<bool> ensureOnlineForWalk() async {
    if (_isOnline && _locationService.isTracking) {
      return true;
    }

    final bool online = await goOnline();

    if (!online) {
      _setError(
        _locationService.lastError ??
            'You must be online to continue with the walk.',
      );

      notifyListeners();
      return false;
    }

    return true;
  }

  // ============================================================
  // WALK ACTION GUARD
  // ============================================================

  bool canPerformWalkAction() {
    return _isOnline &&
        _locationService.isTracking;
  }

  String get unavailableMessage {
    if (_isActiveWalk) {
      return 'You are currently on an active walk.';
    }

    if (!_isOnline) {
      return 'Go Online to continue.';
    }

    if (!_locationService.isTracking) {
      return 'Location tracking is not active.';
    }

    return '';
  }

  // ============================================================
  // GLOBAL LOCATION STREAM
  // ============================================================

  void _listenToGlobalLocation() {
    _locationSubscription?.cancel();

    _locationSubscription =
        _locationService.locationStream.listen(
      (Position position) {
        if (!_isOnline) {
          return;
        }

        debugPrint(
          'Walker Availability Location Update: '
          '${position.latitude}, ${position.longitude}',
        );

        notifyListeners();
      },
      onError: (Object error) {
        _setError(
          'GPS tracking error: $error',
        );

        notifyListeners();

        debugPrint(
          'Walker Availability GPS Stream Error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // STOP GLOBAL LOCATION
  // ============================================================

  Future<void> _stopGlobalLocation() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;

    await _locationService.stopTracking();
  }

  // ============================================================
  // GPS STATUS
  // ============================================================

  Future<bool> isGpsEnabled() async {
    return _locationService.isLocationServiceEnabled();
  }

  Future<LocationPermission> permissionStatus() async {
    return _locationService.permissionStatus();
  }

  Future<bool> openLocationSettings() async {
    return _locationService.openLocationSettings();
  }

  Future<bool> openAppSettings() async {
    return _locationService.openAppSettings();
  }

  // ============================================================
  // REFRESH CURRENT LOCATION
  // ============================================================

  Future<Position?> refreshCurrentLocation() async {
    if (!_isOnline) {
      _setError(
        'Go Online before refreshing your location.',
      );

      notifyListeners();
      return null;
    }

    final Position? position =
        await _locationService.refreshLocation();

    if (position == null) {
      _setError(
        _locationService.lastError ??
            'Unable to refresh your location.',
      );
    } else {
      _clearError();
    }

    notifyListeners();

    return position;
  }

  // ============================================================
  // ERROR
  // ============================================================

  void _setError(String message) {
    _error = message;

    debugPrint(
      'Walker Availability Error: $message',
    );
  }

  void _clearError() {
    _error = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }

  // ============================================================
  // SHUTDOWN
  // ============================================================

  Future<void> disposeService() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;

    await _locationService.stopTracking();

    _isOnline = false;
    _isActiveWalk = false;

    notifyListeners();
  }
}
