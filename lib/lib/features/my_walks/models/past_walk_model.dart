import 'package:cloud_firestore/cloud_firestore.dart';

class PastWalkModel {
  final String id;
  final String walkId;

  final String walkerId;
  final String walkerName;

  final String ownerId;
  final String ownerName;

  final String dogName;
  final String dogBreed;
  final String dogPhoto;

  final String status;

  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;

  final String timeFormatted;

  final double distanceKm;
  final double routeDistanceKm;

  final double durationMinutes;
  final double routeDurationMinutes;

  final int peeCount;
  final int poopCount;
  final int rating;

  final String walkerNote;

  const PastWalkModel({
    required this.id,
    required this.walkId,
    required this.walkerId,
    required this.walkerName,
    required this.ownerId,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    required this.dogPhoto,
    required this.status,
    required this.startedAt,
    required this.completedAt,
    required this.createdAt,
    required this.timeFormatted,
    required this.distanceKm,
    required this.routeDistanceKm,
    required this.durationMinutes,
    required this.routeDurationMinutes,
    required this.peeCount,
    required this.poopCount,
    required this.rating,
    required this.walkerNote,
  });

  // ============================================================
  // FIRESTORE → MODEL
  //
  // Collection:
  // walk_history
  //
  // Supports both:
  // walkerUid
  // walkerId
  // ============================================================

  factory PastWalkModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final Map<String, dynamic> data =
        document.data() ?? <String, dynamic>{};

    final String walkId = _readString(
      data['walkId'] ?? document.id,
    );

    final String walkerId = _readString(
      data['walkerUid'] ??
          data['walkerId'] ??
          '',
    );

    return PastWalkModel(
      id: document.id,

      walkId: walkId,

      walkerId: walkerId,

      walkerName: _readString(
        data['walkerName'],
      ),

      ownerId: _readString(
        data['ownerId'],
      ),

      ownerName: _readString(
        data['ownerName'],
      ),

      dogName: _readString(
        data['dogName'],
      ),

      dogBreed: _readString(
        data['dogBreed'],
      ),

      dogPhoto: _readString(
        data['dogPhoto'],
      ),

      status: _readString(
        data['status'],
      ),

      startedAt: _readDate(
        data['startedAt'],
      ),

      completedAt: _readDate(
        data['completedAt'],
      ),

      createdAt: _readDate(
        data['createdAt'],
      ),

      timeFormatted: _readString(
        data['timeFormatted'],
      ),

      distanceKm: _readDouble(
        data['distanceKm'],
      ),

      routeDistanceKm: _readDouble(
        data['routeDistanceKm'],
      ),

      durationMinutes: _readDouble(
        data['durationMinutes'],
      ),

      routeDurationMinutes: _readDouble(
        data['routeDurationMinutes'],
      ),

      peeCount: _readInt(
        data['peeCount'],
      ),

      poopCount: _readInt(
        data['poopCount'],
      ),

      rating: _readInt(
        data['rating'],
      ),

      walkerNote: _readString(
        data['walkerNote'],
      ),
    );
  }

  // ============================================================
  // DISPLAY ID
  // ============================================================

  String get displayId {
    if (walkId.isNotEmpty) {
      return walkId;
    }

    return id;
  }

  // ============================================================
  // ACTIVITY DATE
  //
  // Priority:
  // completedAt
  // startedAt
  // createdAt
  // ============================================================

  DateTime? get activityDate {
    return completedAt ??
        startedAt ??
        createdAt;
  }

  // ============================================================
  // EFFECTIVE DISTANCE
  //
  // Prefer actual walk distance.
  // Fallback to route distance.
  // ============================================================

  double get effectiveDistanceKm {
    if (distanceKm > 0) {
      return distanceKm;
    }

    return routeDistanceKm;
  }

  // ============================================================
  // EFFECTIVE DURATION
  //
  // Prefer actual walk duration.
  // Fallback to route duration.
  // ============================================================

  double get effectiveDurationMinutes {
    if (durationMinutes > 0) {
      return durationMinutes;
    }

    return routeDurationMinutes;
  }

  // ============================================================
  // DISPLAY TIME
  // ============================================================

  String get displayTime {
    if (timeFormatted.isNotEmpty) {
      return timeFormatted;
    }

    final DateTime? date = activityDate;

    if (date == null) {
      return 'Completed';
    }

    return _formatTime(date);
  }

  // ============================================================
  // DISPLAY DETAILS
  // ============================================================

  String get displayDetails {
    final List<String> parts =
        <String>[];

    if (dogName.isNotEmpty) {
      parts.add(dogName);
    }

    if (ownerName.isNotEmpty) {
      parts.add(
        'Owner: $ownerName',
      );
    }

    if (effectiveDurationMinutes > 0) {
      parts.add(
        '${effectiveDurationMinutes.round()} min',
      );
    }

    if (effectiveDistanceKm > 0) {
      parts.add(
        '${effectiveDistanceKm.toStringAsFixed(1)} km',
      );
    }

    if (parts.isEmpty) {
      return 'Completed walk';
    }

    return parts.join(' • ');
  }

  // ============================================================
  // COMPLETED STATUS
  // ============================================================

  bool get isCompleted {
    final String value =
        status.trim().toLowerCase();

    return value == 'completed' ||
        value == 'complete' ||
        value == 'done';
  }

  // ============================================================
  // STRING READER
  // ============================================================

  static String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // DOUBLE READER
  // ============================================================

  static double _readDouble(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
            value.trim(),
          ) ??
          0;
    }

    return 0;
  }

  // ============================================================
  // INT READER
  // ============================================================

  static int _readInt(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.round();
    }

    if (value is String) {
      return int.tryParse(
            value.trim(),
          ) ??
          0;
    }

    return 0;
  }

  // ============================================================
  // DATE READER
  // ============================================================

  static DateTime? _readDate(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(
        value.trim(),
      );
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(
        value,
      );
    }

    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.toInt(),
      );
    }

    return null;
  }

  // ============================================================
  // TIME FORMAT
  // ============================================================

  static String _formatTime(
    DateTime date,
  ) {
    final int hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final String minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    final String period =
        date.hour >= 12
            ? 'PM'
            : 'AM';

    return '$hour:$minute $period';
  }
}
