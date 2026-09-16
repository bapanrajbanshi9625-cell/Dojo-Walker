import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../models/daily_walk_slot.dart';

class AvailabilitySlotTile extends StatelessWidget {
  const AvailabilitySlotTile({
    super.key,
    required this.slot,
    required this.onDelete,
  });

  final DailyWalkSlot slot;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: DojoWalkerColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: DojoWalkerColors.light,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              size: 21,
              color: DojoWalkerColors.primary,
            ),
          ),
          const SizedBox(width: 11),
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
            onPressed: () => _confirmDelete(context),
            tooltip: 'Delete slot',
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 21,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Slot?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: DojoWalkerColors.navy,
            ),
          ),
          content: Text(
            'Remove ${slot.day} ${slot.startTime} – ${slot.endTime} '
            'from your availability?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: DojoWalkerColors.primary,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      onDelete();
    }
  }
}
