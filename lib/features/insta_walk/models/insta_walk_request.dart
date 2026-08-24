import 'package:cloud_firestore/cloud_firestore.dart';

class InstaWalkRequest {
  final String id;

  // ============================================================
  // OWNER
  // ============================================================

  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String ownerUid;

  // ============================================================
  // INSTA WALK
  // ============================================================

  final String senderUid;
  final String senderRole;
  final String requestId;
  final String searchType;
  final double searchRadiusKm;
  final String ownerLocationType;
  final GeoPoint? ownerLocation;

  // ============================================================
  // DOG
  // ============================================================

  final String dogName;
  final String dogBreed;
  final String dogAge;

  // ============================================================
  // PICKUP
  // ============================================================

  final String pickupAddress;
  final double pickupLat;
  final double pickupLng;

  // ============================================================
  // DESTINATION
  // ============================================================

  final String destinationAddress;
  final double destinationLat;
  final double destinationLng;

  // ============================================================
  // NOTE
  // ============================================================

  final String ownerNote;

  // ============================================================
  // WALK
  // ============================================================

  final double distanceKm;
  final String estimatedTime;
  final String status;
  final String walkType;

  // ============================================================
  // WALKER
  // ============================================================

  final String walkerId;
  final String walkerName;
  final String walkerUid;

  // ============================================================
  // LIVE WALK CONNECTION
  // ============================================================

  final String walkId;
  final String liveWalkSessionId;

  // ============================================================
  // CURRENT LOCATION
  // ============================================================

  final double currentLat;
  final double currentLng;

  // ============================================================
  // TIMESTAMPS
  // ============================================================

  final Timestamp? createdAt;
  final Timestamp? acceptedAt;
  final Timestamp? startedAt;
  final Timestamp? updatedAt;

  const InstaWalkRequest({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerUid,
    required this.senderUid,
    required this.senderRole,
    required this.requestId,
    required this.searchType,
    required this.searchRadiusKm,
    required this.ownerLocationType,
    required this.ownerLocation,
    required this.dogName,
    required this.dogBreed,
    required this.dogAge,
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,
    required this.ownerNote,
    required this.distanceKm,
    required this.estimatedTime,
    required this.status,
    required this.walkType,
    required this.walkerId,
    required this.walkerName,
    required this.walkerUid,
    required this.walkId,
    required this.liveWalkSessionId,
    required this.currentLat,
    required this.currentLng,
    required this.createdAt,
    required this.acceptedAt,
    required this.startedAt,
    required this.updatedAt,
  });

  // ============================================================
  // FIRESTORE -> MODEL
  // ============================================================

  factory InstaWalkRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    final GeoPoint? ownerLocation =
        _geoPoint(data['ownerLocation']);

    final Map<String, dynamic>? pickup =
        _map(data['pickupLocation']);

    final Map<String, dynamic>? destination =
        _map(data['destinationLocation']);

    final Map<String, dynamic>? current =
        _map(data['currentLocation']);

    final double pickupLat = _double(
      data['pickupLat'] ??
          pickup?['lat'] ??
          pickup?['latitude'] ??
          ownerLocation?.latitude,
    );

    final double pickupLng = _double(
      data['pickupLng'] ??
          pickup?['lng'] ??
          pickup?['longitude'] ??
          ownerLocation?.longitude,
    );

    final double destinationLat = _double(
      data['destinationLat'] ??
          destination?['lat'] ??
          destination?['latitude'],
    );

    final double destinationLng = _double(
      data['destinationLng'] ??
          destination?['lng'] ??
          destination?['longitude'],
    );

    final double currentLat = _double(
      data['currentLat'] ??
          current?['lat'] ??
          current?['latitude'],
    );

    final double currentLng = _double(
      data['currentLng'] ??
          current?['lng'] ??
          current?['longitude'],
    );

    final String searchType =
        _string(data['searchType']);

    return InstaWalkRequest(
      id: snapshot.id,

      // OWNER
      ownerId: _string(data['ownerId']),
      ownerName: _string(
        data['ownerName'],
        fallback: 'Owner',
      ),
      ownerPhone: _string(
        data['ownerPhone'] ??
            data['phone'] ??
            data['ownerMobile'],
      ),
      ownerUid: _string(
        data['ownerAuthUid'] ??
            data['ownerUid'],
      ),

      // INSTA WALK
      senderUid: _string(
        data['senderUid'],
        fallback: _string(
          data['ownerAuthUid'] ??
              data['ownerUid'],
        ),
      ),
      senderRole: _string(data['senderRole']),
      requestId: _string(
        data['requestId'],
        fallback: snapshot.id,
      ),
      searchType: searchType,
      searchRadiusKm: _double(
        data['searchRadiusKm'],
      ),
      ownerLocationType:
          _string(data['ownerLocationType']),
      ownerLocation: ownerLocation,

      // DOG
      dogName: _string(
        data['dogName'],
        fallback: 'Dog',
      ),
      dogBreed: _string(data['dogBreed']),
      dogAge: _string(data['dogAge']),

      // PICKUP
      pickupAddress: _string(
        data['pickupAddress'] ??
            data['pickup'] ??
            data['pickupLocationName'] ??
            data['address'],
      ),
      pickupLat: pickupLat,
      pickupLng: pickupLng,

      // DESTINATION
      destinationAddress: _string(
        data['destinationAddress'] ??
            data['destination'] ??
            data['dropAddress'] ??
            data['dropoffAddress'],
      ),
      destinationLat: destinationLat,
      destinationLng: destinationLng,

      // NOTE
      ownerNote: _string(
        data['ownerNote'] ??
            data['note'] ??
            data['specialInstructions'],
      ),

      // WALK
      distanceKm: _double(
        data['distanceKm'] ??
            data['walkDistanceKm'] ??
            data['distance'],
      ),
      estimatedTime: _string(
        data['estimatedTime'] ??
            data['estimatedDuration'],
      ),
      status: _string(data['status']),
      walkType: _string(
        data['walkType'],
        fallback: 'Insta Walk',
      ),

      // WALKER
      walkerId: _string(data['walkerId']),
      walkerName: _string(data['walkerName']),
      walkerUid: _string(
        data['walkerUid'] ??
            data['walkerAuthUid'],
      ),

      // LIVE WALK
      walkId: _string(
        data['walkId'] ??
            data['activeWalkId'],
      ),
      liveWalkSessionId:
          _string(data['liveWalkSessionId']),

      // LOCATION
      currentLat: currentLat,
      currentLng: currentLng,

      // TIMESTAMPS
      createdAt: _timestamp(data['createdAt']),
      acceptedAt: _timestamp(data['acceptedAt']),
      startedAt: _timestamp(data['startedAt']),
      updatedAt: _timestamp(
        data['updatedAt'] ??
            data['updatedAtAt'],
      ),
    );
  }

  // ============================================================
  // FIRESTORE MAP
  // ============================================================

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data =
        <String, dynamic>{
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerUid': ownerUid,

      'senderUid': senderUid,
      'senderRole': senderRole,
      'requestId': requestId,
      'searchType': searchType,
      'searchRadiusKm': searchRadiusKm,
      'ownerLocationType': ownerLocationType,

      'dogName': dogName,
      'dogBreed': dogBreed,
      'dogAge': dogAge,

      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'pickupLocation': {
        'lat': pickupLat,
        'lng': pickupLng,
      },

      'destinationAddress': destinationAddress,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,
      'destinationLocation': {
        'lat': destinationLat,
        'lng': destinationLng,
      },

      'ownerNote': ownerNote,

      'distanceKm': distanceKm,
      'estimatedTime': estimatedTime,
      'status': status,
      'walkType': walkType,

      'walkerId': walkerId,
      'walkerName': walkerName,
      'walkerUid': walkerUid,

      'walkId': walkId,
      'liveWalkSessionId': liveWalkSessionId,

      'currentLat': currentLat,
      'currentLng': currentLng,
      'currentLocation': {
        'lat': currentLat,
        'lng': currentLng,
      },

      'createdAt': createdAt,
      'acceptedAt': acceptedAt,
      'startedAt': startedAt,
      'updatedAt': updatedAt,
    };

    if (ownerLocation != null) {
      data['ownerLocation'] = ownerLocation;
    }

    return data;
  }

  // ============================================================
  // INSTA WALK CHECK
  // ============================================================

  bool get isInstaWalk {
    final String search =
        searchType.trim().toLowerCase();

    final String walk =
        walkType.trim().toLowerCase();

    return search == 'insta_walk' ||
        search == 'instawalk' ||
        search == 'insta walk' ||
        walk == 'insta_walk' ||
        walk == 'instawalk' ||
        walk == 'insta walk' ||
        walk == 'Insta Walk'.toLowerCase();
  }

  bool get isSearching =>
      status.trim().toLowerCase() == 'searching';

  bool get isAccepted =>
      status.trim().toLowerCase() == 'accepted';

  bool get isActive =>
      status.trim().toLowerCase() == 'active';

  bool get isCompleted =>
      status.trim().toLowerCase() == 'completed';

  // ============================================================
  // SAFE HELPERS
  // ============================================================

  static Map<String, dynamic>? _map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  static GeoPoint? _geoPoint(dynamic value) {
    if (value is GeoPoint) {
      return value;
    }

    return null;
  }

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  static double _double(dynamic value) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().trim(),
        ) ??
        0.0;
  }

  static Timestamp? _timestamp(dynamic value) {
    if (value is Timestamp) {
      return value;
    }

    if (value is DateTime) {
      return Timestamp.fromDate(value);
    }

    if (value is int) {
      return Timestamp.fromMillisecondsSinceEpoch(
        value,
      );
    }

    return null;
  }
}
