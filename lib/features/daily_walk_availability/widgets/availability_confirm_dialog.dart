import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../models/daily_walk_slot.dart';

class AvailabilityConfirmDialog extends StatelessWidget {
  const AvailabilityConfirmDialog({
    super.key,
    required this.slots,
  });

  final List<DailyWalkSlot> slots;

  static Future<bool?> show(
    BuildContext context, {
    required List<DailyWalkSlot> slots,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) {
        return AvailabilityConfirmDialog(
          slots: slots,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Confirm Availability',
        style: TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w700,
          color: DojoWalkerColors.navy,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(
          maxHeight: 420,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Please confirm the daily walk slots you want to add:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 16),

              ..._buildSlots(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false);
          },
          child: const Text(
            'Cancel',
          ),
        ),

        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          style: FilledButton.styleFrom(
            backgroundColor:
                DojoWalkerColors.primary,
          ),
          child: const Text(
            'Confirm',
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSlots() {
    final sortedSlots =
        List<DailyWalkSlot>.from(slots);

    sortedSlots.sort(
      _sortSlots,
    );

    return sortedSlots.map(
      (slot) {
        return Padding(
          padding: const EdgeInsets.only(
            bottom: 10,
          ),
          child: Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 11,
            ),
            decoration: BoxDecoration(
              color:
                  DojoWalkerColors.background,
              borderRadius:
                  BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 19,
                  color:
                      DojoWalkerColors.primary,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${slot.startTime} – '
                        '${slot.endTime}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.w700,
                          color:
                              DojoWalkerColors.navy,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        '${slot.durationLabel} • Every day',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600,
                          color:
                              Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).toList();
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
    final parts =
        time.trim().split(' ');

    if (parts.length != 2) {
      return 0;
    }

    final timeParts =
        parts[0].split(':');

    if (timeParts.length != 2) {
      return 0;
    }

    int hour =
        int.tryParse(
              timeParts[0],
            ) ??
            0;

    final minute =
        int.tryParse(
              timeParts[1],
            ) ??
            0;

    final period =
        parts[1].toUpperCase();

    if (period == 'PM' &&
        hour != 12) {
      hour += 12;
    }

    if (period == 'AM' &&
        hour == 12) {
      hour = 0;
    }

    return (hour * 60) + minute;
  }
}
