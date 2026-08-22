// File location:
// lib/features/live_walk/widgets/live_walk_activity_card.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class LiveWalkActivityCard extends StatelessWidget {
  final String sessionId;

  const LiveWalkActivityCard({
    super.key,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('liveWalkSessions')
          .doc(sessionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return _buildLoadingCard();
        }

        if (!snapshot.hasData ||
            !snapshot.data!.exists) {
          return _buildEmptyCard();
        }

        final Map<String, dynamic> data =
            snapshot.data!.data() ??
                <String, dynamic>{};

        // ========================================================
        // DISTANCE
        // ========================================================

        final double distanceKm =
            _readDouble(
          data['distanceKm'],
        );

        // ========================================================
        // ELAPSED TIME
        // ========================================================

        final int elapsedSeconds =
            _readInt(
          data['elapsedSeconds'],
        );

        // ========================================================
        // STEPS
        // ========================================================
        //
        // अगर future में steps Firebase में save होंगे तो
        // automatically दिखेंगे.
        //

        final int steps =
            _readInt(
          data['steps'],
        );

        return _buildCard(
          distanceKm: distanceKm,
          elapsedSeconds: elapsedSeconds,
          steps: steps,
        );
      },
    );
  }

  // ==============================================================
  // MAIN CARD
  // ==============================================================

  Widget _buildCard({
    required double distanceKm,
    required int elapsedSeconds,
    required int steps,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withAlpha(80),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ======================================================
          // HEADER
          // ======================================================

          const Row(
            children: [
              Icon(
                Icons.directions_walk,
                color: AppColors.primary,
                size: 28,
              ),
              SizedBox(width: 10),
              Text(
                'Live Walk Progress',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          const Divider(
            height: 30,
            thickness: 1,
            color: Colors.black12,
          ),

          // ======================================================
          // DURATION
          // ======================================================

          const Text(
            'Duration',
            style: TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 5),

          _LiveDurationText(
            initialSeconds: elapsedSeconds,
          ),

          const SizedBox(height: 20),

          // ======================================================
          // STATS
          // ======================================================

          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: [
              _buildStat(
                distanceKm.toStringAsFixed(1),
                'Distance (km)',
              ),

              Container(
                height: 30,
                width: 1,
                color: AppColors.primary.withAlpha(50),
              ),

              _buildStat(
                _formatSteps(steps),
                'Steps',
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // STAT
  // ==============================================================

  Widget _buildStat(
    String value,
    String label,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  // ==============================================================
  // LOADING
  // ==============================================================

  Widget _buildLoadingCard() {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }

  // ==============================================================
  // EMPTY
  // ==============================================================

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: Text(
          'Live walk data unavailable',
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ==============================================================
  // READ DOUBLE
  // ==============================================================

  double _readDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0.0;
  }

  // ==============================================================
  // READ INT
  // ==============================================================

  int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  // ==============================================================
  // FORMAT STEPS
  // ==============================================================

  String _formatSteps(int steps) {
    if (steps < 1000) {
      return steps.toString();
    }

    if (steps < 1000000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }

    return '${(steps / 1000000).toStringAsFixed(1)}M';
  }
}

// ================================================================
// LIVE DURATION
// ================================================================
//
// Firebase में saved elapsedSeconds से शुरू होता है और
// ACTIVE walk के दौरान local UI हर second update होता है.
//

class _LiveDurationText extends StatefulWidget {
  final int initialSeconds;

  const _LiveDurationText({
    required this.initialSeconds,
  });

  @override
  State<_LiveDurationText> createState() =>
      _LiveDurationTextState();
}

class _LiveDurationTextState
    extends State<_LiveDurationText> {
  Timer? _timer;

  late int _seconds;

  @override
  void initState() {
    super.initState();

    _seconds = widget.initialSeconds;

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) {
          return;
        }

        setState(() {
          _seconds++;
        });
      },
    );
  }

  @override
  void didUpdateWidget(
    covariant _LiveDurationText oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.initialSeconds !=
        widget.initialSeconds) {
      _seconds = widget.initialSeconds;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _formatDuration(_seconds),
      style: const TextStyle(
        fontSize: 44,
        fontWeight: FontWeight.w900,
        color: AppColors.primary,
        letterSpacing: -1,
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final int safeSeconds =
        totalSeconds < 0 ? 0 : totalSeconds;

    final int hours =
        safeSeconds ~/ 3600;

    final int minutes =
        (safeSeconds % 3600) ~/ 60;

    final int seconds =
        safeSeconds % 60;

    final String hh =
        hours.toString().padLeft(2, '0');

    final String mm =
        minutes.toString().padLeft(2, '0');

    final String ss =
        seconds.toString().padLeft(2, '0');

    return '$hh:$mm:$ss';
  }
}
