import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../my_walks/models/past_walk_model.dart';

class WalkerHomeService {
  WalkerHomeService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore =
            firestore ?? FirebaseFirestore.instance,
        _auth =
            auth ?? FirebaseAuth.instance;

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
            final DateTime? walkDate =
                _getWalkDate(walk);

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
            final DateTime? walkDate =
                _getWalkDate(walk);

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
  //
  // Primary:
  // distanceKm
  //
  // Fallback:
  // routeDistanceKm
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
  //
  // Primary:
  // durationMinutes
  //
  // Fallback:
  // routeDurationMinutes
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
        final DateTime? aDate =
            _getWalkDate(a);

        final DateTime? bDate =
            _getWalkDate(b);

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
