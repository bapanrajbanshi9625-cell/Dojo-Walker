// File:
// lib/services/walker_availability_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'walker_location_service.dart';

class WalkerAvailabilityService extends ChangeNotifier {
  WalkerAvailabilityService._() {
    _restoreAvailabilityState();
  }

  static final WalkerAvailabilityService instance =
      WalkerAvailabilityService._();

  static const String _onlinePreferenceKey = 'walker_online';

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  bool _isOnline = false;
  bool _isActiveWalk = false;
  bool _isChangingStatus = false;

  bool _stateRestored = false;

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
  // RESTORE SAVED AVAILABILITY STATE
  // ============================================================

  Future<void> _restoreAvailabilityState() async {
    if (_stateRestored) {
      return;
    }

    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      final bool savedOnline =
          prefs.getBool(_onlinePreferenceKey) ?? false;

      _stateRestored = true;

      // ----------------------------------------------------------
      // User was manually Offline.
      // Nothing to restore.
      // ----------------------------------------------------------

      if (!savedOnline) {
        debugPrint(
          'Walker Availability: Saved state = OFFLINE',
        );

        notifyListeners();
        return;
      }

      // ----------------------------------------------------------
      // User was Online before app/process restart.
      // Restore Online + GPS.
      // ----------------------------------------------------------

      debugPrint(
        'Walker Availability: Saved state = ONLINE. '
        'Restoring availability...',
      );

      final bool restored =
          await _restoreOnlineState();

      if (!restored) {
        debugPrint(
          'Walker Availability: Could not restore GPS tracking '
          'at startup. Online state will remain available for '
          'a future retry.',
        );
      }
    } catch (e, stackTrace) {
      debugPrint(
        'Walker Availability Restore Error: $e',
      );

      debugPrint('$stackTrace');

      _stateRestored = true;
    }
  }

  Future<bool> _restoreOnlineState() async {
    try {
      // --------------------------------------------------------
      // CHECK GPS SERVICE + PERMISSION
      // --------------------------------------------------------

      final bool permissionReady =
          await _locationService.ensurePermission();

      if (!permissionReady) {
        _setError(
          _locationService.lastError ??
              'Location permission is required to restore Online status.',
        );

        return false;
      }

      // --------------------------------------------------------
      // GET CURRENT LOCATION
      // --------------------------------------------------------

      final Position? position =
          await _locationService.getCurrentLocation();

      if (position == null) {
        _setError(
          _locationService.lastError ??
              'Unable to restore your current location.',
        );

        return false;
      }

      // --------------------------------------------------------
      // START GLOBAL TRACKING
      // --------------------------------------------------------

      final bool trackingStarted =
          await _locationService.startTracking();

      if (!trackingStarted) {
        _setError(
          _locationService.lastError ??
              'Unable to restore location tracking.',
        );

        return false;
      }

      _isOnline = true;

      _listenToGlobalLocation();

      _clearError();

      debugPrint(
        'Walker Availability: ONLINE restored.',
      );

      debugPrint(
        'Walker Availability: Restored location '
        '${position.latitude}, ${position.longitude}',
      );

      notifyListeners();

      return true;
    } catch (e, stackTrace) {
      _setError(
        'Unable to restore Online status: $e',
      );

      debugPrint(
        'Walker Availability Restore Online Error: $e',
      );

      debugPrint('$stackTrace');

      return false;
    }
  }

  Future<void> _ensureStateRestored() async {
    if (_stateRestored) {
      return;
    }

    await _restoreAvailabilityState();
  }

  // ============================================================
  // SAVE AVAILABILITY STATE
  // ============================================================

  Future<void> _saveOnlineState(bool online) async {
    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool(
        _onlinePreferenceKey,
        online,
      );

      debugPrint(
        'Walker Availability: Saved state = '
        '${online ? 'ONLINE' : 'OFFLINE'}',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Walker Availability Save State Error: $e',
      );

      debugPrint('$stackTrace');
    }
  }

  // ============================================================
  // ONLINE
  // ============================================================

  Future<bool> goOnline() async {
    await _ensureStateRestored();

    if (_isChangingStatus) {
      return false;
    }

    // ----------------------------------------------------------
    // Already Online + GPS tracking is active.
    // ----------------------------------------------------------

    if (_isOnline &&
        _locationService.isTracking) {
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

      // --------------------------------------------------------
      // Persist Online state.
      // --------------------------------------------------------

      await _saveOnlineState(true);

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
    await _ensureStateRestored();

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
      // --------------------------------------------------------
      // Explicit user Offline action must remain persisted.
      // --------------------------------------------------------

      await _saveOnlineState(false);

      return true;
    }

    _isChangingStatus = true;
    _clearError();
    notifyListeners();

    try {
      await _stopGlobalLocation();

      _isOnline = false;

      // --------------------------------------------------------
      // Persist manual Offline state.
      // --------------------------------------------------------

      await _saveOnlineState(false);

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
    await _ensureStateRestored();

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
    await _ensureStateRestored();

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
    await _ensureStateRestored();

    if (_isOnline &&
        _locationService.isTracking) {
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
    await _ensureStateRestored();

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

    // ----------------------------------------------------------
    // IMPORTANT:
    //
    // Do NOT change _isOnline to false here.
    // Do NOT save Offline here.
    //
    // The persisted state represents the walker's last explicit
    // availability choice. App shutdown must not convert Online
    // into Offline.
    // ----------------------------------------------------------

    debugPrint(
      'Walker Availability: Service cleanup completed. '
      'Persisted availability state was preserved.',
    );

    notifyListeners();
  }
}
