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

  /// Walker Business ID.
  ///
  /// IMPORTANT:
  /// This is NOT the Firebase Authentication UID.
  final String walkerId;

  /// Walker Firebase Authentication UID.
  final String walkerUid;

  // ============================================================
  // ACTIVE WALK
  // ============================================================

  final String qrWalkId;
  final String walkId;

  // ============================================================
  // CURRENT WALKER LOCATION
  // ============================================================

  final double currentLat;
  final double currentLng;

  // ============================================================
  // TIMESTAMPS
  // ============================================================

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

    // OWNER NOTE
    required this.ownerNote,

    // WALK
    required this.distanceKm,
    required this.estimatedTime,
    required this.status,
    required this.walkType,

    // WALKER
    required this.walkerId,
    required this.walkerUid,

    // ACTIVE WALK
    required this.qrWalkId,
    required this.walkId,

    // CURRENT LOCATION
    required this.currentLat,
    required this.currentLng,

    // TIMESTAMPS
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
    // PICKUP LOCATION
    //
    // Supported:
    //
    // pickupLat
    // pickupLng
    //
    // OR:
    //
    // pickupLocation: {
    //   lat: ...,
    //   lng: ...
    // }
    //
    // OR:
    //
    // pickupLocation: {
    //   latitude: ...,
    //   longitude: ...
    // }
    // ==========================================================

    final Map<String, dynamic>? pickupLocation =
        _map(data['pickupLocation']);

    final double pickupLat = _double(
      data['pickupLat'] ??
          pickupLocation?['lat'] ??
          pickupLocation?['latitude'],
    );

    final double pickupLng = _double(
      data['pickupLng'] ??
          pickupLocation?['lng'] ??
          pickupLocation?['longitude'],
    );

    // ==========================================================
    // DESTINATION LOCATION
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
    //
    // Supported:
    //
    // currentLat
    // currentLng
    //
    // OR:
    //
    // currentLocation: {
    //   lat: ...,
    //   lng: ...
    // }
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
    // RETURN MODEL
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
        data['ownerUid'] ??
            data['ownerAuthUid'],
      ),

      ownerUserId: _string(
        data['ownerUserId'] ??
            data['userId'],
      ),

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
            data['pickupLocationName'],
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

      walkType: _string(
        data['walkType'],
        fallback: 'Insta Walk',
      ),

      // ========================================================
      // WALKER
      // ========================================================

      walkerId: _string(
        data['walkerId'],
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

      // ========================================================
      // CURRENT WALKER LOCATION
      // ========================================================

      currentLat: currentLat,

      currentLng: currentLng,

      // ========================================================
      // TIMESTAMPS
      // ========================================================

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
    return {
      // ========================================================
      // OWNER
      // ========================================================

      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerUid': ownerUid,
      'ownerUserId': ownerUserId,

      // ========================================================
      // DOG
      // ========================================================

      'dogName': dogName,
      'dogBreed': dogBreed,
      'dogAge': dogAge,

      // ========================================================
      // PICKUP
      // ========================================================

      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,

      'pickupLocation': {
        'lat': pickupLat,
        'lng': pickupLng,
      },

      // ========================================================
      // DESTINATION
      // ========================================================

      'destinationAddress': destinationAddress,
      'destinationLat': destinationLat,
      'destinationLng': destinationLng,

      'destinationLocation': {
        'lat': destinationLat,
        'lng': destinationLng,
      },

      // ========================================================
      // OWNER NOTE
      // ========================================================

      'ownerNote': ownerNote,

      // ========================================================
      // WALK
      // ========================================================

      'distanceKm': distanceKm,
      'estimatedTime': estimatedTime,
      'status': status,
      'walkType': walkType,

      // ========================================================
      // WALKER
      // ========================================================

      'walkerId': walkerId,
      'walkerUid': walkerUid,

      // ========================================================
      // ACTIVE WALK
      // ========================================================

      'qrWalkId': qrWalkId,
      'walkId': walkId,

      // ========================================================
      // CURRENT WALKER LOCATION
      // ========================================================

      'currentLat': currentLat,
      'currentLng': currentLng,

      'currentLocation': {
        'lat': currentLat,
        'lng': currentLng,
      },

      // ========================================================
      // TIMESTAMPS
      // ========================================================

      'startedAt': startedAt,
      'updatedAt': updatedAt,
    };
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
  // LOCATION HELPERS
  // ============================================================

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
  // REQUEST HELPERS
  // ============================================================

  bool get isSearching {
    return status.trim().toLowerCase() == 'searching';
  }

  bool get isAccepted {
    return status.trim().toLowerCase() == 'accepted';
  }

  bool get isWalkerOnWay {
    return status.trim().toLowerCase() ==
        'walker_on_way';
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
  // WALKER ID HELPERS
  // ============================================================

  bool get hasWalker {
    return walkerId.trim().isNotEmpty ||
        walkerUid.trim().isNotEmpty;
  }

  bool get hasOwner {
    return ownerId.trim().isNotEmpty ||
        ownerUid.trim().isNotEmpty ||
        ownerUserId.trim().isNotEmpty;
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
    String? walkerUid,
    String? qrWalkId,
    String? walkId,
    double? currentLat,
    double? currentLng,
    Timestamp? startedAt,
    Timestamp? updatedAt,
  }) {
    return WalkRequest(
      id: id ?? this.id,

      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerUserId: ownerUserId ?? this.ownerUserId,

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

      walkerUid:
          walkerUid ?? this.walkerUid,

      qrWalkId:
          qrWalkId ?? this.qrWalkId,

      walkId:
          walkId ?? this.walkId,

      currentLat:
          currentLat ?? this.currentLat,

      currentLng:
          currentLng ?? this.currentLng,

      startedAt:
          startedAt ?? this.startedAt,

      updatedAt:
          updatedAt ?? this.updatedAt,
    );
  }
}
