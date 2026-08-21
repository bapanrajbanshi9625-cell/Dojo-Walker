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

  final Timestamp? startedAt;
  final Timestamp? updatedAt;

  const WalkRequest({
    required this.id,

    required this.ownerId,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerUid,
    required this.ownerUserId,

    required this.dogName,
    required this.dogBreed,
    required this.dogAge,

    required this.pickupAddress,

    required this.distanceKm,
    required this.estimatedTime,
    required this.status,

    required this.walkerId,
    required this.walkType,

    required this.qrWalkId,
    required this.walkId,
    required this.walkerUid,

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

      // ========================================================
      // DISTANCE
      // ========================================================

      distanceKm: _double(
        data['distanceKm'],
      ),

      // ========================================================
      // ESTIMATED TIME
      // ========================================================

      estimatedTime: _string(
        data['estimatedTime'],
      ),

      // ========================================================
      // STATUS
      // ========================================================

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
        data['walkId'],
      ),

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
      // OWNER
      'ownerId': ownerId,
      'ownerName': ownerName,
      'ownerPhone': ownerPhone,
      'ownerUid': ownerUid,
      'ownerUserId': ownerUserId,

      // DOG
      'dogName': dogName,
      'dogBreed': dogBreed,
      'dogAge': dogAge,

      // PICKUP
      'pickupAddress': pickupAddress,

      // WALK
      'distanceKm': distanceKm,
      'estimatedTime': estimatedTime,
      'status': status,

      // WALKER
      'walkerId': walkerId,
      'walkerUid': walkerUid,

      // WALK TYPE
      'walkType': walkType,

      // ACTIVE WALK
      'qrWalkId': qrWalkId,
      'walkId': walkId,
      'startedAt': startedAt,
      'updatedAt': updatedAt,
    };
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
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().trim(),
        ) ??
        0;
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
}
