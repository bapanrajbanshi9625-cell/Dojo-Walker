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

  // ============================================================
  // PUBLIC WATCH
  //
  // PHASE 1:
  // walk_request
  //   ACCEPTED
  //      ↓
  //   REACHED
  //
  // PHASE 2:
  // After REACHED, walk_request is no longer used.
  //
  // liveWalkSessions becomes the ONLY source.
  //
  // ACTIVE / STARTED / LIVE / IN_PROGRESS
  //      ↓
  // LIVE STRIP
  //
  // COMPLETED / ENDED / walkEnded / completedAt
  //      ↓
  // HIDE
  // ============================================================

  Stream<ActiveWalkStripState> watch() {
    final User? user = _auth.currentUser;
    final String uid = user?.uid.trim() ?? '';

    if (uid.isEmpty) {
      return Stream<ActiveWalkStripState>.value(
        const ActiveWalkStripState.hidden(),
      );
    }

    final Stream<QuerySnapshot<Map<String, dynamic>>>
        requestStream = _firestore
            .collection('walk_request')
            .where(
              'walkerUid',
              isEqualTo: uid,
            )
            .snapshots();

    final Stream<QuerySnapshot<Map<String, dynamic>>>
        sessionStream = _firestore
            .collection('liveWalkSessions')
            .where(
              'walkerUid',
              isEqualTo: uid,
            )
            .snapshots();

    return _combineStreams(
      requestStream,
      sessionStream,
    );
  }

  // ============================================================
  // COMBINE STREAMS
  // ============================================================

  Stream<ActiveWalkStripState> _combineStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>>
        requestStream,
    Stream<QuerySnapshot<Map<String, dynamic>>>
        sessionStream,
  ) {
    final StreamController<ActiveWalkStripState>
        controller =
        StreamController<ActiveWalkStripState>();

    late StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>
        requestSubscription;

    late StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>
        sessionSubscription;

    QuerySnapshot<Map<String, dynamic>>?
        latestRequests;

    QuerySnapshot<Map<String, dynamic>>?
        latestSessions;

    // ==========================================================
    // IMPORTANT STATE
    //
    // Once REACHED is detected from walk_request,
    // request collection is NEVER used again for this watch.
    // ==========================================================

    bool reachedPhase = false;

    String reachedWalkId = '';

    bool cancelled = false;

    void emit() {
      if (cancelled || controller.isClosed) {
        return;
      }

      final ActiveWalkStripState state =
          _resolve(
        requestSnapshot: latestRequests,
        sessionSnapshot: latestSessions,
        reachedPhase: reachedPhase,
        reachedWalkId: reachedWalkId,
      );

      controller.add(state);
    }

    // ==========================================================
    // REQUEST STREAM
    // ==========================================================

    requestSubscription = requestStream.listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        latestRequests = snapshot;

        // ======================================================
        // BEFORE REACHED:
        // Find ACCEPTED / REACHED request.
        // ======================================================

        if (!reachedPhase) {
          final QueryDocumentSnapshot<
                  Map<String, dynamic>>?
              request =
              _findCurrentRequest(
            snapshot.docs,
          );

          if (request != null) {
            final Map<String, dynamic> data =
                request.data();

            final String status =
                _status(data['status']);

            final String walkId =
                _walkIdFromData(
              data,
              request.id,
            );

            // ==================================================
            // REACHED = SWITCH TO SESSION-ONLY MODE
            // ==================================================

            if (_isReachedStatus(status) &&
                walkId.isNotEmpty) {
              reachedPhase = true;
              reachedWalkId = walkId;
            }
          }
        }

        emit();
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        if (!controller.isClosed) {
          controller.addError(
            error,
            stackTrace,
          );
        }
      },
    );

    // ==========================================================
    // LIVE SESSION STREAM
    // ==========================================================

    sessionSubscription = sessionStream.listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        latestSessions = snapshot;

        // ======================================================
        // IMPORTANT:
        //
        // Even if request stream is stale,
        // completed session MUST hide strip.
        //
        // If a session contains REACHED state, switch to
        // session-only mode as well.
        // ======================================================

        if (!reachedPhase) {
          final QueryDocumentSnapshot<
                  Map<String, dynamic>>?
              session =
              _findLatestRelevantSession(
            snapshot.docs,
          );

          if (session != null) {
            final Map<String, dynamic> data =
                session.data();

            final String status =
                _status(data['status']);

            final String walkId =
                _walkIdFromData(
              data,
              session.id,
            );

            if (_isReachedStatus(status) &&
                walkId.isNotEmpty) {
              reachedPhase = true;
              reachedWalkId = walkId;
            }
          }
        }

        emit();
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        if (!controller.isClosed) {
          controller.addError(
            error,
            stackTrace,
          );
        }
      },
    );

    controller.onCancel = () async {
      cancelled = true;

      await requestSubscription.cancel();
      await sessionSubscription.cancel();
    };

    return controller.stream;
  }

  // ============================================================
  // RESOLVE
  // ============================================================

  ActiveWalkStripState _resolve({
    QuerySnapshot<Map<String, dynamic>>?
        requestSnapshot,
    QuerySnapshot<Map<String, dynamic>>?
        sessionSnapshot,
    required bool reachedPhase,
    required String reachedWalkId,
  }) {
    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        requestDocs =
        requestSnapshot?.docs ??
            const <
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        sessionDocs =
        sessionSnapshot?.docs ??
            const <
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

    // ==========================================================
    // PHASE 2
    //
    // REACHED HAS ALREADY HAPPENED.
    //
    // DO NOT READ walk_request ANYMORE.
    // ONLY liveWalkSessions.
    // ==========================================================

    if (reachedPhase) {
      if (reachedWalkId.trim().isEmpty) {
        return const ActiveWalkStripState.hidden();
      }

      final QueryDocumentSnapshot<
              Map<String, dynamic>>?
          session =
          _findLatestSessionForWalk(
        sessionDocs,
        reachedWalkId,
      );

      if (session == null) {
        // Reached happened, but session has not appeared yet.
        // Do NOT fall back to walk_request.
        return const ActiveWalkStripState.hidden();
      }

      final Map<String, dynamic> data =
          session.data();

      // ========================================================
      // COMPLETED = ALWAYS HIDE
      // ========================================================

      if (_isSessionCompleted(data)) {
        return const ActiveWalkStripState.hidden();
      }

      final String status =
          _status(data['status']);

      // ========================================================
      // ACTIVE LIVE WALK
      // ========================================================

      if (_isLiveStatus(status)) {
        return ActiveWalkStripState(
          show: true,
          isLive: true,
          walkId: reachedWalkId,
        );
      }

      // Reached/session exists but not active yet.
      return const ActiveWalkStripState.hidden();
    }

    // ==========================================================
    // PHASE 1
    //
    // BEFORE REACHED ONLY.
    // walk_request controls the strip.
    // ==========================================================

    final QueryDocumentSnapshot<
            Map<String, dynamic>>?
        request =
        _findCurrentRequest(requestDocs);

    if (request == null) {
      return const ActiveWalkStripState.hidden();
    }

    final Map<String, dynamic> requestData =
        request.data();

    final String requestStatus =
        _status(requestData['status']);

    final String walkId =
        _walkIdFromData(
      requestData,
      request.id,
    );

    if (walkId.isEmpty) {
      return const ActiveWalkStripState.hidden();
    }

    // ==========================================================
    // REACHED
    //
    // Do not show Accepted strip for REACHED.
    // Reached will switch to session-only mode on next emit.
    // ==========================================================

    if (_isReachedStatus(requestStatus)) {
      return const ActiveWalkStripState.hidden();
    }

    // ==========================================================
    // REQUEST ENDED
    // ==========================================================

    if (_isRequestEnded(requestStatus)) {
      return const ActiveWalkStripState.hidden();
    }

    // ==========================================================
    // ACCEPTED
    // ==========================================================

    if (_isAcceptedStatus(requestStatus)) {
      return ActiveWalkStripState(
        show: true,
        isLive: false,
        walkId: walkId,
      );
    }

    return const ActiveWalkStripState.hidden();
  }

  // ============================================================
  // FIND CURRENT REQUEST
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findCurrentRequest(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        candidates =
        documents.where(
      (
        QueryDocumentSnapshot<
            Map<String, dynamic>>
            document,
      ) {
        final String status =
            _status(
          document.data()['status'],
        );

        return _isAcceptedStatus(status) ||
            _isReachedStatus(status);
      },
    ).toList();

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (
        QueryDocumentSnapshot<
                Map<String, dynamic>>
            a,
        QueryDocumentSnapshot<
                Map<String, dynamic>>
            b,
      ) {
        return _documentTime(b).compareTo(
          _documentTime(a),
        );
      },
    );

    return candidates.first;
  }

  // ============================================================
  // FIND LATEST SESSION
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findLatestRelevantSession(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
  ) {
    if (documents.isEmpty) {
      return null;
    }

    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        candidates =
        List<QueryDocumentSnapshot<
                Map<String, dynamic>>>.from(
      documents,
    );

    candidates.sort(
      (
        QueryDocumentSnapshot<
                Map<String, dynamic>>
            a,
        QueryDocumentSnapshot<
                Map<String, dynamic>>
            b,
      ) {
        return _documentTime(b).compareTo(
          _documentTime(a),
        );
      },
    );

    return candidates.first;
  }

  // ============================================================
  // FIND SESSION FOR SPECIFIC WALK
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findLatestSessionForWalk(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
    String walkId,
  ) {
    final String targetWalkId =
        walkId.trim();

    if (targetWalkId.isEmpty) {
      return null;
    }

    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        candidates =
        documents.where(
      (
        QueryDocumentSnapshot<
            Map<String, dynamic>>
            document,
      ) {
        final String sessionWalkId =
            _walkIdFromData(
          document.data(),
          '',
        );

        return sessionWalkId == targetWalkId;
      },
    ).toList();

    if (candidates.isEmpty) {
      return null;
    }

    candidates.sort(
      (
        QueryDocumentSnapshot<
                Map<String, dynamic>>
            a,
        QueryDocumentSnapshot<
                Map<String, dynamic>>
            b,
      ) {
        return _documentTime(b).compareTo(
          _documentTime(a),
        );
      },
    );

    return candidates.first;
  }

  // ============================================================
  // ACCEPTED
  // ============================================================

  bool _isAcceptedStatus(
    String status,
  ) {
    switch (status) {
      case 'ACCEPTED':
      case 'ACCEPT':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // REACHED
  // ============================================================

  bool _isReachedStatus(
    String status,
  ) {
    switch (status) {
      case 'REACHED':
      case 'ARRIVED':
      case 'READY':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // LIVE
  // ============================================================

  bool _isLiveStatus(
    String status,
  ) {
    switch (status) {
      case 'ACTIVE':
      case 'STARTED':
      case 'LIVE':
      case 'IN_PROGRESS':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // REQUEST END
  // ============================================================

  bool _isRequestEnded(
    String status,
  ) {
    switch (status) {
      case 'REJECTED':
      case 'DECLINED':
      case 'CANCELLED':
      case 'CANCELED':
      case 'COMPLETED':
      case 'ENDED':
      case 'EXPIRED':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // SESSION COMPLETION
  // ============================================================

  bool _isSessionCompleted(
    Map<String, dynamic> data,
  ) {
    final String status =
        _status(data['status']);

    if (status == 'COMPLETED' ||
        status == 'ENDED' ||
        status == 'CANCELLED' ||
        status == 'CANCELED') {
      return true;
    }

    if (data['walkEnded'] == true) {
      return true;
    }

    if (data['completedAt'] != null) {
      return true;
    }

    return false;
  }

  // ============================================================
  // WALK ID
  // ============================================================

  String _walkIdFromData(
    Map<String, dynamic> data,
    String fallbackDocumentId,
  ) {
    final List<dynamic> values = <dynamic>[
      data['walkId'],
      data['requestId'],
      data['walkRequestId'],
      data['activeWalkId'],
    ];

    for (final dynamic value in values) {
      final String id = _string(value);

      if (id.isNotEmpty) {
        return id;
      }
    }

    return fallbackDocumentId.trim();
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _status(
    dynamic value,
  ) {
    return _string(value)
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  // ============================================================
  // STRING
  // ============================================================

  String _string(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  // ============================================================
  // DOCUMENT TIME
  // ============================================================

  DateTime _documentTime(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final List<dynamic> values = <dynamic>[
      data['updatedAt'],
      data['completedAt'],
      data['endedAt'],
      data['startedAt'],
      data['reachedAt'],
      data['acceptedAt'],
      data['createdAt'],
    ];

    for (final dynamic value in values) {
      if (value is Timestamp) {
        return value.toDate();
      }

      if (value is DateTime) {
        return value;
      }
    }

    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
