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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please confirm the walk slots you want to add:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              ..._buildSlotGroups(),
            ],
          ),
        ),
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
          child: const Text('Confirm'),
        ),
      ],
    );
  }

  List<Widget> _buildSlotGroups() {
    final grouped = <String, List<DailyWalkSlot>>{};

    for (final slot in slots) {
      grouped.putIfAbsent(
        slot.day,
        () => <DailyWalkSlot>[],
      ).add(slot);
    }

    return grouped.entries.map((entry) {
      final day = entry.key;
      final daySlots = entry.value;

      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: DojoWalkerColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                day,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: DojoWalkerColors.navy,
                ),
              ),
              const SizedBox(height: 8),
              ...daySlots.map(
                (slot) => Padding(
                  padding: const EdgeInsets.only(
                    bottom: 6,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: DojoWalkerColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${slot.startTime} – ${slot.endTime}\n'
                          '${slot.durationLabel}',
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
