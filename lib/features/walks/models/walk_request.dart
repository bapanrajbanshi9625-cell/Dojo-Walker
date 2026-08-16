import 'package:cloud_firestore/cloud_firestore.dart';

class WalkRequest {
  final String id;
  final String ownerUid;
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
  final String? walkerUid;
  final DateTime? createdAt;

  const WalkRequest({
    required this.id,
    required this.ownerUid,
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
    this.walkerUid,
    this.createdAt,
  });

  factory WalkRequest.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return WalkRequest(
      id: id,
      ownerUid: data['ownerUid']?.toString() ?? '',
      ownerName: data['ownerName']?.toString() ?? 'Owner',
      dogName: data['dogName']?.toString() ?? 'Dog',
      ownerPhone: data['ownerPhone']?.toString() ?? '',
      pickupAddress:
          data['pickupAddress']?.toString() ??
          'Pickup location unavailable',
      distanceKm: _readDouble(data['distanceKm']),
      estimatedTime:
          data['estimatedTime']?.toString() ?? '—',
      pickupLatitude:
          _readDouble(data['pickupLatitude']),
      pickupLongitude:
          _readDouble(data['pickupLongitude']),
      status: data['status']?.toString() ?? 'searching',
      acceptedBy:
          data['acceptedBy']?.toString(),
      walkerUid:
          data['walkerUid']?.toString(),
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
        0;
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
