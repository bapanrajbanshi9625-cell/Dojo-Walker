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
/// Rejection:
///     walk_request/{walkId}/rejections/{walkerId}
/// ============================================================

class InstaWalkRequest {
  const InstaWalkRequest({
    required this.id,

    // OWNER
    this.ownerId = '',
    this.ownerAuthUid = '',
    this.ownerUid = '',
    this.ownerName = '',
    this.ownerPhone = '',

    // WALKER
    this.walkerUid = '',
    this.walkerId = '',

    // DOG
    this.dogName = '',
    this.dogBreed = '',
    this.dogPhoto = '',

    // STATUS
    this.status = '',

    // ADDRESS
    this.pickupAddress = '',
    this.address = '',

    // OWNER LOCATION
    this.latitude,
    this.longitude,

    // WALKER LIVE LOCATION
    this.walkerLocation,

    // WALK INFO
    this.distanceKm = 0.0,
    this.durationMinutes = 0,
    this.timeFormatted = '',
    this.date = '',

    // LIVE WALK
    this.activeWalkId = '',
    this.liveWalkSessionId = '',

    // TIMESTAMPS
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
  // ADDRESS
  // ============================================================

  final String pickupAddress;
  final String address;

  // ============================================================
  // OWNER LOCATION
  //
  // Firestore:
  //     ownerLocation: GeoPoint
  //
  // Exposed through latitude / longitude so existing
  // Owner/Home map code can continue to work.
  // ============================================================

  final double? latitude;
  final double? longitude;

  // ============================================================
  // WALKER LIVE LOCATION
  //
  // Firestore:
  //     walkerLocation: GeoPoint
  //
  // This is the Walker's CURRENT location while travelling
  // toward the Owner.
  //
  // IMPORTANT:
  // This is separate from latitude / longitude above.
  //
  // latitude / longitude
  //     = Owner/Home location
  //
  // walkerLocation
  //     = Walker current live location
  // ============================================================

  final GeoPoint? walkerLocation;

  // ============================================================
  // WALK INFO
  // ============================================================

  final double distanceKm;
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

    // ----------------------------------------------------------
    // OWNER LOCATION
    //
    // Primary:
    //     ownerLocation: GeoPoint
    //
    // Fallback:
    //     latitude
    //     lat
    //     pickupLatitude
    //
    //     longitude
    //     lng
    //     pickupLongitude
    // ----------------------------------------------------------

    final GeoPoint? ownerLocation =
        _geoPoint(
      data['ownerLocation'],
    );

    final double? latitude =
        ownerLocation?.latitude ??
            _double(
              data['latitude'] ??
                  data['lat'] ??
                  data['pickupLatitude'],
            );

    final double? longitude =
        ownerLocation?.longitude ??
            _double(
              data['longitude'] ??
                  data['lng'] ??
                  data['pickupLongitude'],
            );

    // ----------------------------------------------------------
    // WALKER LIVE LOCATION
    //
    // Firestore:
    //     walkerLocation: GeoPoint
    //
    // This must NOT replace ownerLocation.
    // ----------------------------------------------------------

    final GeoPoint? walkerLocation =
        _geoPoint(
      data['walkerLocation'],
    );

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
          'authUid',
        ],
      ),

      ownerUid: _firstString(
        data,
        <String>[
          'ownerUid',
          'ownerAuthUid',
          'authUid',
          'uid',
        ],
      ),

      ownerName: _firstString(
        data,
        <String>[
          'ownerName',
          'fullName',
        ],
      ),

      ownerPhone: _firstString(
        data,
        <String>[
          'ownerPhone',
          'ownerMobile',
          'mobileNumber',
          'mainPhone',
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
      // ADDRESS
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

      // --------------------------------------------------------
      // OWNER LOCATION
      // --------------------------------------------------------

      latitude: latitude,

      longitude: longitude,

      // --------------------------------------------------------
      // WALKER LIVE LOCATION
      // --------------------------------------------------------

      walkerLocation: walkerLocation,

      // --------------------------------------------------------
      // WALK INFO
      // --------------------------------------------------------

      distanceKm:
          _double(
            data['distanceKm'],
          ) ??
          0.0,

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
      // OWNER
      'ownerId': ownerId,
      'ownerAuthUid': ownerAuthUid,
      'ownerUid': ownerUid,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,

      // WALKER
      'walkerUid': walkerUid,
      'walkerId': walkerId,

      // DOG
      'dogName': dogName,
      'dogBreed': dogBreed,
      'dogPhoto': dogPhoto,

      // STATUS
      'status': status,

      // ADDRESS
      'pickupAddress': pickupAddress,
      'address': address,

      // OWNER LOCATION
      'latitude': latitude,
      'longitude': longitude,

      // WALKER LIVE LOCATION
      'walkerLocation': walkerLocation,

      // WALK INFO
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'timeFormatted': timeFormatted,
      'date': date,

      // LIVE WALK
      'activeWalkId': activeWalkId,
      'liveWalkSessionId': liveWalkSessionId,

      // TIMESTAMPS
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

    // OWNER
    String? ownerId,
    String? ownerAuthUid,
    String? ownerUid,
    String? ownerName,
    String? ownerPhone,

    // WALKER
    String? walkerUid,
    String? walkerId,

    // DOG
    String? dogName,
    String? dogBreed,
    String? dogPhoto,

    // STATUS
    String? status,

    // ADDRESS
    String? pickupAddress,
    String? address,

    // OWNER LOCATION
    double? latitude,
    double? longitude,

    // WALKER LIVE LOCATION
    GeoPoint? walkerLocation,

    // WALK INFO
    double? distanceKm,
    int? durationMinutes,
    String? timeFormatted,
    String? date,

    // LIVE WALK
    String? activeWalkId,
    String? liveWalkSessionId,

    // TIMESTAMPS
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

      // OWNER
      ownerId: ownerId ?? this.ownerId,
      ownerAuthUid:
          ownerAuthUid ?? this.ownerAuthUid,
      ownerUid:
          ownerUid ?? this.ownerUid,
      ownerName:
          ownerName ?? this.ownerName,
      ownerPhone:
          ownerPhone ?? this.ownerPhone,

      // WALKER
      walkerUid:
          walkerUid ?? this.walkerUid,
      walkerId:
          walkerId ?? this.walkerId,

      // DOG
      dogName:
          dogName ?? this.dogName,
      dogBreed:
          dogBreed ?? this.dogBreed,
      dogPhoto:
          dogPhoto ?? this.dogPhoto,

      // STATUS
      status:
          status ?? this.status,

      // ADDRESS
      pickupAddress:
          pickupAddress ?? this.pickupAddress,
      address:
          address ?? this.address,

      // OWNER LOCATION
      latitude:
          latitude ?? this.latitude,
      longitude:
          longitude ?? this.longitude,

      // WALKER LIVE LOCATION
      walkerLocation:
          walkerLocation ?? this.walkerLocation,

      // WALK INFO
      distanceKm:
          distanceKm ?? this.distanceKm,
      durationMinutes:
          durationMinutes ?? this.durationMinutes,
      timeFormatted:
          timeFormatted ?? this.timeFormatted,
      date:
          date ?? this.date,

      // LIVE WALK
      activeWalkId:
          activeWalkId ?? this.activeWalkId,
      liveWalkSessionId:
          liveWalkSessionId ??
              this.liveWalkSessionId,

      // TIMESTAMPS
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
  // GEOPOINT HELPER
  // ============================================================

  static GeoPoint? _geoPoint(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is GeoPoint) {
      return value;
    }

    return null;
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

  // ============================================================
  // WALKER LOCATION HELPER
  // ============================================================

  bool get hasWalkerLocation =>
      walkerLocation != null;

  double? get walkerLatitude =>
      walkerLocation?.latitude;

  double? get walkerLongitude =>
      walkerLocation?.longitude;
}
