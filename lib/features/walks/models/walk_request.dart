import 'package:cloud_firestore/cloud_firestore.dart';

class WalkRequest {
  final String id;
  final String ownerId;
  final String ownerName;
  final String dogName;
  final String ownerPhone;
  final String pickupAddress;
  final double distanceKm;
  final String estimatedTime;
  final double pickupLatitude;
  final double pickupLongitude;
  final String status;
  final String? acceptedBy;
  final String? walkerId;
  final DateTime? createdAt;

  const WalkRequest({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.dogName,
    required this.ownerPhone,
    required this.pickupAddress,
    required this.distanceKm,
    required this.estimatedTime,
    required this.pickupLatitude,
    required this.pickupLongitude,
    required this.status,
    this.acceptedBy,
    this.walkerId,
    this.createdAt,
  });

  factory WalkRequest.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return WalkRequest(
      id: id,

      // Custom Owner ID — Firebase Auth UID नहीं।
      ownerId:
          data['ownerid']?.toString() ?? '',

      ownerName:
          data['ownername']?.toString() ?? 'Owner',

      dogName:
          data['dogname']?.toString() ?? 'Dog',

      ownerPhone:
          data['ownermobilenumber']?.toString() ?? '',

      pickupAddress:
          data['address']?.toString() ??
          'Pickup location unavailable',

      distanceKm:
          _readDouble(data['distanceKm']),

      estimatedTime:
          data['estimatedtime']?.toString() ?? '—',

      pickupLatitude:
          _readDouble(data['pickuplatitude']),

      pickupLongitude:
          _readDouble(data['pickuplongitude']),

      status:
          data['status']?.toString() ?? 'searching',

      acceptedBy:
          data['acceptedBy']?.toString(),

      // Custom Walker ID — Firebase Auth UID नहीं।
      walkerId:
          data['walkerid']?.toString(),

      createdAt:
          _readDate(data['createdAt']),
    );
  }

  static double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }
}
