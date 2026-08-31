import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LiveWalkGpsService {
  LiveWalkGpsService({
    required void Function(Position position) onPosition,
  }) : _onPosition = onPosition;

  final void Function(Position position) _onPosition;

  StreamSubscription<Position>? _subscription;

  bool _running = false;

  bool get isRunning => _running;

  Future<bool> ensurePermission() async {
    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<bool> start() async {
    final bool permission =
        await ensurePermission();

    if (!permission) {
      return false;
    }

    await _subscription?.cancel();

    _running = true;

    _subscription =
        Geolocator.getPositionStream().listen(
      (Position position) {
        if (!_running) {
          return;
        }

        if (!_validPosition(position)) {
          return;
        }

        _onPosition(position);
      },
      onError: (_) {},
      cancelOnError: false,
    );

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final Position position =
          await Geolocator.getCurrentPosition();

      if (!_validPosition(position)) {
        return null;
      }

      return position;
    } catch (_) {
      return null;
    }
  }

  bool _validPosition(Position position) {
    if (position.accuracy > 100) {
      return false;
    }

    final double lat = position.latitude;
    final double lng = position.longitude;

    return lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180 &&
        !(lat == 0 && lng == 0);
  }

  Future<void> stop() async {
    _running = false;

    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> dispose() async {
    await stop();
  }
}
