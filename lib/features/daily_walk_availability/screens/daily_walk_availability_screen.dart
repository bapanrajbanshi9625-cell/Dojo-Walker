import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../models/daily_walk_slot.dart';
import '../services/daily_walk_availability_service.dart';
import '../widgets/add_slot_sheet.dart';
import '../widgets/availability_confirm_dialog.dart';

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
  final DailyWalkAvailabilityService _service =
      DailyWalkAvailabilityService.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final List<DailyWalkSlot> _pendingSlots = <DailyWalkSlot>[];

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoWalkerColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        centerTitle: false,
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
        builder: (
          context,
          snapshot,
        ) {
          if (snapshot.hasError) {
            return _buildErrorState(
              snapshot.error,
            );
          }

          final savedSlots =
              snapshot.data ?? const <DailyWalkSlot>[];

          return _buildBody(
            savedSlots,
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isSaving
            ? null
            : _openAddSlotSheet,
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

  // ============================================================
  // BODY
  // ============================================================

  Widget _buildBody(
    List<DailyWalkSlot> savedSlots,
  ) {
    final allSlots = <DailyWalkSlot>[
      ...savedSlots,
      ..._pendingSlots,
    ];

    allSlots.sort(_sortSlots);

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
          _buildSlotsList(
            allSlots,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SLOTS LIST
  // ============================================================

  Widget _buildSlotsList(
    List<DailyWalkSlot> slots,
  ) {
    if (slots.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 32,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.black.withValues(
              alpha: 0.05,
            ),
          ),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.schedule_rounded,
              size: 42,
              color: Colors.black26,
            ),
            SizedBox(height: 12),
            Text(
              'No walk slots added yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: DojoWalkerColors.navy,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Tap + to add your available walk time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(
            left: 2,
            bottom: 10,
          ),
          child: Text(
            'Your Available Slots',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: DojoWalkerColors.navy,
            ),
          ),
        ),
        ...slots.map(
          (slot) => _buildSlotCard(
            slot,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SLOT CARD
  // ============================================================

  Widget _buildSlotCard(
    DailyWalkSlot slot,
  ) {
    final isPending = _pendingSlots.any(
      (pending) => pending.id == slot.id,
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending
              ? DojoWalkerColors.primary.withValues(
                  alpha: 0.20,
                )
              : Colors.black.withValues(
                  alpha: 0.05,
                ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 10,
            offset: const Offset(
              0,
              3,
            ),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DojoWalkerColors.light,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: DojoWalkerColors.primary,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _slotTimeText(
                    slot,
                  ),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: DojoWalkerColors.navy,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${slot.durationMinutes} minutes',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                if (isPending) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Waiting to be saved',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DojoWalkerColors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: _isSaving
                ? null
                : () {
                    _deleteSlot(
                      slot,
                    );
                  },
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 22,
            ),
            color: Colors.black45,
            tooltip: 'Remove slot',
          ),
        ],
      ),
    );
  }

  String _slotTimeText(
    DailyWalkSlot slot,
  ) {
    final startMinutes = _timeToMinutes(
      slot.startTime,
    );

    final endMinutes =
        startMinutes + slot.durationMinutes;

    return '${_minutesToTime(startMinutes)}'
        ' – '
        '${_minutesToTime(endMinutes)}';
  }

  String _minutesToTime(
    int minutes,
  ) {
    final normalized = minutes % (24 * 60);

    final hour24 = normalized ~/ 60;
    final minute = normalized % 60;

    final period = hour24 >= 12
        ? 'PM'
        : 'AM';

    int hour12 = hour24 % 12;

    if (hour12 == 0) {
      hour12 = 12;
    }

    return '${hour12.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} '
        '$period';
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.05,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(
              0,
              4,
            ),
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
            'Add the time slots when you are '
            'available for walks.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.45,
            ),
          ),
          SizedBox(height: 13),
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
          SizedBox(height: 6),
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

  // ============================================================
  // PENDING NOTICE
  // ============================================================

  Widget _buildPendingNotice() {
    final count = _pendingSlots.length;

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
          color: DojoWalkerColors.primary.withValues(
            alpha: 0.15,
          ),
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
              '$count slot${count == 1 ? '' : 's'} '
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

  // ============================================================
  // SAVE BAR
  // ============================================================

  Widget _buildSaveBar() {
    final count = _pendingSlots.length;

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
              color: Colors.black.withValues(
                alpha: 0.08,
              ),
              blurRadius: 12,
              offset: const Offset(
                0,
                -3,
              ),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: _isSaving
                ? null
                : _saveAvailability,
            style: FilledButton.styleFrom(
              backgroundColor:
                  DojoWalkerColors.primary,
              disabledBackgroundColor:
                  Colors.black.withValues(
                alpha: 0.08,
              ),
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
                    'Save Availability ($count)',
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

  // ============================================================
  // ADD SLOT
  // ============================================================

  Future<void> _openAddSlotSheet() async {
    final slot =
        await showModalBottomSheet<DailyWalkSlot>(
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

    if (walkerId == null || walkerId.isEmpty) {
      _showMessage(
        'Walker is not authenticated.',
      );
      return;
    }

    final normalizedSlot = slot.copyWith(
      id: _createTemporaryId(),
      walkerId: walkerId,
    );

    if (_isDuplicatePending(
      normalizedSlot,
    )) {
      _showMessage(
        'This slot is already added.',
      );
      return;
    }

    setState(() {
      _pendingSlots.add(
        normalizedSlot,
      );
    });
  }

  // ============================================================
  // DUPLICATE PENDING SLOT
  // ============================================================

  bool _isDuplicatePending(
    DailyWalkSlot slot,
  ) {
    return _pendingSlots.any(
      (existing) =>
          existing.startTime == slot.startTime &&
          existing.durationMinutes ==
              slot.durationMinutes,
    );
  }

  // ============================================================
  // SAVE AVAILABILITY
  // ============================================================

  Future<void> _saveAvailability() async {
    if (_pendingSlots.isEmpty ||
        _isSaving) {
      return;
    }

    final slotsToSave =
        List<DailyWalkSlot>.unmodifiable(
      _pendingSlots,
    );

    final confirmed =
        await AvailabilityConfirmDialog.show(
      context,
      slots: slotsToSave,
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.saveSlots(
        slotsToSave,
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

  // ============================================================
  // DELETE
  // ============================================================

  Future<void> _deleteSlot(
    DailyWalkSlot slot,
  ) async {
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
      await _service.deleteSlot(
        slot.id,
      );

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

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState(
    Object? error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 44,
              color: Colors.black38,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load availability.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: DojoWalkerColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _friendlyError(error),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  String _createTemporaryId() {
    return 'pending_'
        '${DateTime.now().microsecondsSinceEpoch}';
  }

  String _friendlyError(
    Object? error,
  ) {
    if (error is StateError) {
      return error.message;
    }

    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return 'You do not have permission to update availability.';
      }

      if (error.message != null &&
          error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    return 'Something went wrong. Please try again.';
  }

  void _showMessage(
    String message,
  ) {
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
