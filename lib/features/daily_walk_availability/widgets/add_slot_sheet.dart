import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../services/daily_walk_availability_service.dart';

class AddSlotSheet extends StatefulWidget {
  const AddSlotSheet({
    super.key,
    required this.onSlotAdded,
  });

  final VoidCallback onSlotAdded;

  @override
  State<AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<AddSlotSheet> {
  final DailyWalkAvailabilityService _service =
      DailyWalkAvailabilityService.instance;

  String _selectedDay = 'Monday';
  TimeOfDay _startTime = const TimeOfDay(
    hour: 4,
    minute: 0,
  );

  int _durationMinutes = 30;
  bool _isSaving = false;

  static const List<String> _days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  TimeOfDay get _endTime {
    final totalMinutes =
        (_startTime.hour * 60) +
        _startTime.minute +
        _durationMinutes;

    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;

    return TimeOfDay(
      hour: hour,
      minute: minute,
    );
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );

    if (picked == null || !mounted) {
      return;
    }

    final startMinutes =
        (picked.hour * 60) + picked.minute;

    final endMinutes =
        startMinutes + _durationMinutes;

    const earliestMinutes = 4 * 60;
    const latestMinutes = 22 * 60;

    if (startMinutes < earliestMinutes ||
        endMinutes > latestMinutes) {
      _showMessage(
        'Walk time must be between 4:00 AM and 10:00 PM.',
      );
      return;
    }

    setState(() {
      _startTime = picked;
    });
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0
        ? 12
        : time.hourOfPeriod;

    final minute =
        time.minute.toString().padLeft(2, '0');

    final period =
        time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $period';
  }

  Future<void> _addSlot() async {
    if (_isSaving) {
      return;
    }

    final startMinutes =
        (_startTime.hour * 60) + _startTime.minute;

    final endMinutes =
        startMinutes + _durationMinutes;

    if (startMinutes < 4 * 60 ||
        endMinutes > 22 * 60) {
      _showMessage(
        'Please select a time between 4:00 AM and 10:00 PM.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _service.addSlot(
        day: _selectedDay,
        startTime: _formatTime(_startTime),
        endTime: _formatTime(_endTime),
        durationMinutes: _durationMinutes,
      );

      if (!mounted) {
        return;
      }

      widget.onSlotAdded();

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Walk slot added successfully.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      _showMessage(
        error.toString().replaceFirst(
          'Exception: ',
          '',
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Add Walk Slot',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: DojoWalkerColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Add a regular walk slot for your selected day.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'Day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _selectedDay,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: DojoWalkerColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _days.map((day) {
                  return DropdownMenuItem<String>(
                    value: day,
                    child: Text(day),
                  );
                }).toList(),
                onChanged: _isSaving
                    ? null
                    : (value) {
                        if (value == null) {
                          return;
                        }

                        setState(() {
                          _selectedDay = value;
                        });
                      },
              ),

              const SizedBox(height: 20),

              const Text(
                'Start Time',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              InkWell(
                onTap: _isSaving
                    ? null
                    : _selectStartTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    color: DojoWalkerColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: DojoWalkerColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _formatTime(_startTime),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Walk Duration',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _durationButton(
                      label: '30 Minutes',
                      value: 30,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _durationButton(
                      label: '1 Hour',
                      value: 60,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DojoWalkerColors.light,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      color: DojoWalkerColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        '${_formatTime(_startTime)} – '
                        '${_formatTime(_endTime)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              Navigator.of(context).pop();
                            },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(
                          double.infinity,
                          50,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _isSaving ? null : _addSlot,
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            DojoWalkerColors.primary,
                        minimumSize: const Size(
                          double.infinity,
                          50,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Add Slot'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _durationButton({
    required String label,
    required int value,
  }) {
    final selected = _durationMinutes == value;

    return InkWell(
      onTap: _isSaving
          ? null
          : () {
              final startMinutes =
                  (_startTime.hour * 60) +
                  _startTime.minute;

              if (startMinutes + value > 22 * 60) {
                _showMessage(
                  'This duration goes beyond 10:00 PM.',
                );
                return;
              }

              setState(() {
                _durationMinutes = value;
              });
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 15,
        ),
        decoration: BoxDecoration(
          color: selected
              ? DojoWalkerColors.primary
              : DojoWalkerColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? DojoWalkerColors.primary
                : Colors.black12,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected
                  ? Colors.white
                  : DojoWalkerColors.navy,
            ),
          ),
        ),
      ),
    );
  }
}
