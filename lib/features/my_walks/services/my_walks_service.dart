import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/past_walk_model.dart';

class MyWalksService {
  MyWalksService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth =
            auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ============================================================
  // CURRENT WALKER
  // ============================================================

  String? get currentWalkerId {
    return _auth.currentUser?.uid;
  }

  // ============================================================
  // WATCH ALL COMPLETED WALKS
  //
  // Collection:
  // walk_history
  //
  // Primary walker field:
  // walkerId
  //
  // NOTE:
  // We use walkerId consistently here.
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
          'walkerId',
          isEqualTo: user.uid,
        )
        .snapshots()
        .map(
      (
        QuerySnapshot<Map<String, dynamic>> snapshot,
      ) {
        final List<PastWalkModel> walks =
            snapshot.docs
                .map(
                  PastWalkModel.fromDocument,
                )
                .where(
                  (PastWalkModel walk) =>
                      walk.isCompleted,
                )
                .toList();

        _sortWalks(walks);

        return walks;
      },
    );
  }

  // ============================================================
  // WATCH WALKS FOR DATE
  // ============================================================

  Stream<List<PastWalkModel>> watchWalksForDate(
    DateTime date,
  ) {
    return watchPastWalks().map(
      (
        List<PastWalkModel> walks,
      ) {
        return walks
            .where(
              (PastWalkModel walk) {
                final DateTime? activityDate =
                    walk.activityDate;

                if (activityDate == null) {
                  return false;
                }

                return activityDate.year ==
                        date.year &&
                    activityDate.month ==
                        date.month &&
                    activityDate.day ==
                        date.day;
              },
            )
            .toList();
      },
    );
  }

  // ============================================================
  // WATCH WALKS FOR WEEK
  //
  // Monday → Sunday
  // ============================================================

  Stream<List<PastWalkModel>> watchWalksForWeek(
    DateTime date,
  ) {
    final DateTime start =
        startOfWeek(date);

    final DateTime end =
        start.add(
      const Duration(days: 7),
    );

    return watchPastWalks().map(
      (
        List<PastWalkModel> walks,
      ) {
        return walks
            .where(
              (PastWalkModel walk) {
                final DateTime? activityDate =
                    walk.activityDate;

                if (activityDate == null) {
                  return false;
                }

                return !activityDate.isBefore(
                      start,
                    ) &&
                    activityDate.isBefore(
                      end,
                    );
              },
            )
            .toList();
      },
    );
  }

  // ============================================================
  // START OF WEEK
  //
  // Monday = first day
  // ============================================================

  DateTime startOfWeek(
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
      total += walk.effectiveDistanceKm;
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
      total +=
          walk.effectiveDurationMinutes;
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
        walks
            .where(
              (PastWalkModel walk) =>
                  walk.rating > 0,
            )
            .toList();

    if (ratedWalks.isEmpty) {
      return 0;
    }

    int totalRating = 0;

    for (final PastWalkModel walk
        in ratedWalks) {
      totalRating += walk.rating;
    }

    return totalRating /
        ratedWalks.length;
  }

  // ============================================================
  // SORT WALKS
  //
  // Newest activity first.
  // ============================================================

  void _sortWalks(
    List<PastWalkModel> walks,
  ) {
    walks.sort(
      (
        PastWalkModel a,
        PastWalkModel b,
      ) {
        final DateTime? aDate =
            a.activityDate;

        final DateTime? bDate =
            b.activityDate;

        if (aDate == null &&
            bDate == null) {
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
