import 'package:geolocator/geolocator.dart';

class LiveWalkState {
  // ============================================================
  // CANONICAL WALK ID
  //
  // One ID for:
  // walk_request/{requestId}
  // liveWalkSessions/{requestId}
  // walk_history/{requestId}
  //
  // Example:
  // DW000001
  // ============================================================

  String? requestId;

  // ============================================================
  // COMPATIBILITY GETTERS
  //
  // These do NOT create separate IDs.
  // They always return the same requestId.
  // ============================================================

  String? get walkId => requestId;

  set walkId(String? value) {
    requestId = value;
  }

  String? get sessionId => requestId;

  set sessionId(String? value) {
    requestId = value;
  }

  // ============================================================
  // RUNNING
  // ============================================================

  bool running = false;

  // ============================================================
  // GPS
  // ============================================================

  Position? lastPosition;

  final List<Map<String, double>> routeCoordinates =
      <Map<String, double>>[];

  // ============================================================
  // DISTANCE
  // ============================================================

  double totalDistanceKm = 0.0;

  // ============================================================
  // ACTIVITY
  // ============================================================

  int steps = 0;
  int peeCount = 0;
  int poopCount = 0;

  // ============================================================
  // START
  // ============================================================

  DateTime? startedAt;

  // ============================================================
  // DURATION
  // ============================================================

  int get durationSeconds {
    final DateTime? start = startedAt;

    if (start == null) {
      return 0;
    }

    final int seconds =
        DateTime.now().difference(start).inSeconds;

    return seconds < 0 ? 0 : seconds;
  }

  // ============================================================
  // DISTANCE METERS
  // ============================================================

  double get totalDistanceMeters =>
      totalDistanceKm * 1000.0;

  // ============================================================
  // VALID REQUEST ID
  // ============================================================

  bool get hasValidRequestId {
    final String? id = requestId;

    if (id == null) {
      return false;
    }

    return RegExp(r'^DW\d{6}$').hasMatch(id.trim());
  }

  // ============================================================
  // RESET
  // ============================================================

  void reset() {
    requestId = null;

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
