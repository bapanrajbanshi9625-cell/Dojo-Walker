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
  // This version matches:
  //
  // WalkRequest.fromFirestore(
  //   document.id,
  //   document.data(),
  // )
  // ============================================================

  factory WalkRequest.fromFirestore(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return WalkRequest(
      id: documentId,

      ownerId: _string(data['ownerId']),
      ownerName: _string(data['ownerName']),

      dogName: _string(data['dogName']),
      dogBreed: _string(data['dogBreed']),
      dogAge: _string(data['dogAge']),

      pickupAddress: _string(
        data['pickupAddress'],
      ),

      distanceKm: _double(
        data['distanceKm'],
      ),

      estimatedTime: _string(
        data['estimatedTime'],
      ),

      status: _string(
        data['status'],
      ),

      // IMPORTANT:
      // Walker ID, NOT Firebase UID.
      walkerId: _string(
        data['walkerId'],
      ),

      walkType: _string(
        data['walkType'],
        fallback: 'Insta Walk',
      ),
    );
  }

  // ============================================================
  // DOCUMENT SNAPSHOT VERSION
  //
  // Useful elsewhere in the project.
  // ============================================================

  factory WalkRequest.fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return WalkRequest.fromFirestore(
      snapshot.id,
      snapshot.data() ?? <String, dynamic>{},
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

      // Walker ID, NOT UID.
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
          value.toString(),
        ) ??
        0;
  }
}
