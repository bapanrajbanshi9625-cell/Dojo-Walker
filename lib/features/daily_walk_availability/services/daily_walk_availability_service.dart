import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/daily_walk_slot.dart';

class DailyWalkAvailabilityService {
  DailyWalkAvailabilityService._();

  static final DailyWalkAvailabilityService instance =
      DailyWalkAvailabilityService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  static const String _collection =
      'daily_walk_availability';

  String? get _walkerId =>
      _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>
      get _slotsCollection =>
          _firestore.collection(_collection);

  // ============================================================
  // WATCH MY SLOTS
  // ============================================================

  Stream<List<DailyWalkSlot>> watchMySlots() {
    final walkerId = _walkerId;

    if (walkerId == null || walkerId.isEmpty) {
      return Stream.value(
        const <DailyWalkSlot>[],
      );
    }

    return _slotsCollection
        .where(
          'walkerId',
          isEqualTo: walkerId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .snapshots()
        .map(
      (snapshot) {
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
      },
    );
  }

  // ============================================================
  // GET MY SLOTS
  // ============================================================

  Future<List<DailyWalkSlot>> getMySlots() async {
    final walkerId = _walkerId;

    if (walkerId == null || walkerId.isEmpty) {
      return const <DailyWalkSlot>[];
    }

    final snapshot = await _slotsCollection
        .where(
          'walkerId',
          isEqualTo: walkerId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
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

  // ============================================================
  // SAVE PENDING SLOTS
  // ============================================================

  Future<void> saveSlots(
    List<DailyWalkSlot> slots,
  ) async {
    final walkerId = _walkerId;

    if (walkerId == null || walkerId.isEmpty) {
      throw StateError(
        'Walker is not authenticated.',
      );
    }

    if (slots.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // Validate pending slots.
    // ----------------------------------------------------------

    for (final slot in slots) {
      if (slot.startTime.trim().isEmpty) {
        throw ArgumentError(
          'Start time is required.',
        );
      }

      if (slot.endTime.trim().isEmpty) {
        throw ArgumentError(
          'End time is required.',
        );
      }

      if (slot.durationMinutes != 30 &&
          slot.durationMinutes != 60) {
        throw ArgumentError(
          'Duration must be either 30 or 60 minutes.',
        );
      }

      if (slot.walkerId.isNotEmpty &&
          slot.walkerId != walkerId) {
        throw StateError(
          'You cannot save another walker\'s slot.',
        );
      }
    }

    // ----------------------------------------------------------
    // Check duplicates against existing Firebase slots.
    // ----------------------------------------------------------

    final existingSnapshot = await _slotsCollection
        .where(
          'walkerId',
          isEqualTo: walkerId,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .get();

    final existingSlots = existingSnapshot.docs
        .map(
          (doc) => DailyWalkSlot.fromMap({
            ...doc.data(),
            'id': doc.id,
          }),
        )
        .toList();

    for (final pendingSlot in slots) {
      final duplicateExists = existingSlots.any(
        (existingSlot) =>
            existingSlot.startTime ==
                pendingSlot.startTime &&
            existingSlot.durationMinutes ==
                pendingSlot.durationMinutes &&
            existingSlot.isActive,
      );

      if (duplicateExists) {
        throw StateError(
          'This slot has already been added.',
        );
      }
    }

    // ----------------------------------------------------------
    // Check duplicates inside pending list.
    // ----------------------------------------------------------

    for (int i = 0; i < slots.length; i++) {
      for (int j = i + 1; j < slots.length; j++) {
        final first = slots[i];
        final second = slots[j];

        final duplicate =
            first.startTime == second.startTime &&
            first.durationMinutes ==
                second.durationMinutes;

        if (duplicate) {
          throw StateError(
            'The same slot cannot be added twice.',
          );
        }
      }
    }

    // ----------------------------------------------------------
    // Save all slots in one batch.
    // ----------------------------------------------------------

    final batch = _firestore.batch();

    for (final slot in slots) {
      final document =
          _slotsCollection.doc();

      final savedSlot = DailyWalkSlot(
        id: document.id,
        walkerId: walkerId,
        startTime: slot.startTime,
        endTime: slot.endTime,
        durationMinutes: slot.durationMinutes,
        isActive: true,
      );

      batch.set(
        document,
        savedSlot.toMap(),
      );
    }

    await batch.commit();
  }

  // ============================================================
  // ADD SINGLE SLOT
  // ============================================================

  Future<String> addSlot({
    required String startTime,
    required String endTime,
    required int durationMinutes,
  }) async {
    final walkerId = _walkerId;

    if (walkerId == null || walkerId.isEmpty) {
      throw StateError(
        'Walker is not authenticated.',
      );
    }

    if (durationMinutes != 30 &&
        durationMinutes != 60) {
      throw ArgumentError(
        'Duration must be either 30 or 60 minutes.',
      );
    }

    final duplicate = await _slotsCollection
        .where(
          'walkerId',
          isEqualTo: walkerId,
        )
        .where(
          'startTime',
          isEqualTo: startTime,
        )
        .where(
          'durationMinutes',
          isEqualTo: durationMinutes,
        )
        .where(
          'isActive',
          isEqualTo: true,
        )
        .limit(1)
        .get();

    if (duplicate.docs.isNotEmpty) {
      throw StateError(
        'This slot has already been added.',
      );
    }

    final document =
        _slotsCollection.doc();

    final slot = DailyWalkSlot(
      id: document.id,
      walkerId: walkerId,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
      isActive: true,
    );

    await document.set(
      slot.toMap(),
    );

    return document.id;
  }

  // ============================================================
  // UPDATE SLOT
  // ============================================================

  Future<void> updateSlot(
    DailyWalkSlot slot,
  ) async {
    final walkerId = _walkerId;

    if (walkerId == null || walkerId.isEmpty) {
      throw StateError(
        'Walker is not authenticated.',
      );
    }

    if (slot.id.isEmpty) {
      throw ArgumentError(
        'Slot ID cannot be empty.',
      );
    }

    if (slot.walkerId != walkerId) {
      throw StateError(
        'You cannot update another walker\'s slot.',
      );
    }

    if (slot.durationMinutes != 30 &&
        slot.durationMinutes != 60) {
      throw ArgumentError(
        'Duration must be either 30 or 60 minutes.',
      );
    }

    final updatedSlot = slot.copyWith(
      walkerId: walkerId,
      isActive: true,
    );

    await _slotsCollection
        .doc(slot.id)
        .set(
          updatedSlot.toMap(),
          SetOptions(
            merge: true,
          ),
        );
  }

  // ============================================================
  // DELETE SLOT
  // ============================================================

  Future<void> deleteSlot(
    String slotId,
  ) async {
    final walkerId = _walkerId;

    if (walkerId == null || walkerId.isEmpty) {
      throw StateError(
        'Walker is not authenticated.',
      );
    }

    if (slotId.trim().isEmpty) {
      return;
    }

    final document =
        await _slotsCollection.doc(slotId).get();

    if (!document.exists) {
      return;
    }

    final data = document.data();

    if (data == null ||
        data['walkerId'] != walkerId) {
      throw StateError(
        'You cannot delete another walker\'s slot.',
      );
    }

    await _slotsCollection
        .doc(slotId)
        .update({
      'isActive': false,
    });
  }

  // ============================================================
  // SORT
  // ============================================================

  int _sortSlots(
    DailyWalkSlot first,
    DailyWalkSlot second,
  ) {
    return _timeToMinutes(
      first.startTime,
    ).compareTo(
      _timeToMinutes(
        second.startTime,
      ),
    );
  }

  int _timeToMinutes(
    String time,
  ) {
    final parts = time.trim().split(' ');

    if (parts.length != 2) {
      return 0;
    }

    final timeParts =
        parts[0].split(':');

    if (timeParts.length != 2) {
      return 0;
    }

    int hour =
        int.tryParse(timeParts[0]) ?? 0;

    final minute =
        int.tryParse(timeParts[1]) ?? 0;

    final period =
        parts[1].toUpperCase();

    if (period == 'PM' && hour != 12) {
      hour += 12;
    }

    if (period == 'AM' && hour == 12) {
      hour = 0;
    }

    return (hour * 60) + minute;
  }
}
