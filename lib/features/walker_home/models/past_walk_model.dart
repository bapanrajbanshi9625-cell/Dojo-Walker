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
  // Collection: walk_history
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

    final String walkerName = _readString(
      data['walkerName'],
    );

    final String ownerId = _readString(
      data['ownerId'],
    );

    final String ownerName = _readString(
      data['ownerName'],
    );

    final String dogName = _readString(
      data['dogName'],
    );

    final String dogBreed = _readString(
      data['dogBreed'],
    );

    final String dogPhoto = _readString(
      data['dogPhoto'],
    );

    final String status = _readString(
      data['status'],
    );

    final DateTime? startedAt =
        _readDate(data['startedAt']);

    final DateTime? completedAt =
        _readDate(data['completedAt']);

    final DateTime? createdAt =
        _readDate(data['createdAt']);

    final String timeFormatted =
        _readString(data['timeFormatted']);

    final double distanceKm =
        _readDouble(data['distanceKm']);

    final double routeDistanceKm =
        _readDouble(data['routeDistanceKm']);

    final double durationMinutes =
        _readDouble(data['durationMinutes']);

    final double routeDurationMinutes =
        _readDouble(data['routeDurationMinutes']);

    final int peeCount =
        _readInt(data['peeCount']);

    final int poopCount =
        _readInt(data['poopCount']);

    final int rating =
        _readInt(data['rating']);

    final String walkerNote =
        _readString(data['walkerNote']);

    return PastWalkModel(
      id: document.id,
      walkId: walkId,
      walkerId: walkerId,
      walkerName: walkerName,
      ownerId: ownerId,
      ownerName: ownerName,
      dogName: dogName,
      dogBreed: dogBreed,
      dogPhoto: dogPhoto,
      status: status,
      startedAt: startedAt,
      completedAt: completedAt,
      createdAt: createdAt,
      timeFormatted: timeFormatted,
      distanceKm: distanceKm,
      routeDistanceKm: routeDistanceKm,
      durationMinutes: durationMinutes,
      routeDurationMinutes: routeDurationMinutes,
      peeCount: peeCount,
      poopCount: poopCount,
      rating: rating,
      walkerNote: walkerNote,
    );
  }

  // ============================================================
  // CARD ID
  // ============================================================

  String get displayId {
    if (walkId.isNotEmpty) {
      return walkId;
    }

    return id;
  }

  // ============================================================
  // DISPLAY TIME
  // ============================================================

  String get displayTime {
    if (timeFormatted.isNotEmpty) {
      return timeFormatted;
    }

    final DateTime? date =
        completedAt ?? startedAt;

    if (date == null) {
      return 'Completed';
    }

    return _formatTime(date);
  }

  // ============================================================
  // DISPLAY DETAILS
  // ============================================================

  String get displayDetails {
    final List<String> parts = <String>[];

    if (dogName.isNotEmpty) {
      parts.add(dogName);
    }

    if (ownerName.isNotEmpty) {
      parts.add('Owner: $ownerName');
    }

    if (durationMinutes > 0) {
      parts.add(
        '${durationMinutes.round()} min',
      );
    }

    if (distanceKm > 0) {
      parts.add(
        '${distanceKm.toStringAsFixed(1)} km',
      );
    }

    if (parts.isEmpty) {
      return 'Completed walk';
    }

    return parts.join(' • ');
  }

  // ============================================================
  // STATUS
  // ============================================================

  bool get isCompleted {
    final String value =
        status.trim().toLowerCase();

    return value == 'completed' ||
        value == 'complete' ||
        value == 'done';
  }

  // ============================================================
  // STRING
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
  // DOUBLE
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
  // INT
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
  // DATE
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
        date.minute.toString().padLeft(
              2,
              '0',
            );

    final String period =
        date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
