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

  /// Walker ID — Firebase Auth UID नहीं।
  final String walkerId;

  final String walkType;

  WalkRequest({
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

  factory WalkRequest.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return WalkRequest(
      id: snapshot.id,
      ownerId: _string(data['ownerId']),
      ownerName: _string(data['ownerName']),
      dogName: _string(data['dogName']),
      dogBreed: _string(data['dogBreed']),
      dogAge: _string(data['dogAge']),
      pickupAddress: _string(data['pickupAddress']),
      distanceKm: _double(data['distanceKm']),
      estimatedTime: _string(data['estimatedTime']),
      status: _string(data['status']),
      walkerId: _string(data['walkerId']),
      walkType: _string(
        data['walkType'],
        fallback: 'Insta Walk',
      ),
    );
  }

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
      'walkerId': walkerId,
      'walkType': walkType,
    };
  }

  static String _string(
    dynamic value, {
    String fallback = '',
  }) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    if (result.isEmpty) return fallback;

    return result;
  }

  static double _double(dynamic value) {
    if (value == null) return 0;

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value.toString()) ?? 0;
  }
}
