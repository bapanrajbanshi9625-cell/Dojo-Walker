// File:
// lib/features/insta_walk/models/insta_walk_request.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// ============================================================
/// INSTA WALK REQUEST MODEL
///
/// Firestore collection:
///     walk_request
///
/// Status flow:
///     searching
///        ↓
///     accepted
///        ↓
///     active
///        ↓
///     completed
///
/// Other possible status:
///     cancelled
///
/// Rejection is stored privately at:
///     walk_request/{walkId}/rejections/{walkerId}
/// ============================================================

class InstaWalkRequest {
  const InstaWalkRequest({
    required this.id,
    this.ownerId = '',
    this.ownerAuthUid = '',
    this.ownerUid = '',
    this.ownerName = '',
    this.ownerPhone = '',
    this.walkerUid = '',
    this.walkerId = '',
    this.dogName = '',
    this.dogBreed = '',
    this.dogPhoto = '',
    this.status = '',
    this.pickupAddress = '',
    this.address = '',
    this.latitude,
    this.longitude,
    this.distanceKm = 0.0,
    this.durationMinutes = 0,
    this.timeFormatted = '',
    this.date = '',
    this.activeWalkId = '',
    this.liveWalkSessionId = '',
    this.createdAt,
    this.acceptedAt,
    this.startedAt,
    this.endedAt,
    this.cancelledAt,
    this.rejectedAt,
    this.updatedAt,
  });

  // ============================================================
  // ID
  // ============================================================

  final String id;

  // ============================================================
  // OWNER
  // ============================================================

  final String ownerId;
  final String ownerAuthUid;
  final String ownerUid;
  final String ownerName;
  final String ownerPhone;

  // ============================================================
  // WALKER
  // ============================================================

  final String walkerUid;
  final String walkerId;

  // ============================================================
  // DOG
  // ============================================================

  final String dogName;
  final String dogBreed;
  final String dogPhoto;

  // ============================================================
  // STATUS
  // ============================================================

  final String status;

  // ============================================================
  // LOCATION
  // ============================================================

  final String pickupAddress;
  final String address;

  final double? latitude;
  final double? longitude;

  final double distanceKm;

  // ============================================================
  // WALK INFO
  // ============================================================

  final int durationMinutes;
  final String timeFormatted;
  final String date;

  // ============================================================
  // LIVE WALK
  // ============================================================

  final String activeWalkId;
  final String liveWalkSessionId;

  // ============================================================
  // TIMESTAMPS
  // ============================================================

  final Timestamp? createdAt;
  final Timestamp? acceptedAt;
  final Timestamp? startedAt;
  final Timestamp? endedAt;
  final Timestamp? cancelledAt;
  final Timestamp? rejectedAt;
  final Timestamp? updatedAt;

  // ============================================================
  // FROM FIRESTORE
  // ============================================================

  factory InstaWalkRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    return InstaWalkRequest(
      id: snapshot.id,

      // --------------------------------------------------------
      // OWNER
      // --------------------------------------------------------

      ownerId: _string(
        data['ownerId'],
      ),

      ownerAuthUid: _firstString(
        data,
        <String>[
          'ownerAuthUid',
          'ownerUid',
        ],
      ),

      ownerUid: _string(
        data['ownerUid'],
      ),

      ownerName: _string(
        data['ownerName'],
      ),

      ownerPhone: _firstString(
        data,
        <String>[
          'ownerPhone',
          'ownerMobile',
          'mobileNumber',
        ],
      ),

      // --------------------------------------------------------
      // WALKER
      // --------------------------------------------------------

      walkerUid: _string(
        data['walkerUid'],
      ),

      walkerId: _string(
        data['walkerId'],
      ),

      // --------------------------------------------------------
      // DOG
      // --------------------------------------------------------

      dogName: _string(
        data['dogName'],
      ),

      dogBreed: _string(
        data['dogBreed'],
      ),

      dogPhoto: _firstString(
        data,
        <String>[
          'dogPhoto',
          'dogPhotoUrl',
          'dogImage',
        ],
      ),

      // --------------------------------------------------------
      // STATUS
      // --------------------------------------------------------

      status: _string(
        data['status'],
      ),

      // --------------------------------------------------------
      // LOCATION
      // --------------------------------------------------------

      pickupAddress: _firstString(
        data,
        <String>[
          'pickupAddress',
          'pickupLocation',
        ],
      ),

      address: _firstString(
        data,
        <String>[
          'address',
          'ownerAddress',
        ],
      ),

      latitude: _double(
        data['latitude'] ??
            data['lat'] ??
            data['pickupLatitude'],
      ),

      longitude: _double(
        data['longitude'] ??
            data['lng'] ??
            data['pickupLongitude'],
      ),

      distanceKm:
          _double(data['distanceKm']) ?? 0.0,

      // --------------------------------------------------------
      // WALK INFO
      // --------------------------------------------------------

      durationMinutes: _int(
        data['durationMinutes'],
      ),

      timeFormatted: _string(
        data['timeFormatted'],
      ),

      date: _string(
        data['date'],
      ),

      // --------------------------------------------------------
      // LIVE WALK
      // --------------------------------------------------------

      activeWalkId: _string(
        data['activeWalkId'],
      ),

      liveWalkSessionId: _string(
        data['liveWalkSessionId'],
      ),

      // --------------------------------------------------------
      // TIMESTAMPS
      // --------------------------------------------------------

      createdAt: _timestamp(
        data['createdAt'],
      ),

      acceptedAt: _timestamp(
        data['acceptedAt'],
      ),

      startedAt: _timestamp(
        data['startedAt'],
      ),

      endedAt: _timestamp(
        data['endedAt'],
      ),

      cancelledAt: _timestamp(
        data['cancelledAt'],
      ),

      rejectedAt: _timestamp(
        data['rejectedAt'],
      ),

      updatedAt: _timestamp(
        data['updatedAt'],
      ),
    );
  }

  // ============================================================
  // TO FIRESTORE
  // ============================================================

  Map<String, dynamic> toFirestore() {
    return <String, dynamic>{
      'ownerId': ownerId,
      'ownerAuthUid': ownerAuthUid,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,

      'walkerUid': walkerUid,
      'walkerId': walkerId,

      'dogName': dogName,
      'dogBreed': dogBreed,
      'dogPhoto': dogPhoto,

      'status': status,

      'pickupAddress': pickupAddress,
      'address': address,

      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,

      'durationMinutes': durationMinutes,
      'timeFormatted': timeFormatted,
      'date': date,

      'activeWalkId': activeWalkId,
      'liveWalkSessionId': liveWalkSessionId,

      'createdAt': createdAt,
      'acceptedAt': acceptedAt,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'cancelledAt': cancelledAt,
      'rejectedAt': rejectedAt,
      'updatedAt': updatedAt,
    };
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  InstaWalkRequest copyWith({
    String? id,
    String? ownerId,
    String? ownerAuthUid,
    String? ownerUid,
    String? ownerName,
    String? ownerPhone,
    String? walkerUid,
    String? walkerId,
    String? dogName,
    String? dogBreed,
    String? dogPhoto,
    String? status,
    String? pickupAddress,
    String? address,
    double? latitude,
    double? longitude,
    double? distanceKm,
    int? durationMinutes,
    String? timeFormatted,
    String? date,
    String? activeWalkId,
    String? liveWalkSessionId,
    Timestamp? createdAt,
    Timestamp? acceptedAt,
    Timestamp? startedAt,
    Timestamp? endedAt,
    Timestamp? cancelledAt,
    Timestamp? rejectedAt,
    Timestamp? updatedAt,
  }) {
    return InstaWalkRequest(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      ownerAuthUid:
          ownerAuthUid ?? this.ownerAuthUid,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      walkerUid: walkerUid ?? this.walkerUid,
      walkerId: walkerId ?? this.walkerId,
      dogName: dogName ?? this.dogName,
      dogBreed: dogBreed ?? this.dogBreed,
      dogPhoto: dogPhoto ?? this.dogPhoto,
      status: status ?? this.status,
      pickupAddress:
          pickupAddress ?? this.pickupAddress,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm:
          distanceKm ?? this.distanceKm,
      durationMinutes:
          durationMinutes ?? this.durationMinutes,
      timeFormatted:
          timeFormatted ?? this.timeFormatted,
      date: date ?? this.date,
      activeWalkId:
          activeWalkId ?? this.activeWalkId,
      liveWalkSessionId:
          liveWalkSessionId ??
              this.liveWalkSessionId,
      createdAt:
          createdAt ?? this.createdAt,
      acceptedAt:
          acceptedAt ?? this.acceptedAt,
      startedAt:
          startedAt ?? this.startedAt,
      endedAt:
          endedAt ?? this.endedAt,
      cancelledAt:
          cancelledAt ?? this.cancelledAt,
      rejectedAt:
          rejectedAt ?? this.rejectedAt,
      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // STRING HELPER
  // ============================================================

  static String _string(
    dynamic value,
  ) {
    return value?.toString().trim() ?? '';
  }

  // ============================================================
  // FIRST NON-EMPTY STRING
  // ============================================================

  static String _firstString(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    for (final String key in keys) {
      final String value =
          _string(data[key]);

      if (value.isNotEmpty) {
        return value;
      }
    }

    return '';
  }

  // ============================================================
  // DOUBLE HELPER
  // ============================================================

  static double? _double(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // INT HELPER
  // ============================================================

  static int _int(
    dynamic value,
  ) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString().trim(),
        ) ??
        0;
  }

  // ============================================================
  // TIMESTAMP HELPER
  // ============================================================

  static Timestamp? _timestamp(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value;
    }

    if (value is DateTime) {
      return Timestamp.fromDate(value);
    }

    return null;
  }

  // ============================================================
  // STATUS HELPERS
  // ============================================================

  bool get isSearching =>
      status.toLowerCase() == 'searching';

  bool get isAccepted =>
      status.toLowerCase() == 'accepted';

  bool get isActive =>
      status.toLowerCase() == 'active';

  bool get isCompleted =>
      status.toLowerCase() == 'completed';

  bool get isCancelled =>
      status.toLowerCase() == 'cancelled';

  bool get isRejected =>
      status.toLowerCase() == 'rejected';
}
