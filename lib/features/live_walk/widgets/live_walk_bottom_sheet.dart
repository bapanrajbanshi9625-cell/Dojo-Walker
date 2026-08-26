import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'live_walk_complete_slider.dart';

class LiveWalkBottomSheet extends StatelessWidget {
  const LiveWalkBottomSheet({
    super.key,
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    required this.ownerPhone,
    required this.sessionData,
    required this.ending,
    required this.onEndWalk,
  });

  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  final Map<String, dynamic> sessionData;

  final bool ending;
  final VoidCallback onEndWalk;

  @override
  Widget build(BuildContext context) {
    final String status =
        sessionData['status']
                ?.toString()
                .trim()
                .toLowerCase() ??
            '';

    final bool completed =
        status == 'completed' ||
        status == 'ended';

    if (completed) {
      return _CompletedBottomSheet(
        dogName: dogName,
        sessionData: sessionData,
      );
    }

    return _RunningBottomSheet(
      ownerName: ownerName,
      dogName: dogName,
      dogBreed: dogBreed,
      ownerPhone: ownerPhone,
      sessionData: sessionData,
      ending: ending,
      onEndWalk: onEndWalk,
    );
  }
}

// ============================================================
// RUNNING BOTTOM SHEET
// ============================================================

class _RunningBottomSheet extends StatelessWidget {
  const _RunningBottomSheet({
    required this.ownerName,
    required this.dogName,
    required this.dogBreed,
    required this.ownerPhone,
    required this.sessionData,
    required this.ending,
    required this.onEndWalk,
  });

  final String ownerName;
  final String dogName;
  final String dogBreed;
  final String? ownerPhone;

  final Map<String, dynamic> sessionData;

  final bool ending;
  final VoidCallback onEndWalk;

  @override
  Widget build(BuildContext context) {
    final double distance =
        _readDouble(
              sessionData['distanceKm'],
            ) ??
            0.0;

    final int steps =
        _readInt(
              sessionData['steps'],
            ) ??
            0;

    final String duration =
        _readDuration(
      sessionData,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        18,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================================================
            // HANDLE
            // ==================================================

            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 14),

            // ==================================================
            // DOG
            // ==================================================

            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color:
                        AppColors.primary.withValues(
                      alpha: .10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: AppColors.primary,
                    size: 25,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        dogName.isEmpty
                            ? 'Dog'
                            : dogName,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color:
                              AppColors.secondary,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),

                      const SizedBox(height: 3),

                      Text(
                        dogBreed.isEmpty
                            ? 'Live Walk'
                            : dogBreed,
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // LIVE BADGE
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        AppColors.success.withValues(
                      alpha: .10,
                    ),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color:
                            AppColors.success,
                        size: 8,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color:
                              AppColors.success,
                          fontSize: 9,
                          fontWeight:
                              FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // STATS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon:
                        Icons.route_rounded,
                    value:
                        '${distance.toStringAsFixed(2)} km',
                    label: 'Distance',
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: _StatCard(
                    icon:
                        Icons.timer_rounded,
                    value: duration,
                    label: 'Duration',
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: _StatCard(
                    icon:
                        Icons.directions_walk_rounded,
                    value: '$steps',
                    label: 'Steps',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ==================================================
            // COMPLETE SLIDER
            // ==================================================

            LiveWalkCompleteSlider(
              enabled: !ending,
              onCompleted: onEndWalk,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// COMPLETED BOTTOM SHEET
// ============================================================

class _CompletedBottomSheet
    extends StatefulWidget {
  const _CompletedBottomSheet({
    required this.dogName,
    required this.sessionData,
  });

  final String dogName;
  final Map<String, dynamic> sessionData;

  @override
  State<_CompletedBottomSheet> createState() =>
      _CompletedBottomSheetState();
}

class _CompletedBottomSheetState
    extends State<_CompletedBottomSheet> {
  int _rating = 0;

  @override
  Widget build(BuildContext context) {
    final double distance =
        _readDouble(
              widget.sessionData[
                  'distanceKm'],
            ) ??
            0.0;

    final int steps =
        _readInt(
              widget.sessionData['steps'],
            ) ??
            0;

    final String duration =
        _readDuration(
      widget.sessionData,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        20,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 18,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ==================================================
            // HANDLE
            // ==================================================

            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius:
                    BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // SUCCESS ICON
            // ==================================================

            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color:
                    AppColors.success.withValues(
                  alpha: .10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColors.success,
                size: 58,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Walk Completed',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              '${widget.dogName}\'s walk is complete.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 15),

            // ==================================================
            // STATS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    icon:
                        Icons.route_rounded,
                    value:
                        '${distance.toStringAsFixed(2)} km',
                    label: 'Distance',
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: _StatCard(
                    icon:
                        Icons.timer_rounded,
                    value: duration,
                    label: 'Duration',
                  ),
                ),

                const SizedBox(width: 9),

                Expanded(
                  child: _StatCard(
                    icon:
                        Icons.directions_walk_rounded,
                    value: '$steps',
                    label: 'Steps',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 17),

            // ==================================================
            // REVIEW
            // ==================================================

            const Text(
              'How was the walk?',
              style: TextStyle(
                color: AppColors.secondary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 7),

            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center,
              children: List.generate(
                5,
                (int index) {
                  final int star =
                      index + 1;

                  return IconButton(
                    onPressed: () {
                      setState(() {
                        _rating = star;
                      });
                    },
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 2,
                    ),
                    constraints:
                        const BoxConstraints(
                      minWidth: 38,
                      minHeight: 38,
                    ),
                    icon: Icon(
                      star <= _rating
                          ? Icons.star_rounded
                          : Icons
                              .star_border_rounded,
                      color:
                          star <= _rating
                              ? AppColors.primary
                              : Colors.grey,
                      size: 30,
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 10),

            // ==================================================
            // HOME
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(
                    context,
                  ).pop(true);
                },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor:
                      Colors.white,
                  elevation: 0,
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Back to Walker Home',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
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

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 18,
          ),

          const SizedBox(height: 4),

          Text(
            value,
            maxLines: 1,
            overflow:
                TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// DOUBLE
// ============================================================

double? _readDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value.toString().trim(),
  );
}

// ============================================================
// INT
// ============================================================

int? _readInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString().trim(),
  );
}

// ============================================================
// DURATION
// ============================================================

String _readDuration(
  Map<String, dynamic> data,
) {
  final dynamic minutesValue =
      data['durationMinutes'];

  if (minutesValue is num) {
    final int minutes =
        minutesValue.toInt();

    if (minutes < 60) {
      return '${minutes}m';
    }

    final int hours = minutes ~/ 60;
    final int remaining =
        minutes % 60;

    return remaining == 0
        ? '${hours}h'
        : '${hours}h ${remaining}m';
  }

  final dynamic duration =
      data['duration'];

  if (duration != null) {
    return duration.toString();
  }

  return '0m';
}
