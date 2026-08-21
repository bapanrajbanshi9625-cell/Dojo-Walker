import 'dart:async';

import 'package:geolocator/geolocator.dart';

class WalkerLocationService {
  WalkerLocationService._();

  static final WalkerLocationService instance =
      WalkerLocationService._();

  StreamSubscription<Position>? _positionSubscription;

  final StreamController<Position> _locationController =
      StreamController<Position>.broadcast();

  Stream<Position> get locationStream =>
      _locationController.stream;

  Position? _currentPosition;

  Position? get currentPosition =>
      _currentPosition;

  // ============================================================
  // CHECK LOCATION + PERMISSION
  // ============================================================

  Future<bool> ensurePermission() async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<Position?> getCurrentLocation() async {
    final bool allowed =
        await ensurePermission();

    if (!allowed) {
      return null;
    }

    try {
      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      _currentPosition = position;

      if (!_locationController.isClosed) {
        _locationController.add(position);
      }

      return position;
    } catch (_) {
      return null;
    }
  }

  // ============================================================
  // START CONTINUOUS GPS
  // ============================================================

  Future<bool> startTracking() async {
    final bool allowed =
        await ensurePermission();

    if (!allowed) {
      return false;
    }

    await _positionSubscription?.cancel();

    const LocationSettings settings =
        LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );

    _positionSubscription =
        Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (Position position) {
        _currentPosition = position;

        if (!_locationController.isClosed) {
          _locationController.add(position);
        }
      },
    );

    return true;
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();

    _positionSubscription = null;
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
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stopTracking();
    await _locationController.close();
  }
}
