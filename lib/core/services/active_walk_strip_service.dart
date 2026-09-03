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
  // FLOW:
  //
  // walk_request
  //      ↓
  // status = ACCEPTED
  //      ↓
  // SHOW STRIP
  //
  // liveWalkSessions
  //      ↓
  // ACTIVE / STARTED / LIVE / IN_PROGRESS
  //      ↓
  // LIVE WALK
  //
  // liveWalkSessions
  //      ↓
  // COMPLETED / ENDED / CANCELLED
  //      ↓
  // HIDE STRIP
  //
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
  // COMBINE REQUEST + SESSION STREAMS
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

    StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>
        requestSubscription;

    StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>
        sessionSubscription;

    QuerySnapshot<Map<String, dynamic>>?
        latestRequests;

    QuerySnapshot<Map<String, dynamic>>?
        latestSessions;

    bool cancelled = false;

    void emit() {
      if (cancelled || controller.isClosed) {
        return;
      }

      controller.add(
        _resolve(
          requestSnapshot: latestRequests,
          sessionSnapshot: latestSessions,
        ),
      );
    }

    requestSubscription = requestStream.listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        latestRequests = snapshot;
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

    sessionSubscription = sessionStream.listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        latestSessions = snapshot;
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
  // RESOLVE CURRENT STRIP STATE
  //
  // PRIORITY:
  //
  // 1. Find accepted request
  // 2. Check matching live session
  // 3. Active session => LIVE WALK
  // 4. Completed session => HIDE
  // 5. Accepted request without live session => ACCEPTED STRIP
  // 6. Nothing => HIDE
  //
  // ============================================================

  ActiveWalkStripState _resolve({
    QuerySnapshot<Map<String, dynamic>>?
        requestSnapshot,
    QuerySnapshot<Map<String, dynamic>>?
        sessionSnapshot,
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
    // STEP 1
    // ACCEPTED REQUEST FROM walk_request
    // ==========================================================

    final QueryDocumentSnapshot<
            Map<String, dynamic>>?
        acceptedRequest =
        _findAcceptedRequest(
      requestDocs,
    );

    if (acceptedRequest == null) {
      return const ActiveWalkStripState.hidden();
    }

    final Map<String, dynamic> requestData =
        acceptedRequest.data();

    final String walkId =
        _walkIdFromData(
      requestData,
      acceptedRequest.id,
    );

    if (walkId.isEmpty) {
      return const ActiveWalkStripState.hidden();
    }

    final String requestStatus =
        _status(
      requestData['status'],
    );

    // ==========================================================
    // SAFETY CHECK
    // ==========================================================

    if (_isRequestEnded(requestStatus)) {
      return const ActiveWalkStripState.hidden();
    }

    // ==========================================================
    // STEP 2
    // FIND LIVE SESSION FOR THIS WALK
    // ==========================================================

    final QueryDocumentSnapshot<
            Map<String, dynamic>>?
        matchingSession =
        _findLatestSessionForWalk(
      sessionDocs,
      walkId,
    );

    if (matchingSession != null) {
      final Map<String, dynamic> sessionData =
          matchingSession.data();

      final String sessionStatus =
          _status(
        sessionData['status'],
      );

      // ========================================================
      // LIVE SESSION COMPLETED
      // ========================================================

      if (_isSessionEnded(sessionStatus)) {
        return const ActiveWalkStripState.hidden();
      }

      // ========================================================
      // LIVE SESSION ACTIVE
      // ========================================================

      if (_isLiveStatus(sessionStatus)) {
        return ActiveWalkStripState(
          show: true,
          isLive: true,
          walkId: walkId,
        );
      }
    }

    // ==========================================================
    // STEP 3
    // ACCEPTED REQUEST
    //
    // No active live session yet.
    // Strip remains visible.
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
  // FIND ACCEPTED REQUEST
  //
  // SOURCE:
  // walk_request
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findAcceptedRequest(
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

        return _isAcceptedStatus(status);
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
  // FIND LATEST SESSION FOR WALK
  //
  // SOURCE:
  // liveWalkSessions
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
  // ACCEPTED STATUS
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
  // LIVE STATUS
  // ============================================================

  bool _isLiveStatus(
    String status,
  ) {
    switch (status) {
      case 'ACTIVE':
      case 'STARTED':
      case 'LIVE':
      case 'IN_PROGRESS':
      case 'REACHED':
      case 'ARRIVED':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // REQUEST END STATUS
  //
  // Used only for walk_request.
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
  // SESSION END STATUS
  //
  // Completion comes from liveWalkSessions.
  // ============================================================

  bool _isSessionEnded(
    String status,
  ) {
    switch (status) {
      case 'COMPLETED':
      case 'ENDED':
      case 'CANCELLED':
      case 'CANCELED':
        return true;

      default:
        return false;
    }
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
  // STATUS NORMALIZATION
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
