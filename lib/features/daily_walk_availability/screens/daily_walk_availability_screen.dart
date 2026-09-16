import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../models/daily_walk_slot.dart';
import '../services/daily_walk_availability_service.dart';
import '../widgets/add_slot_sheet.dart';
import '../widgets/availability_confirm_dialog.dart';
import '../widgets/availability_day_section.dart';

class DailyWalkAvailabilityScreen extends StatefulWidget {
  const DailyWalkAvailabilityScreen({
    super.key,
  });

  @override
  State<DailyWalkAvailabilityScreen> createState() =>
      _DailyWalkAvailabilityScreenState();
}

class _DailyWalkAvailabilityScreenState
    extends State<DailyWalkAvailabilityScreen> {
  static const List<String> _days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  final DailyWalkAvailabilityService _service =
      DailyWalkAvailabilityService.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<DailyWalkSlot> _pendingSlots =
      <DailyWalkSlot>[];

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoWalkerColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Daily Walk Availability',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: DojoWalkerColors.navy,
          ),
        ),
      ),
      body: StreamBuilder<List<DailyWalkSlot>>(
        stream: _service.watchMySlots(),
        builder: (context, snapshot) {
          final savedSlots =
              snapshot.data ?? const <DailyWalkSlot>[];

          return _buildBody(savedSlots);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving ? null : _openAddSlotSheet,
        backgroundColor: DojoWalkerColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(
          Icons.add_rounded,
          size: 28,
        ),
      ),
      bottomNavigationBar: _pendingSlots.isEmpty
          ? null
          : _buildSaveBar(),
    );
  }

  Widget _buildBody(List<DailyWalkSlot> savedSlots) {
    final allSlots = <DailyWalkSlot>[
      ...savedSlots,
      ..._pendingSlots,
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ),
        children: [
          _buildHeader(),
          const SizedBox(height: 16),

          if (_pendingSlots.isNotEmpty)
            _buildPendingNotice(),

          if (_pendingSlots.isNotEmpty)
            const SizedBox(height: 12),

          ..._days.map(
            (day) {
              final daySlots = allSlots
                  .where((slot) => slot.day == day)
                  .toList();

              daySlots.sort(_sortSlots);

              return AvailabilityDaySection(
                day: day,
                slots: daySlots,
                onDeleteSlot: (slot) {
                  _deleteSlot(
                    slot,
                    savedSlots: savedSlots,
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Walk Availability',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: DojoWalkerColors.navy,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Add the days and time slots when you are '
            'available for daily walks.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.45,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 18,
                color: DojoWalkerColors.primary,
              ),
              SizedBox(width: 7),
              Text(
                'Available time: 4:00 AM – 10:00 PM',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DojoWalkerColors.deep,
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.timelapse_rounded,
                size: 18,
                color: DojoWalkerColors.primary,
              ),
              SizedBox(width: 7),
              Text(
                'Walk duration: 30 Minutes or 1 Hour',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: DojoWalkerColors.deep,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: DojoWalkerColors.light,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: DojoWalkerColors.primary
              .withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.pending_actions_rounded,
            size: 20,
            color: DojoWalkerColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_pendingSlots.length} slot'
              '${_pendingSlots.length == 1 ? '' : 's'} '
              'waiting to be saved.',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DojoWalkerColors.deep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          16,
          10,
          16,
          10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _isSaving ? null : _saveAvailability,
            style: FilledButton.styleFrom(
              backgroundColor: DojoWalkerColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 21,
                    height: 21,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.3,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : Text(
                    'Save Availability'
                    ' (${_pendingSlots.length})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAddSlotSheet() async {
    final slot = await showModalBottomSheet<DailyWalkSlot>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      builder: (_) {
        return const AddSlotSheet();
      },
    );

    if (slot == null || !mounted) {
      return;
    }

    final walkerId = _auth.currentUser?.uid;

    if (walkerId == null) {
      _showMessage(
        'Walker is not authenticated.',
      );
      return;
    }

    final normalizedSlot = slot.copyWith(
      id: _createTemporaryId(),
      walkerId: walkerId,
    );

    if (_isDuplicatePending(normalizedSlot)) {
      _showMessage(
        'This slot is already added.',
      );
      return;
    }

    setState(() {
      _pendingSlots.add(normalizedSlot);
    });
  }

  bool _isDuplicatePending(DailyWalkSlot slot) {
    return _pendingSlots.any(
      (existing) =>
          existing.day == slot.day &&
          existing.startTime == slot.startTime &&
          existing.durationMinutes ==
              slot.durationMinutes,
    );
  }

  bool _isDuplicateSaved(
    DailyWalkSlot pending,
    List<DailyWalkSlot> savedSlots,
  ) {
    return savedSlots.any(
      (saved) =>
          saved.day == pending.day &&
          saved.startTime == pending.startTime &&
          saved.durationMinutes ==
              pending.durationMinutes &&
          saved.isActive,
    );
  }

  Future<void> _saveAvailability() async {
    if (_pendingSlots.isEmpty) {
      return;
    }

    final savedSlots = await _service.getMySlots();

    final duplicateExists = _pendingSlots.any(
      (pending) => _isDuplicateSaved(
        pending,
        savedSlots,
      ),
    );

    if (duplicateExists) {
      if (!mounted) {
        return;
      }

      _showMessage(
        'One or more selected slots already exist.',
      );
      return;
    }

    final confirmed = await AvailabilityConfirmDialog.show(
      context,
      slots: List<DailyWalkSlot>.unmodifiable(
        _pendingSlots,
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.saveSlots(
        List<DailyWalkSlot>.from(
          _pendingSlots,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _pendingSlots.clear();
        _isSaving = false;
      });

      _showMessage(
        'Availability saved successfully.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      _showMessage(
        _friendlyError(error),
      );
    }
  }

  Future<void> _deleteSlot(
    DailyWalkSlot slot, {
    required List<DailyWalkSlot> savedSlots,
  }) async {
    if (_pendingSlots.any(
      (pending) => pending.id == slot.id,
    )) {
      setState(() {
        _pendingSlots.removeWhere(
          (pending) => pending.id == slot.id,
        );
      });
      return;
    }

    if (slot.id.isEmpty) {
      return;
    }

    try {
      await _service.deleteSlot(slot.id);

      if (!mounted) {
        return;
      }

      _showMessage(
        'Slot removed.',
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        _friendlyError(error),
      );
    }
  }

  String _createTemporaryId() {
    return 'pending_${DateTime.now().microsecondsSinceEpoch}';
  }

  String _friendlyError(Object error) {
    if (error is StateError) {
      return error.message;
    }

    return 'Something went wrong. Please try again.';
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  int _sortSlots(
    DailyWalkSlot first,
    DailyWalkSlot second,
  ) {
    final firstMinutes = _timeToMinutes(
      first.startTime,
    );

    final secondMinutes = _timeToMinutes(
      second.startTime,
    );

    return firstMinutes.compareTo(secondMinutes);
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
