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

  /// Walker Business ID.
  /// NOT Firebase Auth UID.
  final String walkerId;

  final String walkType;

  // ============================================================
  // ACTIVE WALK
  // ============================================================

  final String qrWalkId;
  final String walkId;
  final String walkerUid;

  /// Current walker GPS location.
  final double currentLat;
  final double currentLng;

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

    // WALKER
    required this.walkerId,
    required this.walkType,

    // ACTIVE WALK
    required this.qrWalkId,
    required this.walkId,
    required this.walkerUid,

    // CURRENT LOCATION
    required this.currentLat,
    required this.currentLng,

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
    // PICKUP COORDINATES
    //
    // Supports:
    //
    // pickupLat / pickupLng
    //
    // AND nested:
    //
    // pickupLocation: {
    //   lat: ...,
    //   lng: ...
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
    // DESTINATION COORDINATES
    //
    // Supports:
    //
    // destinationLat / destinationLng
    //
    // AND nested:
    //
    // destinationLocation: {
    //   lat: ...,
    //   lng: ...
    // }
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
    // Supports:
    //
    // currentLat / currentLng
    //
    // AND activeWalk style:
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
      ),

      ownerPhone: _string(
        data['ownerPhone'],
      ),

      ownerUid: _string(
        data['ownerUid'],
      ),

      ownerUserId: _string(
        data['ownerUserId'],
      ),

      // ========================================================
      // DOG
      // ========================================================

      dogName: _string(
        data['dogName'],
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
        data['pickupAddress'],
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
        data['distanceKm'],
      ),

      estimatedTime: _string(
        data['estimatedTime'],
      ),

      status: _string(
        data['status'],
      ),

      // ========================================================
      // WALKER
      // ========================================================

      walkerId: _string(
        data['walkerId'],
      ),

      walkerUid: _string(
        data['walkerUid'],
      ),

      // ========================================================
      // WALK TYPE
      // ========================================================

      walkType: _string(
        data['walkType'],
        fallback: 'Insta Walk',
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
      // CURRENT LOCATION
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
        data['updatedAt'],
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

      // ========================================================
      // WALKER
      // ========================================================

      'walkerId': walkerId,
      'walkerUid': walkerUid,

      // ========================================================
      // WALK TYPE
      // ========================================================

      'walkType': walkType,

      // ========================================================
      // ACTIVE WALK
      // ========================================================

      'qrWalkId': qrWalkId,
      'walkId': walkId,

      // ========================================================
      // CURRENT LOCATION
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

    return double.tryParse(
          value.toString().trim(),
        ) ??
        0.0;
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

    return null;
  }

  // ============================================================
  // HELPERS
  // ============================================================

  bool get hasPickupLocation {
    return pickupLat != 0.0 &&
        pickupLng != 0.0;
  }

  bool get hasDestinationLocation {
    return destinationLat != 0.0 &&
        destinationLng != 0.0;
  }

  bool get hasCurrentLocation {
    return currentLat != 0.0 &&
        currentLng != 0.0;
  }
}
