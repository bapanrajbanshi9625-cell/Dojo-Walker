import 'package:flutter/material.dart';

import '../../../core/theme/dojo_walker_colors.dart';
import '../models/daily_walk_slot.dart';

class AddSlotSheet extends StatelessWidget {
  const AddSlotSheet({
    super.key,
  });

  static const int _openingMinutes = 4 * 60;
  static const int _closingMinutes = 22 * 60;

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

  DailyWalkSlot _createSlot({
    required int startMinutes,
    required int durationMinutes,
  }) {
    final endMinutes =
        startMinutes + durationMinutes;

    return DailyWalkSlot(
      id: '',
      walkerId: '',
      startTime: _formatTime(startMinutes),
      endTime: _formatTime(endMinutes),
      durationMinutes: durationMinutes,
      isActive: true,
    );
  }

  void _addSlot(
    BuildContext context, {
    required int startMinutes,
    required int durationMinutes,
  }) {
    final slot = _createSlot(
      startMinutes: startMinutes,
      durationMinutes: durationMinutes,
    );

    Navigator.of(context).pop(slot);
  }

  @override
  Widget build(BuildContext context) {
    final startTimes = <int>[];

    for (
      int minutes = _openingMinutes;
      minutes <= _closingMinutes - 30;
      minutes += 30
    ) {
      startTimes.add(minutes);
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // --------------------------------------------------
            // HANDLE
            // --------------------------------------------------

            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: 0.12,
                  ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // TITLE
            // --------------------------------------------------

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
              'Choose a time when you are available for daily walks.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 18),

            // --------------------------------------------------
            // INFO
            // --------------------------------------------------

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: DojoWalkerColors.light,
                borderRadius:
                    BorderRadius.circular(13),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.repeat_rounded,
                    size: 19,
                    color: DojoWalkerColors.primary,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Each slot repeats every day.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: DojoWalkerColors.deep,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Quick Select Time',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: DojoWalkerColors.navy,
              ),
            ),

            const SizedBox(height: 8),

            // --------------------------------------------------
            // SERIAL TIME LIST
            // --------------------------------------------------

            SizedBox(
              height: 390,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: startTimes.length,
                itemBuilder: (
                  context,
                  index,
                ) {
                  final start =
                      startTimes[index];

                  final has30Minutes =
                      start + 30 <=
                          _closingMinutes;

                  final has1Hour =
                      start + 60 <=
                          _closingMinutes;

                  return Padding(
                    padding:
                        const EdgeInsets.only(
                      bottom: 12,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // START TIME
                        Padding(
                          padding:
                              const EdgeInsets.only(
                            left: 2,
                            bottom: 7,
                          ),
                          child: Text(
                            _formatTime(start),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight:
                                  FontWeight.w800,
                              color:
                                  DojoWalkerColors.navy,
                            ),
                          ),
                        ),

                        // 30 MINUTES
                        if (has30Minutes)
                          _SlotOption(
                            label:
                                '${_formatTime(start)} – '
                                '${_formatTime(start + 30)}',
                            durationLabel:
                                '30 min',
                            onTap: () {
                              _addSlot(
                                context,
                                startMinutes:
                                    start,
                                durationMinutes:
                                    30,
                              );
                            },
                          ),

                        if (has30Minutes &&
                            has1Hour)
                          const SizedBox(
                            height: 7,
                          ),

                        // 1 HOUR
                        if (has1Hour)
                          _SlotOption(
                            label:
                                '${_formatTime(start)} – '
                                '${_formatTime(start + 60)}',
                            durationLabel:
                                '1 hour',
                            onTap: () {
                              _addSlot(
                                context,
                                startMinutes:
                                    start,
                                durationMinutes:
                                    60,
                              );
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            SizedBox(
              width: double.infinity,
              height: 44,
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
    );
  }
}

class _SlotOption extends StatelessWidget {
  const _SlotOption({
    required this.label,
    required this.durationLabel,
    required this.onTap,
  });

  final String label;
  final String durationLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(13),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: DojoWalkerColors.background,
            borderRadius:
                BorderRadius.circular(13),
            border: Border.all(
              color: Colors.black.withValues(
                alpha: 0.07,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            DojoWalkerColors.navy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      durationLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color:
                      DojoWalkerColors.primary,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
