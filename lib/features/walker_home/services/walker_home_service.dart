import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../my_walks/models/past_walk_model.dart';

class WalkerHomeSummary {
  final int totalWalks;
  final double distanceKm;
  final double durationMinutes;
  final String performance;

  const WalkerHomeSummary({
    this.totalWalks = 0,
    this.distanceKm = 0,
    this.durationMinutes = 0,
    this.performance = 'No data',
  });
}

class WalkerHomeService {
  WalkerHomeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // CURRENT WALKER UID
  // ============================================================

  String? get currentWalkerId {
    return _auth.currentUser?.uid;
  }

  // ============================================================
  // ALL COMPLETED PAST WALKS
  //
  // Collection:
  // walk_history
  //
  // Primary walker field:
  // walkerUid
  // ============================================================

  Stream<List<PastWalkModel>> watchPastWalks() {
    final User? user = _auth.currentUser;

    if (user == null) {
      return Stream.value(
        const <PastWalkModel>[],
      );
    }

    return _firestore
        .collection('walk_history')
        .where(
          'walkerUid',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<PastWalkModel> walks = snapshot.docs
            .map(
              PastWalkModel.fromDocument,
            )
            .where(
              (PastWalkModel walk) => walk.isCompleted,
            )
            .toList();

        _sortWalks(walks);

        return walks;
      },
    );
  }

  // ============================================================
  // TODAY'S SUMMARY
  //
  // Uses today's completed walks from walk_history.
  // ============================================================

  Stream<WalkerHomeSummary> watchTodaySummary() {
    return watchPastWalks().map(
      (List<PastWalkModel> walks) {
        final DateTime now = DateTime.now();

        final DateTime startOfDay = DateTime(
          now.year,
          now.month,
          now.day,
        );

        final DateTime endOfDay = startOfDay.add(
          const Duration(days: 1),
        );

        final List<PastWalkModel> todayWalks =
            walks.where(
          (PastWalkModel walk) {
            final DateTime? walkDate = _getWalkDate(walk);

            if (walkDate == null) {
              return false;
            }

            return !walkDate.isBefore(startOfDay) &&
                walkDate.isBefore(endOfDay);
          },
        ).toList();

        final int total = totalWalks(todayWalks);
        final double distance = totalDistanceKm(todayWalks);
        final double duration =
            totalDurationMinutes(todayWalks);

        return WalkerHomeSummary(
          totalWalks: total,
          distanceKm: distance,
          durationMinutes: duration,
          performance: _performanceText(
            todayWalks,
          ),
        );
      },
    );
  }

  // ============================================================
  // PERFORMANCE
  // ============================================================

  String _performanceText(
    List<PastWalkModel> walks,
  ) {
    if (walks.isEmpty) {
      return 'No data';
    }

    final double rating = averageRating(walks);

    if (rating >= 4.5) {
      return 'Excellent';
    }

    if (rating >= 4.0) {
      return 'Great';
    }

    if (rating >= 3.0) {
      return 'Good';
    }

    if (rating > 0) {
      return 'Average';
    }

    if (walks.length >= 3) {
      return 'Excellent';
    }

    if (walks.length >= 2) {
      return 'Good';
    }

    return 'Active';
  }

  // ============================================================
  // WALKS FOR SELECTED DATE
  // ============================================================

  Stream<List<PastWalkModel>> watchWalksForDate(
    DateTime date,
  ) {
    return watchPastWalks().map(
      (List<PastWalkModel> walks) {
        final DateTime selectedDate = DateTime(
          date.year,
          date.month,
          date.day,
        );

        return walks.where(
          (PastWalkModel walk) {
            final DateTime? walkDate = _getWalkDate(walk);

            if (walkDate == null) {
              return false;
            }

            final DateTime day = DateTime(
              walkDate.year,
              walkDate.month,
              walkDate.day,
            );

            return day == selectedDate;
          },
        ).toList();
      },
    );
  }

  // ============================================================
  // WALKS FOR SELECTED WEEK
  //
  // Monday → Sunday
  // ============================================================

  Stream<List<PastWalkModel>> watchWalksForWeek(
    DateTime date,
  ) {
    final DateTime start = _startOfWeek(date);

    final DateTime end = start.add(
      const Duration(days: 7),
    );

    return watchPastWalks().map(
      (List<PastWalkModel> walks) {
        return walks.where(
          (PastWalkModel walk) {
            final DateTime? walkDate = _getWalkDate(walk);

            if (walkDate == null) {
              return false;
            }

            return !walkDate.isBefore(start) &&
                walkDate.isBefore(end);
          },
        ).toList();
      },
    );
  }

  // ============================================================
  // GET WALK ACTIVITY DATE
  //
  // Priority:
  // completedAt
  // startedAt
  // createdAt
  // ============================================================

  DateTime? _getWalkDate(
    PastWalkModel walk,
  ) {
    return walk.completedAt ??
        walk.startedAt ??
        walk.createdAt;
  }

  // ============================================================
  // TOTAL WALKS
  // ============================================================

  int totalWalks(
    List<PastWalkModel> walks,
  ) {
    return walks.length;
  }

  // ============================================================
  // TOTAL DISTANCE
  // ============================================================

  double totalDistanceKm(
    List<PastWalkModel> walks,
  ) {
    double total = 0;

    for (final PastWalkModel walk in walks) {
      if (walk.distanceKm > 0) {
        total += walk.distanceKm;
      } else if (walk.routeDistanceKm > 0) {
        total += walk.routeDistanceKm;
      }
    }

    return total;
  }

  // ============================================================
  // TOTAL DURATION
  // ============================================================

  double totalDurationMinutes(
    List<PastWalkModel> walks,
  ) {
    double total = 0;

    for (final PastWalkModel walk in walks) {
      if (walk.durationMinutes > 0) {
        total += walk.durationMinutes;
      } else if (walk.routeDurationMinutes > 0) {
        total += walk.routeDurationMinutes;
      }
    }

    return total;
  }

  // ============================================================
  // AVERAGE RATING
  // ============================================================

  double averageRating(
    List<PastWalkModel> walks,
  ) {
    final List<PastWalkModel> ratedWalks =
        walks.where(
      (PastWalkModel walk) {
        return walk.rating > 0;
      },
    ).toList();

    if (ratedWalks.isEmpty) {
      return 0;
    }

    int totalRating = 0;

    for (final PastWalkModel walk in ratedWalks) {
      totalRating += walk.rating;
    }

    return totalRating / ratedWalks.length;
  }

  // ============================================================
  // TOTAL PEE COUNT
  // ============================================================

  int totalPeeCount(
    List<PastWalkModel> walks,
  ) {
    int total = 0;

    for (final PastWalkModel walk in walks) {
      total += walk.peeCount;
    }

    return total;
  }

  // ============================================================
  // TOTAL POOP COUNT
  // ============================================================

  int totalPoopCount(
    List<PastWalkModel> walks,
  ) {
    int total = 0;

    for (final PastWalkModel walk in walks) {
      total += walk.poopCount;
    }

    return total;
  }

  // ============================================================
  // RATED WALKS COUNT
  // ============================================================

  int ratedWalksCount(
    List<PastWalkModel> walks,
  ) {
    return walks.where(
      (PastWalkModel walk) {
        return walk.rating > 0;
      },
    ).length;
  }

  // ============================================================
  // START OF WEEK
  //
  // Monday = first day
  // Sunday = last day
  // ============================================================

  DateTime _startOfWeek(
    DateTime date,
  ) {
    final DateTime day = DateTime(
      date.year,
      date.month,
      date.day,
    );

    return day.subtract(
      Duration(
        days: day.weekday - 1,
      ),
    );
  }

  // ============================================================
  // SORT WALKS
  //
  // Newest completed walk first
  // ============================================================

  void _sortWalks(
    List<PastWalkModel> walks,
  ) {
    walks.sort(
      (
        PastWalkModel a,
        PastWalkModel b,
      ) {
        final DateTime? aDate = _getWalkDate(a);
        final DateTime? bDate = _getWalkDate(b);

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
      },
    );
  }
}
