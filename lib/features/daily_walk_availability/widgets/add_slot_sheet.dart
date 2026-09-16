import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../models/daily_walk_slot.dart';

class AddSlotSheet extends StatefulWidget {
  const AddSlotSheet({
    super.key,
  });

  @override
  State<AddSlotSheet> createState() => _AddSlotSheetState();
}

class _AddSlotSheetState extends State<AddSlotSheet> {
  static const List<String> _days = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const int _openingMinutes = 4 * 60;
  static const int _closingMinutes = 22 * 60;

  String _selectedDay = 'Monday';
  TimeOfDay _selectedStartTime = const TimeOfDay(
    hour: 4,
    minute: 0,
  );
  int _selectedDuration = 30;

  int get _startMinutes =>
      (_selectedStartTime.hour * 60) + _selectedStartTime.minute;

  int get _endMinutes => _startMinutes + _selectedDuration;

  bool get _isValidTime =>
      _startMinutes >= _openingMinutes &&
      _endMinutes <= _closingMinutes;

  String _formatTime(int totalMinutes) {
    final hour24 = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;

    final period = hour24 >= 12 ? 'PM' : 'AM';

    int hour12 = hour24 % 12;
    if (hour12 == 0) {
      hour12 = 12;
    }

    return '${hour12.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')} $period';
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedStartTime,
      helpText: 'Select Start Time',
    );

    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      _selectedStartTime = picked;
    });
  }

  void _selectDuration(int duration) {
    setState(() {
      _selectedDuration = duration;
    });
  }

  void _addSlot() {
    if (!_isValidTime) {
      _showMessage(
        'Slot must be between 4:00 AM and 10:00 PM.',
      );
      return;
    }

    final startTime = _formatTime(_startMinutes);
    final endTime = _formatTime(_endMinutes);

    final slot = DailyWalkSlot(
      id: '',
      walkerId: '',
      day: _selectedDay,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: _selectedDuration,
      isActive: true,
    );

    Navigator.of(context).pop(slot);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final endTime = _formatTime(_endMinutes);
    final isValid = _isValidTime;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                'Add Walk Slot',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: DojoWalkerColors.navy,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Choose your available day, start time and walk duration.',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),

              const Text(
                'Day',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DojoWalkerColors.navy,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                ),
                decoration: BoxDecoration(
                  color: DojoWalkerColors.background,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: Colors.black.withValues(alpha: 0.07),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedDay,
                    isExpanded: true,
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                    ),
                    items: _days.map(
                      (day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      setState(() {
                        _selectedDay = value;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Start Time',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: DojoWalkerColors.navy,
                ),
              ),
              const SizedBox(height: 8),

              InkWell(
                onTap: _selectStartTime,
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: DojoWalkerColors.background,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.07),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        color: DojoWalkerColors.primary,
                        size: 21,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _formatTime(_startMinutes),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: DojoWalkerColors.navy,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.black45,
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
                  fontWeight: FontWeight.w700,
                  color: DojoWalkerColors.navy,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: _DurationButton(
                      label: '30 Minutes',
                      selected: _selectedDuration == 30,
                      onTap: () => _selectDuration(30),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DurationButton(
                      label: '1 Hour',
                      selected: _selectedDuration == 60,
                      onTap: () => _selectDuration(60),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: isValid
                      ? DojoWalkerColors.light
                      : Colors.red.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(
                      isValid
                          ? Icons.check_circle_outline_rounded
                          : Icons.error_outline_rounded,
                      size: 19,
                      color: isValid
                          ? DojoWalkerColors.primary
                          : Colors.red,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        '$_selectedDay  •  '
                        '${_formatTime(_startMinutes)} – $endTime',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isValid
                              ? DojoWalkerColors.deep
                              : Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: isValid ? _addSlot : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: DojoWalkerColors.primary,
                    disabledBackgroundColor:
                        Colors.black.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Add Slot',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationButton extends StatelessWidget {
  const _DurationButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected
                ? DojoWalkerColors.primary
                : DojoWalkerColors.background,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected
                  ? DojoWalkerColors.primary
                  : Colors.black.withValues(alpha: 0.07),
            ),
          ),
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
