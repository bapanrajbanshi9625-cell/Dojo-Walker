import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';

class LiveWalkBottomSheet extends StatelessWidget {
  const LiveWalkBottomSheet({
    super.key,
    required this.dogName,
    required this.ownerPhone,
    required this.sessionData,
    required this.ending,
    required this.onEndWalk,
  });

  final String dogName;
  final String? ownerPhone;
  final Map<String, dynamic> sessionData;
  final bool ending;
  final VoidCallback onEndWalk;

  @override
  Widget build(BuildContext context) {
    final double distance =
        _readDouble(sessionData['distanceKm']) ?? 0.0;

    final int steps =
        _readInt(sessionData['steps']) ?? 0;

    final String duration =
        _readDuration(sessionData);

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12,
        ),
        padding: const EdgeInsets.fromLTRB(
          16,
          14,
          16,
          16,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.border,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, -5),
            ),
          ],
        ),
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
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // DOG + LIVE
            // ==================================================

            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: .10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.pets_rounded,
                    color: AppColors.primary,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 11),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LIVE WALK',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .7,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dogName.trim().isEmpty
                            ? 'Dog Walk'
                            : dogName.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),

                // LIVE
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(
                      alpha: .10,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color: AppColors.success,
                        size: 8,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ==================================================
            // STATS
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _Stat(
                    icon: Icons.route_rounded,
                    value:
                        '${distance.toStringAsFixed(2)} km',
                    label: 'DISTANCE',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    icon: Icons.timer_rounded,
                    value: duration,
                    label: 'TIME',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Stat(
                    icon:
                        Icons.directions_walk_rounded,
                    value: '$steps',
                    label: 'STEPS',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ==================================================
            // CALL + CHAT
            // ==================================================

            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.call_rounded,
                    label: 'Call Owner',
                    color: AppColors.success,
                    onPressed:
                        ending ? null : _callOwner,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: _ActionButton(
                    icon: Icons.chat_bubble_rounded,
                    label: 'Chat',
                    color: AppColors.primary,
                    onPressed: ending
                        ? null
                        : () {
                            // Chat screen अभी बनाया नहीं गया है.
                            // बाद में यहाँ navigation जोड़ना है.
                          },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ==================================================
            // COMPLETE WALK
            // ==================================================

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed:
                    ending ? null : onEndWalk,
                icon: const Icon(
                  Icons.check_circle_rounded,
                  size: 23,
                ),
                label: Text(
                  ending
                      ? 'COMPLETING WALK...'
                      : 'COMPLETE WALK',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(
                    alpha: .55,
                  ),
                  disabledForegroundColor:
                      Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // CALL OWNER
  // ==========================================================

  Future<void> _callOwner() async {
    final String phone =
        ownerPhone?.trim() ?? '';

    if (phone.isEmpty) {
      return;
    }

    final Uri uri = Uri(
      scheme: 'tel',
      path: phone,
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      // Call failure को यहाँ silently ignore किया गया है.
    }
  }

  // ==========================================================
  // DOUBLE
  // ==========================================================

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

  // ==========================================================
  // INT
  // ==========================================================

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

  // ==========================================================
  // DURATION
  // ==========================================================

  String _readDuration(
    Map<String, dynamic> data,
  ) {
    final dynamic value =
        data['durationMinutes'] ??
            data['duration'];

    if (value is num) {
      final int minutes = value.toInt();

      if (minutes < 60) {
        return '${minutes}m';
      }

      final int hours = minutes ~/ 60;
      final int remaining = minutes % 60;

      return '${hours}h ${remaining}m';
    }

    if (value != null) {
      return value.toString().trim();
    }

    return '0m';
  }
}

// ============================================================
// STAT
// ============================================================

class _Stat extends StatelessWidget {
  const _Stat({
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
      padding: const EdgeInsets.symmetric(
        vertical: 11,
        horizontal: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
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
            size: 21,
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTION BUTTON
// ============================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(
          icon,
          size: 20,
        ),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: color.withValues(
              alpha: .45,
            ),
          ),
          backgroundColor: color.withValues(
            alpha: .06,
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
