// File:
// lib/services/walker_availability_service.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'walker_location_service.dart';

enum WalkerWalkType {
  instaWalk,
  dailyWalk,
}

class WalkerAvailabilityService extends ChangeNotifier {
  WalkerAvailabilityService._() {
    _restoreFuture = _restoreAvailabilityState();
  }

  static final WalkerAvailabilityService instance =
      WalkerAvailabilityService._();

  static const String _onlinePreferenceKey = 'walker_online';
  static const String _walkTypePreferenceKey = 'walker_walk_type';

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  late final Future<void> _restoreFuture;

  bool _isOnline = false;
  bool _isActiveWalk = false;
  bool _isChangingStatus = false;
  bool _stateRestored = false;

  WalkerWalkType? _selectedWalkType;

  // IMPORTANT:
  // Going Online does NOT automatically start Insta Walk search.
  bool _isInstaWalkSearching = false;

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

  WalkerWalkType? get selectedWalkType =>
      _selectedWalkType;

  bool get isInstaWalkSelected =>
      _selectedWalkType == WalkerWalkType.instaWalk;

  bool get isDailyWalkSelected =>
      _selectedWalkType == WalkerWalkType.dailyWalk;

  bool get isInstaWalkSearching =>
      _isInstaWalkSearching;

  bool get isDailyWalkMode =>
      _isOnline &&
      _selectedWalkType == WalkerWalkType.dailyWalk;

  Future<void> get ready => _restoreFuture;

  // ============================================================
  // RESTORE SAVED STATE
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

      final String savedWalkType =
          prefs.getString(_walkTypePreferenceKey) ?? '';

      if (savedWalkType == 'dailyWalk') {
        _selectedWalkType =
            WalkerWalkType.dailyWalk;
      } else if (savedWalkType == 'instaWalk') {
        _selectedWalkType =
            WalkerWalkType.instaWalk;
      }

      if (!savedOnline) {
        _isOnline = false;
        _isInstaWalkSearching = false;
        _stateRestored = true;

        debugPrint(
          'Walker Availability: Saved state = OFFLINE',
        );

        notifyListeners();
        return;
      }

      debugPrint(
        'Walker Availability: Saved state = ONLINE. '
        'Restoring availability...',
      );

      final bool restored =
          await _restoreOnlineState();

      if (!restored) {
        debugPrint(
          'Walker Availability: Could not restore GPS tracking. '
          'Walker remains Offline.',
        );
      }

      // IMPORTANT:
      // App restart must never automatically start Insta search.
      _isInstaWalkSearching = false;

      _stateRestored = true;
    } catch (e, stackTrace) {
      _stateRestored = true;

      debugPrint(
        'Walker Availability Restore Error: $e',
      );

      debugPrint('$stackTrace');
    }
  }

  Future<bool> _restoreOnlineState() async {
    try {
      final bool permissionReady =
          await _locationService.ensurePermission();

      if (!permissionReady) {
        _setError(
          _locationService.lastError ??
              'Location permission is required to restore Online status.',
        );

        return false;
      }

      final Position? position =
          await _locationService.getCurrentLocation();

      if (position == null) {
        _setError(
          _locationService.lastError ??
              'Unable to restore your current location.',
        );

        return false;
      }

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
    await _restoreFuture;
  }

  // ============================================================
  // WALK TYPE
  // ============================================================

  Future<void> setWalkType(
    WalkerWalkType walkType,
  ) async {
    await _ensureStateRestored();

    _selectedWalkType = walkType;

    // Changing mode always stops Insta search.
    _isInstaWalkSearching = false;

    try {
      final SharedPreferences prefs =
          await SharedPreferences.getInstance();

      await prefs.setString(
        _walkTypePreferenceKey,
        walkType == WalkerWalkType.instaWalk
            ? 'instaWalk'
            : 'dailyWalk',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Walker Availability Save Walk Type Error: $e',
      );
      debugPrint('$stackTrace');
    }

    debugPrint(
      'Walker Availability: Walk Type = '
      '${walkType == WalkerWalkType.instaWalk ? 'INSTA WALK' : 'DAILY WALK'}',
    );

    notifyListeners();
  }

  // ============================================================
  // INSTA WALK SEARCH
  // ============================================================

  Future<bool> startInstaWalkSearch() async {
    await _ensureStateRestored();

    if (!_isOnline) {
      _setError(
        'Go Online before starting Insta Walk search.',
      );

      notifyListeners();
      return false;
    }

    if (_selectedWalkType != WalkerWalkType.instaWalk) {
      _setError(
        'Choose Insta Walk before starting search.',
      );

      notifyListeners();
      return false;
    }

    _isInstaWalkSearching = true;

    _clearError();

    debugPrint(
      'Walker Availability: INSTA WALK SEARCH = ON',
    );

    notifyListeners();

    return true;
  }

  void stopInstaWalkSearch() {
    if (!_isInstaWalkSearching) {
      return;
    }

    _isInstaWalkSearching = false;

    debugPrint(
      'Walker Availability: INSTA WALK SEARCH = OFF',
    );

    notifyListeners();
  }

  // ============================================================
  // SAVE AVAILABILITY
  // ============================================================

  Future<void> _saveOnlineState(
    bool online,
  ) async {
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

    if (_isOnline &&
        _locationService.isTracking) {
      return true;
    }

    _isChangingStatus = true;
    _clearError();
    notifyListeners();

    try {
      final bool permissionReady =
          await _locationService.ensurePermission();

      if (!permissionReady) {
        _setError(
          _locationService.lastError ??
              'Location permission is required to go online.',
        );

        return false;
      }

      final Position? position =
          await _locationService.getCurrentLocation();

      if (position == null) {
        _setError(
          _locationService.lastError ??
              'Unable to get your current location.',
        );

        return false;
      }

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

      // IMPORTANT:
      // Online does NOT mean Insta Walk search.
      _isInstaWalkSearching = false;

      _listenToGlobalLocation();

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

    if (_isActiveWalk) {
      _setError(
        'You cannot go offline during an active walk.',
      );

      notifyListeners();

      return false;
    }

    if (!_isOnline) {
      _isInstaWalkSearching = false;

      await _saveOnlineState(false);

      return true;
    }

    _isChangingStatus = true;
    _clearError();
    notifyListeners();

    try {
      _isInstaWalkSearching = false;

      await _stopGlobalLocation();

      _isOnline = false;

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
  // ACTIVE WALK
  // ============================================================

  Future<void> setActiveWalk(
    bool active,
  ) async {
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
  // FORCE ONLINE FOR WALK
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
  // GLOBAL LOCATION
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
  // STOP LOCATION
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
  // REFRESH LOCATION
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

    debugPrint(
      'Walker Availability: Service cleanup completed. '
      'Persisted availability state was preserved.',
    );

    notifyListeners();
  }
}
