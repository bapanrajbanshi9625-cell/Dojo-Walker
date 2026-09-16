import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../models/daily_walk_slot.dart';
import 'availability_slot_tile.dart';

class AvailabilityDaySection extends StatelessWidget {
  const AvailabilityDaySection({
    super.key,
    required this.day,
    required this.slots,
    required this.onDeleteSlot,
  });

  final String day;
  final List<DailyWalkSlot> slots;
  final ValueChanged<DailyWalkSlot> onDeleteSlot;

  @override
  Widget build(BuildContext context) {
    final hasSlots = slots.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: DojoWalkerColors.navy,
                  ),
                ),
              ),
              if (hasSlots)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: DojoWalkerColors.light,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${slots.length} ${slots.length == 1 ? 'Slot' : 'Slots'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: DojoWalkerColors.deep,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasSlots)
            const Padding(
              padding: EdgeInsets.only(
                top: 2,
                bottom: 2,
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
            ...slots.map(
              (slot) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AvailabilitySlotTile(
                  slot: slot,
                  onDelete: () => onDeleteSlot(slot),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
