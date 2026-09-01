import 'package:cloud_firestore/cloud_firestore.dart';

class PastWalkModel {
  final String id;
  final String time;
  final String details;
  final String dogName;
  final String ownerName;
  final String walkId;
  final String walkerId;
  final String status;
  final DateTime? completedAt;

  const PastWalkModel({
    required this.id,
    required this.time,
    required this.details,
    required this.dogName,
    required this.ownerName,
    required this.walkId,
    required this.walkerId,
    required this.status,
    required this.completedAt,
  });

  factory PastWalkModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? <String, dynamic>{};

    final completedAt = _readDate(
      data['completedAt'] ??
          data['completed_at'] ??
          data['completedTime'] ??
          data['endedAt'],
    );

    final dogName = _readString(
      data['dogName'] ?? data['dog'] ?? 'Dog',
    );

    final ownerName = _readString(
      data['ownerName'] ?? data['owner'] ?? 'Owner',
    );

    final walkId = _readString(
      data['walkId'] ?? data['id'] ?? document.id,
    );

    final walkerId = _readString(
      data['walkerId'] ?? data['walkerID'] ?? '',
    );

    final status = _readString(
      data['status'] ?? 'completed',
    );

    return PastWalkModel(
      id: walkId,
      time: _formatDate(completedAt),
      details: _buildDetails(
        dogName: dogName,
        ownerName: ownerName,
        data: data,
      ),
      dogName: dogName,
      ownerName: ownerName,
      walkId: walkId,
      walkerId: walkerId,
      status: status,
      completedAt: completedAt,
    );
  }

  static String _buildDetails({
    required String dogName,
    required String ownerName,
    required Map<String, dynamic> data,
  }) {
    final duration = _readString(
      data['duration'] ??
          data['durationMinutes'] ??
          data['walkDuration'],
    );

    final distance = _readString(
      data['distance'] ??
          data['distanceKm'] ??
          data['totalDistance'],
    );

    final parts = <String>[
      if (dogName.isNotEmpty) dogName,
      if (ownerName.isNotEmpty) 'Owner: $ownerName',
      if (duration.isNotEmpty) duration,
      if (distance.isNotEmpty) distance,
    ];

    if (parts.isEmpty) {
      return 'Completed walk';
    }

    return parts.join(' • ');
  }

  static String _readString(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  static DateTime? _readDate(dynamic value) {
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
      return DateTime.tryParse(value);
    }

    return null;
  }

  static String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Completed';
    }

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
            ? date.hour - 12
            : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }
}
