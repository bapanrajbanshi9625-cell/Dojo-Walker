import 'package:geolocator/geolocator.dart';

class LiveWalkState {
  String? walkId;
  String? sessionId;

  bool running = false;

  Position? lastPosition;

  final List<Map<String, double>> routeCoordinates =
      <Map<String, double>>[];

  double totalDistanceKm = 0.0;

  int steps = 0;
  int peeCount = 0;
  int poopCount = 0;

  DateTime? startedAt;

  int get durationSeconds {
    final DateTime? start = startedAt;

    if (start == null) {
      return 0;
    }

    final int seconds =
        DateTime.now().difference(start).inSeconds;

    return seconds < 0 ? 0 : seconds;
  }

  double get totalDistanceMeters =>
      totalDistanceKm * 1000.0;

  void reset() {
    walkId = null;
    sessionId = null;
    running = false;
    lastPosition = null;
    routeCoordinates.clear();
    totalDistanceKm = 0.0;
    steps = 0;
    peeCount = 0;
    poopCount = 0;
    startedAt = null;
  }
}
