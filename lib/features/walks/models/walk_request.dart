import 'package:cloud_firestore/cloud_firestore.dart';

class WalkRequest {
  final String id;

  final String ownerId;
  final String ownerName;

  final String dogName;
  final String dogBreed;
  final String dogAge;

  final String pickupAddress;

  final double distanceKm;
  final String estimatedTime;

  final String status;

  /// IMPORTANT:
  /// This is WALKER ID, not Firebase UID.
  final String walkerId;

  final String walkType;

  const WalkRequest({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    required this.dogAge,
    required this.pickupAddress,
    required this.distanceKm,
    required this.estimatedTime,
    required this.status,
    required this.walkerId,
    required this.walkType,
  });

  // ============================================================
  // FIRESTORE -> MODEL
  //
  // IMPORTANT:
  //
  // Now all existing code can simply use:
  //
  // WalkRequest.fromFirestore(doc)
  //
  // No need to pass:
  // doc.id
  // doc.data()
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
      // WALKER ID
      //
      // IMPORTANT:
      // This is Walker Business ID.
      // NOT Firebase Auth UID.
      // ========================================================

      walkerId: _string(
        data['walkerId'],
      ),

      // ========================================================
      // WALK TYPE
      // ========================================================

      walkType: _string(
        data['walkType'],
        fallback: 'Insta Walk',
      ),
    );
  }

  // ============================================================
  // MODEL -> FIRESTORE
  // ============================================================

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,

      'dogName': dogName,
      'dogBreed': dogBreed,
      'dogAge': dogAge,

      'pickupAddress': pickupAddress,

      'distanceKm': distanceKm,
      'estimatedTime': estimatedTime,

      'status': status,

      // Walker Business ID
      // NOT Firebase UID.
      'walkerId': walkerId,

      'walkType': walkType,
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
}
