import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../models/daily_walk_slot.dart';
import '../services/daily_walk_availability_service.dart';
import '../widgets/add_slot_sheet.dart';

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

  StreamSubscription<List<DailyWalkSlot>>? _subscription;

  List<DailyWalkSlot> _slots = const <DailyWalkSlot>[];
  bool _isLoading = true;
  String? _errorMessage;

  static const List<String> _days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _listenToSlots();
  }

  void _listenToSlots() {
    _subscription = _service.watchMySlots().listen(
      (slots) {
        if (!mounted) {
          return;
        }

        setState(() {
          _slots = slots;
          _isLoading = false;
          _errorMessage = null;
        });
      },
      onError: (Object error) {
        if (!mounted) {
          return;
        }

        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load availability.';
        });
      },
    );
  }

  List<DailyWalkSlot> _slotsForDay(String day) {
    return _slots.where((slot) => slot.day == day).toList();
  }

  void _openAddSlotSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      builder: (context) {
        return AddSlotSheet(
          onSlotAdded: () {
            // Firestore stream automatically refreshes the screen.
          },
        );
      },
    );
  }

  Future<void> _deleteSlot(DailyWalkSlot slot) async {
    try {
      await _service.deleteSlot(slot.id);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Slot removed.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(DailyWalkSlot slot) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Slot?'),
          content: Text(
            '${slot.day}\n'
            '${slot.startTime} – ${slot.endTime}\n'
            '${slot.durationLabel}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: DojoWalkerColors.primary,
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      await _deleteSlot(slot);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DojoWalkerColors.background,
      appBar: AppBar(
        title: const Text('Daily Walk Availability'),
        backgroundColor: Colors.white,
        foregroundColor: DojoWalkerColors.navy,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddSlotSheet,
        backgroundColor: DojoWalkerColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAvailabilityHeader(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        8,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Walk Availability',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: DojoWalkerColors.navy,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Add your regular walk slots between 4:00 AM and 10:00 PM.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.4,
            ),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 20,
                color: DojoWalkerColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                '04:00 AM – 10:00 PM',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: DojoWalkerColors.navy,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Walk duration: 30 Minutes or 1 Hour',
            style: TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        100,
      ),
      itemCount: _days.length,
      itemBuilder: (context, index) {
        final day = _days[index];
        final daySlots = _slotsForDay(day);

        return _buildDaySection(
          day: day,
          slots: daySlots,
        );
      },
    );
  }

  Widget _buildDaySection({
    required String day,
    required List<DailyWalkSlot> slots,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: DojoWalkerColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          if (slots.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Text(
                'No slots added yet',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                ),
              ),
            )
          else
            ...slots.map(_buildSlotTile),
        ],
      ),
    );
  }

  Widget _buildSlotTile(DailyWalkSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: DojoWalkerColors.light,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule_rounded,
            size: 20,
            color: DojoWalkerColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${slot.startTime} – ${slot.endTime}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: DojoWalkerColors.navy,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  slot.durationLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(slot),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 21,
            ),
            color: Colors.black45,
            tooltip: 'Remove slot',
          ),
        ],
      ),
    );
  }
}
