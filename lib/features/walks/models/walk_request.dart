class WalkRequest {
  final String id;
  final String ownerUid;
  final String address;
  final String status;
  final double distanceKm;

  const WalkRequest({
    required this.id,
    required this.ownerUid,
    required this.address,
    required this.status,
    required this.distanceKm,
  });

  String get title => 'Insta Walk Request';

  factory WalkRequest.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    final dynamic distance = data['distanceKm'];

    final double distanceKm = distance is num
        ? distance.toDouble()
        : double.tryParse(
              distance?.toString() ?? '',
            ) ??
            0;

    return WalkRequest(
      id: id,
      ownerUid: data['ownerUid']?.toString() ?? '',
      address: data['address']?.toString() ?? '',
      status: data['status']?.toString() ?? 'searching',
      distanceKm: distanceKm,
    );
  }
}
