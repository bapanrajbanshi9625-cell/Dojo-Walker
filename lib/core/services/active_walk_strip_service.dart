import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActiveWalkStripState {
  const ActiveWalkStripState({
    required this.show,
    required this.isLive,
    required this.walkId,
  });

  final bool show;
  final bool isLive;
  final String walkId;

  const ActiveWalkStripState.hidden()
      : show = false,
        isLive = false,
        walkId = '';
}

class ActiveWalkStripService {
  ActiveWalkStripService._();

  static final ActiveWalkStripService instance =
      ActiveWalkStripService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Stream<ActiveWalkStripState> watch() {
    final String uid =
        _auth.currentUser?.uid.trim() ?? '';

    if (uid.isEmpty) {
      return Stream<ActiveWalkStripState>.value(
        const ActiveWalkStripState.hidden(),
      );
    }

    final Stream<QuerySnapshot<Map<String, dynamic>>>
        activeWalks = _firestore
            .collection('active_walks')
            .where(
              'walkerUid',
              isEqualTo: uid,
            )
            .snapshots();

    final Stream<QuerySnapshot<Map<String, dynamic>>>
        liveSessions = _firestore
            .collection('liveWalkSessions')
            .where(
              'walkerUid',
              isEqualTo: uid,
            )
            .snapshots();

    return _combineStreams(
      activeWalks,
      liveSessions,
    );
  }

  Stream<ActiveWalkStripState> _combineStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>>
        activeWalks,
    Stream<QuerySnapshot<Map<String, dynamic>>>
        liveSessions,
  ) async* {
    QuerySnapshot<Map<String, dynamic>>?
        latestActive;

    QuerySnapshot<Map<String, dynamic>>?
        latestLive;

    final StreamController<
            ActiveWalkStripState>
        controller =
        StreamController<ActiveWalkStripState>();

    late StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>
        activeSubscription;

    late StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>
        liveSubscription;

    void emit() {
      final ActiveWalkStripState state =
          _resolve(
        activeSnapshot: latestActive,
        liveSnapshot: latestLive,
      );

      if (!controller.isClosed) {
        controller.add(state);
      }
    }

    activeSubscription = activeWalks.listen(
      (QuerySnapshot<Map<String, dynamic>>
          snapshot) {
        latestActive = snapshot;
        emit();
      },
      onError: controller.addError,
    );

    liveSubscription = liveSessions.listen(
      (QuerySnapshot<Map<String, dynamic>>
          snapshot) {
        latestLive = snapshot;
        emit();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await activeSubscription.cancel();
      await liveSubscription.cancel();
    };

    yield* controller.stream;
  }

  ActiveWalkStripState _resolve({
    QuerySnapshot<Map<String, dynamic>>?
        activeSnapshot,
    QuerySnapshot<Map<String, dynamic>>?
        liveSnapshot,
  }) {
    // ==========================================================
    // LIVE SESSION HAS HIGHEST PRIORITY
    // ==========================================================

    if (liveSnapshot != null) {
      for (final QueryDocumentSnapshot<
              Map<String, dynamic>>
          doc in liveSnapshot.docs) {
        final Map<String, dynamic> data =
            doc.data();

        final String status =
            _status(data['status']);

        if (_isEnded(status)) {
          continue;
        }

        if (!_isLiveStatus(status)) {
          continue;
        }

        final String walkId =
            _string(data['walkId']);

        return ActiveWalkStripState(
          show: true,
          isLive: true,
          walkId: walkId.isNotEmpty
              ? walkId
              : doc.id,
        );
      }
    }

    // ==========================================================
    // ACTIVE WALK
    // ==========================================================

    if (activeSnapshot != null) {
      for (final QueryDocumentSnapshot<
              Map<String, dynamic>>
          doc in activeSnapshot.docs) {
        final Map<String, dynamic> data =
            doc.data();

        final String status =
            _status(data['status']);

        if (_isEnded(status)) {
          continue;
        }

        if (!_isActiveStatus(status)) {
          continue;
        }

        final String walkId =
            _string(data['walkId']);

        return ActiveWalkStripState(
          show: true,
          isLive: false,
          walkId: walkId.isNotEmpty
              ? walkId
              : doc.id,
        );
      }
    }

    return const ActiveWalkStripState.hidden();
  }

  bool _isActiveStatus(String status) {
    return status == 'ACCEPTED' ||
        status == 'ACTIVE' ||
        status == 'ON_THE_WAY';
  }

  bool _isLiveStatus(String status) {
    return status == 'ACTIVE' ||
        status == 'STARTED' ||
        status == 'LIVE';
  }

  bool _isEnded(String status) {
    return status == 'COMPLETED' ||
        status == 'ENDED' ||
        status == 'CANCELLED';
  }

  String _status(dynamic value) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim()
        .toUpperCase();
  }

  String _string(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }
}
