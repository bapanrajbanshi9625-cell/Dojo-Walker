// File:
// lib/features/walks/models/walk_request.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class WalkRequest {
  final String id;

  // ============================================================
  // OWNER
  // ============================================================

  final String ownerId;
  final String ownerName;
  final String ownerPhone;
  final String ownerUid;
  final String ownerUserId;

  // ============================================================
  // INSTA WALK / SENDER
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
  // OWNER NOTE
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
  // ACTIVE WALK
  // ============================================================

  final String qrWalkId;
  final String walkId;
  final String liveWalkSessionId;

  // ============================================================
  // CURRENT WALKER LOCATION
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

  // ============================================================
  // CONSTRUCTOR
  // ============================================================

  const WalkRequest({
    required this.id,

    // OWNER
    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerUid,
    required this.ownerUserId,

    // INSTA WALK
    required this.senderUid,
    required this.senderRole,
    required this.requestId,
    required this.searchType,
    required this.searchRadiusKm,
    required this.ownerLocationType,
    required this.ownerLocation,

    // DOG
    required this.dogName,
    required this.dogBreed,
    required this.dogAge,

    // PICKUP
    required this.pickupAddress,
    required this.pickupLat,
    required this.pickupLng,

    // DESTINATION
    required this.destinationAddress,
    required this.destinationLat,
    required this.destinationLng,

    // NOTE
    required this.ownerNote,

    // WALK
    required this.distanceKm,
    required this.estimatedTime,
    required this.status,
    required this.walkType,

    // WALKER
    required this.walkerId,
    required this.walkerName,
    required this.walkerUid,

    // ACTIVE WALK
    required this.qrWalkId,
    required this.walkId,
    required this.liveWalkSessionId,

    // CURRENT LOCATION
    required this.currentLat,
    required this.currentLng,

    // TIMESTAMPS
    required this.createdAt,
    required this.acceptedAt,
    required this.startedAt,
    required this.updatedAt,
  });

  // ============================================================
  // FIRESTORE -> MODEL
  // ============================================================

  factory WalkRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data =
        snapshot.data() ?? <String, dynamic>{};

    // ==========================================================
    // OWNER LOCATION
    //
    // Insta Walk:
    // ownerLocation: GeoPoint
    // ==========================================================

    final GeoPoint? ownerLocation =
        _geoPoint(data['ownerLocation']);

    // ==========================================================
    // PICKUP LOCATION
    //
    // Priority:
    //
    // 1. pickupLat / pickupLng
    // 2. pickupLocation
    // 3. ownerLocation
    // ==========================================================

    final Map<String, dynamic>? pickupLocation =
        _map(data['pickupLocation']);

    final double pickupLat = _double(
      data['pickupLat'] ??
          pickupLocation?['lat'] ??
          pickupLocation?['latitude'] ??
          ownerLocation?.latitude,
    );

    final double pickupLng = _double(
      data['pickupLng'] ??
          pickupLocation?['lng'] ??
          pickupLocation?['longitude'] ??
          ownerLocation?.longitude,
    );

    // ==========================================================
    // DESTINATION
    // ==========================================================

    final Map<String, dynamic>? destinationLocation =
        _map(data['destinationLocation']);

    final double destinationLat = _double(
      data['destinationLat'] ??
          destinationLocation?['lat'] ??
          destinationLocation?['latitude'],
    );

    final double destinationLng = _double(
      data['destinationLng'] ??
          destinationLocation?['lng'] ??
          destinationLocation?['longitude'],
    );

    // ==========================================================
    // CURRENT WALKER LOCATION
    // ==========================================================

    final Map<String, dynamic>? currentLocation =
        _map(data['currentLocation']);

    final double currentLat = _double(
      data['currentLat'] ??
          currentLocation?['lat'] ??
          currentLocation?['latitude'],
    );

    final double currentLng = _double(
      data['currentLng'] ??
          currentLocation?['lng'] ??
          currentLocation?['longitude'],
    );

    // ==========================================================
    // WALK TYPE
    //
    // Insta Walk documents may use searchType.
    // Normal walks may use walkType.
    // ==========================================================

    final String searchType = _string(
      data['searchType'],
    );

    final String walkType = _string(
      data['walkType'],
      fallback: searchType.isNotEmpty
          ? _formatWalkType(searchType)
          : 'Walk',
    );

    // ==========================================================
    // RETURN
    // ==========================================================

    return WalkRequest(
      id: snapshot.id,

      // ========================================================
      // OWNER
      // ========================================================

      ownerId: _string(
        data['ownerId'],
      ),

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

      ownerUserId: _string(
        data['ownerUserId'] ??
            data['userId'] ??
            data['ownerId'],
      ),

      // ========================================================
      // INSTA WALK
      // ========================================================

      senderUid: _string(
        data['senderUid'],
        fallback: _string(
          data['ownerAuthUid'] ??
              data['ownerUid'],
        ),
      ),

      senderRole: _string(
        data['senderRole'],
      ),

      requestId: _string(
        data['requestId'],
        fallback: snapshot.id,
      ),

      searchType: searchType,

      searchRadiusKm: _double(
        data['searchRadiusKm'],
      ),

      ownerLocationType: _string(
        data['ownerLocationType'],
      ),

      ownerLocation: ownerLocation,

      // ========================================================
      // DOG
      // ========================================================

      dogName: _string(
        data['dogName'],
        fallback: 'Dog',
      ),

      dogBreed: _string(
        data['dogBreed'],
      ),

      dogAge: _string(
        data['dogAge'],
      ),

      // ========================================================
      // PICKUP
      // ========================================================

      pickupAddress: _string(
        data['pickupAddress'] ??
            data['pickup'] ??
            data['pickupLocationName'] ??
            data['address'],
      ),

      pickupLat: pickupLat,

      pickupLng: pickupLng,

      // ========================================================
      // DESTINATION
      // ========================================================

      destinationAddress: _string(
        data['destinationAddress'] ??
            data['destination'] ??
            data['dropAddress'] ??
            data['dropoffAddress'],
      ),

      destinationLat: destinationLat,

      destinationLng: destinationLng,

      // ========================================================
      // OWNER NOTE
      // ========================================================

      ownerNote: _string(
        data['ownerNote'] ??
            data['note'] ??
            data['specialInstructions'],
      ),

      // ========================================================
      // WALK
      // ========================================================

      distanceKm: _double(
        data['distanceKm'] ??
            data['walkDistanceKm'] ??
            data['distance'],
      ),

      estimatedTime: _string(
        data['estimatedTime'] ??
            data['estimatedDuration'],
      ),

      status: _string(
        data['status'],
      ),

      walkType: walkType,

      // ========================================================
      // WALKER
      // ========================================================

      walkerId: _string(
        data['walkerId'],
      ),

      walkerName: _string(
        data['walkerName'],
      ),

      walkerUid: _string(
        data['walkerUid'] ??
            data['walkerAuthUid'],
      ),

      // ========================================================
      // ACTIVE WALK
      // ========================================================

      qrWalkId: _string(
        data['qrWalkId'],
      ),

      walkId: _string(
        data['walkId'] ??
            data['activeWalkId'],
      ),

      liveWalkSessionId: _string(
        data['liveWalkSessionId'],
      ),

      // ========================================================
      // CURRENT LOCATION
      // ========================================================

      currentLat: currentLat,

      currentLng: currentLng,

      // ========================================================
      // TIMESTAMPS
      // ========================================================

      createdAt: _timestamp(
        data['createdAt'],
      ),

      acceptedAt: _timestamp(
        data['acceptedAt'],
      ),

      startedAt: _timestamp(
        data['startedAt'],
      ),

      updatedAt: _timestamp(
        data['updatedAt'] ??
            data['updatedAtAt'],
      ),
    );
  }

  // ============================================================
  // MODEL -> FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data =
        <String, dynamic>{
      // OWNER
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerUid': ownerUid,
      'ownerUserId': ownerUserId,

      // INSTA WALK
      'senderUid': senderUid,
      'senderRole': senderRole,
      'requestId': requestId,
      'searchType': searchType,
      'searchRadiusKm': searchRadiusKm,
      'ownerLocationType': ownerLocationType,

      // DOG
      'dogName': dogName,
      'dogBreed': dogBreed,
      'dogAge': dogAge,

      // PICKUP
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,

      'pickupLocation': {
        'lat': pickupLat,
        'lng': pickupLng,
      },

      // DESTINATION
      'destinationAddress': destinationAddress,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,

      'destinationLocation': {
        'lat': destinationLat,
        'lng': destinationLng,
      },

      // NOTE
      'ownerNote': ownerNote,

      // WALK
      'distanceKm': distanceKm,
      'estimatedTime': estimatedTime,
      'status': status,
      'walkType': walkType,

      // WALKER
      'walkerId': walkerId,
      'walkerName': walkerName,
      'walkerUid': walkerUid,

      // ACTIVE WALK
      'qrWalkId': qrWalkId,
      'walkId': walkId,
      'liveWalkSessionId': liveWalkSessionId,

      // CURRENT LOCATION
      'currentLat': currentLat,
      'currentLng': currentLng,

      'currentLocation': {
        'lat': currentLat,
        'lng': currentLng,
      },

      // TIMESTAMPS
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
  // LOCATION
  // ============================================================

  bool get hasOwnerLocation {
    return ownerLocation != null;
  }

  bool get hasPickupLocation {
    return _validCoordinate(
      pickupLat,
      pickupLng,
    );
  }

  bool get hasDestinationLocation {
    return _validCoordinate(
      destinationLat,
      destinationLng,
    );
  }

  bool get hasCurrentLocation {
    return _validCoordinate(
      currentLat,
      currentLng,
    );
  }

  // ============================================================
  // INSTA WALK
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
        walk == 'insta walk';
  }

  // ============================================================
  // REQUEST STATUS
  // ============================================================

  bool get isSearching {
    return status.trim().toLowerCase() ==
        'searching';
  }

  bool get isAccepted {
    return status.trim().toLowerCase() ==
        'accepted';
  }

  bool get isWalkerOnWay {
    return status.trim().toLowerCase() ==
        'walker_on_way';
  }

  bool get isActive {
    return status.trim().toLowerCase() ==
        'active';
  }

  bool get isCompleted {
    return status.trim().toLowerCase() ==
        'completed';
  }

  bool get isCancelled {
    final String value =
        status.trim().toLowerCase();

    return value == 'cancelled' ||
        value == 'owner_cancelled' ||
        value == 'walker_cancelled';
  }

  // ============================================================
  // WALKER
  // ============================================================

  bool get hasWalker {
    return walkerId.trim().isNotEmpty ||
        walkerUid.trim().isNotEmpty;
  }

  // ============================================================
  // OWNER
  // ============================================================

  bool get hasOwner {
    return ownerId.trim().isNotEmpty ||
        ownerUid.trim().isNotEmpty ||
        ownerUserId.trim().isNotEmpty;
  }

  // ============================================================
  // COPY WITH
  // ============================================================

  WalkRequest copyWith({
    String? id,

    String? ownerId,
    String? ownerName,
    String? ownerPhone,
    String? ownerUid,
    String? ownerUserId,

    String? senderUid,
    String? senderRole,
    String? requestId,
    String? searchType,
    double? searchRadiusKm,
    String? ownerLocationType,
    GeoPoint? ownerLocation,

    String? dogName,
    String? dogBreed,
    String? dogAge,

    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,

    String? destinationAddress,
    double? destinationLat,
    double? destinationLng,

    String? ownerNote,

    double? distanceKm,
    String? estimatedTime,
    String? status,
    String? walkType,

    String? walkerId,
    String? walkerName,
    String? walkerUid,

    String? qrWalkId,
    String? walkId,
    String? liveWalkSessionId,

    double? currentLat,
    double? currentLng,

    Timestamp? createdAt,
    Timestamp? acceptedAt,
    Timestamp? startedAt,
    Timestamp? updatedAt,
  }) {
    return WalkRequest(
      id: id ?? this.id,

      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerUserId:
          ownerUserId ?? this.ownerUserId,

      senderUid:
          senderUid ?? this.senderUid,
      senderRole:
          senderRole ?? this.senderRole,
      requestId:
          requestId ?? this.requestId,
      searchType:
          searchType ?? this.searchType,
      searchRadiusKm:
          searchRadiusKm ?? this.searchRadiusKm,
      ownerLocationType:
          ownerLocationType ??
              this.ownerLocationType,
      ownerLocation:
          ownerLocation ?? this.ownerLocation,

      dogName: dogName ?? this.dogName,
      dogBreed: dogBreed ?? this.dogBreed,
      dogAge: dogAge ?? this.dogAge,

      pickupAddress:
          pickupAddress ?? this.pickupAddress,
      pickupLat:
          pickupLat ?? this.pickupLat,
      pickupLng:
          pickupLng ?? this.pickupLng,

      destinationAddress:
          destinationAddress ??
              this.destinationAddress,
      destinationLat:
          destinationLat ??
              this.destinationLat,
      destinationLng:
          destinationLng ??
              this.destinationLng,

      ownerNote:
          ownerNote ?? this.ownerNote,

      distanceKm:
          distanceKm ?? this.distanceKm,

      estimatedTime:
          estimatedTime ??
              this.estimatedTime,

      status:
          status ?? this.status,

      walkType:
          walkType ?? this.walkType,

      walkerId:
          walkerId ?? this.walkerId,

      walkerName:
          walkerName ?? this.walkerName,

      walkerUid:
          walkerUid ?? this.walkerUid,

      qrWalkId:
          qrWalkId ?? this.qrWalkId,

      walkId:
          walkId ?? this.walkId,

      liveWalkSessionId:
          liveWalkSessionId ??
              this.liveWalkSessionId,

      currentLat:
          currentLat ?? this.currentLat,

      currentLng:
          currentLng ?? this.currentLng,

      createdAt:
          createdAt ?? this.createdAt,

      acceptedAt:
          acceptedAt ?? this.acceptedAt,

      startedAt:
          startedAt ?? this.startedAt,

      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }

  // ============================================================
  // SAFE MAP
  // ============================================================

  static Map<String, dynamic>? _map(
    dynamic value,
  ) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  // ============================================================
  // SAFE GEOPOINT
  // ============================================================

  static GeoPoint? _geoPoint(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return value;
    }

    return null;
  }

  // ============================================================
  // SAFE STRING
  // ============================================================

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) {
      return fallback;
    }

    final String result =
        value.toString().trim();

    if (result.isEmpty) {
      return fallback;
    }

    return result;
  }

  // ============================================================
  // SAFE DOUBLE
  // ============================================================

  static double _double(
    dynamic value,
  ) {
    if (value == null) {
      return 0.0;
    }

    if (value is num) {
      return value.toDouble();
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return 0.0;
    }

    return double.tryParse(text) ?? 0.0;
  }

  // ============================================================
  // SAFE TIMESTAMP
  // ============================================================

  static Timestamp? _timestamp(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value;
    }

    if (value is DateTime) {
      return Timestamp.fromDate(value);
    }

    if (value is int) {
      try {
        return Timestamp.fromMillisecondsSinceEpoch(
          value,
        );
      } catch (_) {
        return null;
      }
    }

    return null;
  }

  // ============================================================
  // WALK TYPE FORMATTER
  // ============================================================

  static String _formatWalkType(
    String value,
  ) {
    final String normalized =
        value.trim().toLowerCase();

    if (normalized == 'insta_walk' ||
        normalized == 'instawalk' ||
        normalized == 'insta walk') {
      return 'Insta Walk';
    }

    if (normalized.isEmpty) {
      return 'Walk';
    }

    return value.trim();
  }

  // ============================================================
  // VALID COORDINATE
  // ============================================================

  static bool _validCoordinate(
    double latitude,
    double longitude,
  ) {
    return latitude != 0.0 &&
        longitude != 0.0 &&
        latitude >= -90.0 &&
        latitude <= 90.0 &&
        longitude >= -180.0 &&
        longitude <= 180.0;
  }
}
