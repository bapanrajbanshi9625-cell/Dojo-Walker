// File:
// lib/features/walker_home/widgets/activity_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ActivityCard extends StatelessWidget {
  const ActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const _ActivityCardView(
        walks: 0,
        distanceKm: 0,
        durationMinutes: 0,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _todayWalksStream(user.uid),
      builder: (
        BuildContext context,
        AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot,
      ) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const _ActivityLoadingCard();
        }

        if (snapshot.hasError) {
          return const _ActivityCardView(
            walks: 0,
            distanceKm: 0,
            durationMinutes: 0,
          );
        }

        final List<QueryDocumentSnapshot<Map<String, dynamic>>>
            documents =
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        int walks = 0;
        double totalDistanceKm = 0;
        int totalDurationMinutes = 0;

        for (final QueryDocumentSnapshot<Map<String, dynamic>>
            document in documents) {
          final Map<String, dynamic> data =
              document.data();

          final String status =
              (data['status']?.toString() ?? '')
                  .trim()
                  .toLowerCase();

          // Cancelled walks को Activity में count नहीं करेंगे.
          if (status == 'cancelled' ||
              status == 'owner_cancelled' ||
              status == 'walker_cancelled') {
            continue;
          }

          walks++;

          totalDistanceKm += _readDouble(
            data['distanceKm'] ??
                data['walkDistanceKm'] ??
                data['distance'],
          );

          totalDurationMinutes += _readDurationMinutes(
            data['durationMinutes'] ??
                data['walkDurationMinutes'] ??
                data['duration'],
          );
        }

        return _ActivityCardView(
          walks: walks,
          distanceKm: totalDistanceKm,
          durationMinutes: totalDurationMinutes,
        );
      },
    );
  }

  // ============================================================
  // TODAY'S WALK HISTORY
  // ============================================================

  Stream<QuerySnapshot<Map<String, dynamic>>> _todayWalksStream(
    String uid,
  ) {
    final DateTime now = DateTime.now();

    final DateTime startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final DateTime endOfDay = startOfDay.add(
      const Duration(days: 1),
    );

    return FirebaseFirestore.instance
        .collection('walk_history')
        .where(
          'walkerId',
          isEqualTo: uid,
        )
        .where(
          'createdAt',
          isGreaterThanOrEqualTo:
              Timestamp.fromDate(startOfDay),
        )
        .where(
          'createdAt',
          isLessThan:
              Timestamp.fromDate(endOfDay),
        )
        .snapshots();
  }

  // ============================================================
  // SAFE DOUBLE
  // ============================================================

  static double _readDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString().trim(),
        ) ??
        0;
  }

  // ============================================================
  // SAFE DURATION
  // ============================================================

  static int _readDurationMinutes(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toInt();
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return 0;
    }

    // "45 min"
    final RegExp minuteRegex =
        RegExp(r'(\d+(?:\.\d+)?)\s*min');

    final RegExpMatch? minuteMatch =
        minuteRegex.firstMatch(
      text.toLowerCase(),
    );

    if (minuteMatch != null) {
      return double.tryParse(
            minuteMatch.group(1) ?? '0',
          )?.round() ??
          0;
    }

    // "1.5 hours"
    final RegExp hourRegex =
        RegExp(r'(\d+(?:\.\d+)?)\s*(?:hour|hours|hr|hrs)');

    final RegExpMatch? hourMatch =
        hourRegex.firstMatch(
      text.toLowerCase(),
    );

    if (hourMatch != null) {
      final double hours =
          double.tryParse(
                hourMatch.group(1) ?? '0',
              ) ??
              0;

      return (hours * 60).round();
    }

    return int.tryParse(text) ?? 0;
  }
}

// ================================================================
// ACTIVITY CARD UI
// ================================================================

class _ActivityCardView extends StatelessWidget {
  const _ActivityCardView({
    required this.walks,
    required this.distanceKm,
    required this.durationMinutes,
  });

  final int walks;
  final double distanceKm;
  final int durationMinutes;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Activity",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceAround,
            children: [
              _buildActivityItem(
                icon: Icons.directions_walk,
                title: "Walks",
                value: walks.toString(),
              ),
              _buildVerticalDivider(),
              _buildActivityItem(
                icon: Icons.map,
                title: "Distance",
                value:
                    '${distanceKm.toStringAsFixed(1)} km',
              ),
              _buildVerticalDivider(),
              _buildActivityItem(
                icon: Icons.access_time,
                title: "Duration",
                value: '$durationMinutes min',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF6600),
          size: 22,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey[200],
    );
  }
}

// ================================================================
// LOADING
// ================================================================

class _ActivityLoadingCard extends StatelessWidget {
  const _ActivityLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 145,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
