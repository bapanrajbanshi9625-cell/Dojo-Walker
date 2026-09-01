import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/past_walk_model.dart';

class WalkerHomeService {
  WalkerHomeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // PAST WALKS
  // ============================================================

  Stream<List<PastWalkModel>> watchPastWalks() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(const <PastWalkModel>[]);
    }

    return _firestore
        .collection('walk_history')
        .where(
          'walkerId',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map((snapshot) {
      final walks = snapshot.docs
          .map(PastWalkModel.fromDocument)
          .where((walk) {
        final status = walk.status.toLowerCase();

        return status == 'completed' ||
            status == 'complete' ||
            status == 'done';
      }).toList();

      walks.sort((a, b) {
        final aDate = a.completedAt;
        final bDate = b.completedAt;

        if (aDate == null && bDate == null) {
          return 0;
        }

        if (aDate == null) {
          return 1;
        }

        if (bDate == null) {
          return -1;
        }

        return bDate.compareTo(aDate);
      });

      return walks;
    });
  }

  // ============================================================
  // TODAY SUMMARY
  // ============================================================

  Stream<WalkerHomeSummary> watchTodaySummary() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        const WalkerHomeSummary(),
      );
    }

    return _firestore
        .collection('walk_history')
        .where(
          'walkerId',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();

      final todayWalks = snapshot.docs.where((doc) {
        final data = doc.data();

        final status =
            (data['status'] ?? '').toString().toLowerCase();

        final completedAt = _readDate(
          data['completedAt'] ??
              data['completed_at'] ??
              data['completedTime'] ??
              data['endedAt'],
        );

        final isCompleted =
            status == 'completed' ||
            status == 'complete' ||
            status == 'done';

        if (!isCompleted || completedAt == null) {
          return false;
        }

        return completedAt.year == now.year &&
            completedAt.month == now.month &&
            completedAt.day == now.day;
      }).toList();

      double totalDistance = 0;
      int totalDuration = 0;

      for (final doc in todayWalks) {
        final data = doc.data();

        totalDistance += _readDouble(
          data['distanceKm'] ??
              data['distance'] ??
              data['totalDistance'],
        );

        totalDuration += _readInt(
          data['durationMinutes'] ??
              data['duration'] ??
              data['walkDuration'],
        );
      }

      return WalkerHomeSummary(
        totalWalks: todayWalks.length,
        distanceKm: totalDistance,
        durationMinutes: totalDuration,
        performance: _calculatePerformance(
          totalWalks: todayWalks.length,
          distanceKm: totalDistance,
          durationMinutes: totalDuration,
        ),
      );
    });
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================

  String _calculatePerformance({
    required int totalWalks,
    required double distanceKm,
    required int durationMinutes,
  }) {
    if (totalWalks == 0) {
      return '—';
    }

    if (totalWalks >= 4 ||
        distanceKm >= 8 ||
        durationMinutes >= 120) {
      return 'Excellent';
    }

    if (totalWalks >= 2 ||
        distanceKm >= 4 ||
        durationMinutes >= 60) {
      return 'Good';
    }

    return 'Active';
  }

  // ============================================================
  // DATE PARSER
  // ============================================================

  DateTime? _readDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  // ============================================================
  // DOUBLE PARSER
  // ============================================================

  double _readDouble(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value.toString(),
        ) ??
        0;
  }

  // ============================================================
  // INT PARSER
  // ============================================================

  int _readInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is num) {
      return value.round();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }
}

// ================================================================
// WALKER HOME SUMMARY MODEL
// ================================================================

class WalkerHomeSummary {
  final int totalWalks;
  final double distanceKm;
  final int durationMinutes;
  final String performance;

  const WalkerHomeSummary({
    this.totalWalks = 0,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.performance = '—',
  });
}
