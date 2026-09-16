class DailyWalkSlot {
  final String id;
  final String walkerId;
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final bool isActive;

  const DailyWalkSlot({
    required this.id,
    required this.walkerId,
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    this.isActive = true,
  });

  bool get is30Minutes => durationMinutes == 30;

  bool get is1Hour => durationMinutes == 60;

  String get durationLabel {
    if (durationMinutes == 30) {
      return '30 Minutes';
    }

    if (durationMinutes == 60) {
      return '1 Hour';
    }

    return '$durationMinutes Minutes';
  }

  DailyWalkSlot copyWith({
    String? id,
    String? walkerId,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    bool? isActive,
  }) {
    return DailyWalkSlot(
      id: id ?? this.id,
      walkerId: walkerId ?? this.walkerId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes:
          durationMinutes ?? this.durationMinutes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walkerId': walkerId,
      'startTime': startTime,
      'endTime': endTime,
      'durationMinutes': durationMinutes,
      'isActive': isActive,
    };
  }

  factory DailyWalkSlot.fromMap(
    Map<String, dynamic> map,
  ) {
    return DailyWalkSlot(
      id: map['id'] as String? ?? '',
      walkerId: map['walkerId'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      durationMinutes:
          (map['durationMinutes'] as num?)?.toInt() ?? 30,
      isActive:
          map['isActive'] as bool? ?? true,
    );
  }
}
