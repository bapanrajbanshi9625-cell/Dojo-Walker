import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_walk_slot.dart';

class DailyWalkAvailabilityService {
  DailyWalkAvailabilityService._();

  static final DailyWalkAvailabilityService instance =
      DailyWalkAvailabilityService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _collection = 'daily_walk_availability';

  String? get _walkerId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _slotsCollection =>
      _firestore.collection(_collection);

  Stream<List<DailyWalkSlot>> watchMySlots() {
    final walkerId = _walkerId;

    if (walkerId == null) {
      return Stream.value(const <DailyWalkSlot>[]);
    }

    return _slotsCollection
        .where('walkerId', isEqualTo: walkerId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final slots = snapshot.docs
          .map(
            (doc) => DailyWalkSlot.fromMap({
              ...doc.data(),
              'id': doc.id,
            }),
          )
          .toList();

      slots.sort(_sortSlots);

      return slots;
    });
  }

  Future<List<DailyWalkSlot>> getMySlots() async {
    final walkerId = _walkerId;

    if (walkerId == null) {
      return const <DailyWalkSlot>[];
    }

    final snapshot = await _slotsCollection
        .where('walkerId', isEqualTo: walkerId)
        .where('isActive', isEqualTo: true)
        .get();

    final slots = snapshot.docs
        .map(
          (doc) => DailyWalkSlot.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    slots.sort(_sortSlots);

    return slots;
  }

  Future<String> addSlot({
    required String day,
    required String startTime,
    required String endTime,
    required int durationMinutes,
  }) async {
    final walkerId = _walkerId;

    if (walkerId == null) {
      throw StateError('Walker is not authenticated.');
    }

    if (durationMinutes != 30 && durationMinutes != 60) {
      throw ArgumentError(
        'Duration must be either 30 or 60 minutes.',
      );
    }

    final duplicate = await _slotsCollection
        .where('walkerId', isEqualTo: walkerId)
        .where('day', isEqualTo: day)
        .where('startTime', isEqualTo: startTime)
        .where('durationMinutes', isEqualTo: durationMinutes)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw StateError('This slot has already been added.');
    }

    final document = _slotsCollection.doc();

    final slot = DailyWalkSlot(
      id: document.id,
      walkerId: walkerId,
      day: day,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      isActive: true,
    );

    await document.set(slot.toMap());

    return document.id;
  }

  Future<void> updateSlot(DailyWalkSlot slot) async {
    final walkerId = _walkerId;

    if (walkerId == null) {
      throw StateError('Walker is not authenticated.');
    }

    if (slot.walkerId != walkerId) {
      throw StateError('You cannot update another walker\'s slot.');
    }

    await _slotsCollection.doc(slot.id).set(
          slot.toMap(),
          SetOptions(merge: true),
        );
  }

  Future<void> deleteSlot(String slotId) async {
    final walkerId = _walkerId;

    if (walkerId == null) {
      throw StateError('Walker is not authenticated.');
    }

    final document = await _slotsCollection.doc(slotId).get();

    if (!document.exists) {
      return;
    }

    final data = document.data();

    if (data == null || data['walkerId'] != walkerId) {
      throw StateError('You cannot delete another walker\'s slot.');
    }

    await _slotsCollection.doc(slotId).update({
      'isActive': false,
    });
  }

  Future<void> saveSlots(List<DailyWalkSlot> slots) async {
    final walkerId = _walkerId;

    if (walkerId == null) {
      throw StateError('Walker is not authenticated.');
    }

    final batch = _firestore.batch();

    for (final slot in slots) {
      if (slot.walkerId != walkerId) {
        throw StateError(
          'You cannot save another walker\'s slot.',
        );
      }

      final document = _slotsCollection.doc(slot.id);

      batch.set(
        document,
        slot.toMap(),
        SetOptions(merge: true),
      );
    }

    await batch.commit();
  }

  int _sortSlots(
    DailyWalkSlot first,
    DailyWalkSlot second,
  ) {
    final dayComparison = _dayIndex(first.day).compareTo(
      _dayIndex(second.day),
    );

    if (dayComparison != 0) {
      return dayComparison;
    }

    return _timeToMinutes(first.startTime).compareTo(
      _timeToMinutes(second.startTime),
    );
  }

  int _dayIndex(String day) {
    const days = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    final index = days.indexOf(day);

    return index == -1 ? 999 : index;
  }

  int _timeToMinutes(String time) {
    final parts = time.trim().split(' ');

    if (parts.length != 2) {
      return 0;
    }

    final timeParts = parts[0].split(':');

    if (timeParts.length != 2) {
      return 0;
    }

    int hour = int.tryParse(timeParts[0]) ?? 0;
    final minute = int.tryParse(timeParts[1]) ?? 0;
    final period = parts[1].toUpperCase();

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return (hour * 60) + minute;
  }
}
