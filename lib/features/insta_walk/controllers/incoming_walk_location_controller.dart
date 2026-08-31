import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';

class IncomingWalkLocationController {
  IncomingWalkLocationController({
    required this.ownerLatitude,
    required this.ownerLongitude,
    this.onLocationChanged,
    this.onError,
  });

  final double? ownerLatitude;
  final double? ownerLongitude;

  final void Function(
    Position position,
    double distanceMeters,
    String distanceText,
    String etaText,
    bool canReachOwner,
  )? onLocationChanged;

  final void Function(String message)? onError;

  StreamSubscription<Position>? _locationSubscription;

  Position? _walkerPosition;

  double _distanceMeters = 0;

  bool _started = false;

  // ============================================================
  // GETTERS
  // ============================================================

  Position? get walkerPosition => _walkerPosition;

  double get distanceMeters => _distanceMeters;

  bool get canReachOwner {
    return ownerLatitude != null &&
        ownerLongitude != null &&
        _walkerPosition != null &&
        _distanceMeters <= 100;
  }

  String get distanceText {
    if (_walkerPosition == null ||
        ownerLatitude == null ||
        ownerLongitude == null) {
      return '—';
    }

    if (_distanceMeters < 1000) {
      return '${_distanceMeters.round()} m';
    }

    return '${(_distanceMeters / 1000).toStringAsFixed(1)} km';
  }

  String get etaText {
    if (_distanceMeters <= 0) {
      return '—';
    }

    const double walkingSpeedKmH = 5;

    final double minutes =
        (_distanceMeters / 1000) /
            walkingSpeedKmH *
            60;

    final int rounded = math.max(
      1,
      minutes.ceil(),
    );

    return '$rounded min';
  }

  // ============================================================
  // START GPS
  // ============================================================

  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;

    try {
      final bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        onError?.call(
          'Please turn on Location/GPS.',
        );
        _started = false;
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
              LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        onError?.call(
          'Location permission is required.',
        );
        _started = false;
        return;
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        desiredAccuracy:
            LocationAccuracy.high,
      );

      _updateLocation(position);

      _locationSubscription =
          Geolocator.getPositionStream(
        locationSettings:
            const LocationSettings(
          accuracy:
              LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        _updateLocation,
        onError: (Object error) {
          onError?.call(
            'Unable to track your location.',
          );
        },
      );
    } catch (error) {
      _started = false;

      onError?.call(
        'Unable to get your location.',
      );
    }
  }

  // ============================================================
  // UPDATE LOCATION
  // ============================================================

  void _updateLocation(
    Position position,
  ) {
    _walkerPosition = position;

    final double? latitude =
        ownerLatitude;

    final double? longitude =
        ownerLongitude;

    double distance = 0;

    if (latitude != null &&
        longitude != null) {
      distance =
          Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        latitude,
        longitude,
      );
    }

    _distanceMeters = distance;

    onLocationChanged?.call(
      position,
      _distanceMeters,
      distanceText,
      etaText,
      canReachOwner,
    );
  }

  // ============================================================
  // STOP GPS
  // ============================================================

  Future<void> stop() async {
    _started = false;

    await _locationSubscription?.cancel();

    _locationSubscription = null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stop();
  }
}
