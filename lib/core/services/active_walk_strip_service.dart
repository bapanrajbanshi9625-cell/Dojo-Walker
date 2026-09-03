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
  // Collections used:
  // 1. walk_requests
  // 2. liveWalkSessions
  //
  // active_walks is NOT used.
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
            .collection('walk_requests')
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
    StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>
        requestSubscription =
        requestStream.listen((_) {});

    StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>
        sessionSubscription =
        sessionStream.listen((_) {});

    QuerySnapshot<Map<String, dynamic>>?
        latestRequests;

    QuerySnapshot<Map<String, dynamic>>?
        latestSessions;

    final StreamController<ActiveWalkStripState>
        controller =
        StreamController<ActiveWalkStripState>();

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

    requestSubscription.cancel();

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

    sessionSubscription.cancel();

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
  // RESOLVE
  //
  // PRIORITY:
  //
  // 1. Active live session
  // 2. Accepted request
  // 3. Nothing
  //
  // IMPORTANT:
  // Pending/searching/requested are NOT shown.
  // ============================================================

  ActiveWalkStripState _resolve({
    QuerySnapshot<Map<String, dynamic>>?
        requestSnapshot,
    QuerySnapshot<Map<String, dynamic>>?
        sessionSnapshot,
  }) {
    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        sessionDocs =
        sessionSnapshot?.docs ??
            const <
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        requestDocs =
        requestSnapshot?.docs ??
            const <
                QueryDocumentSnapshot<
                    Map<String, dynamic>>>[];

    // ==========================================================
    // STEP 1
    // ACTIVE LIVE SESSION
    //
    // reached / arrived / active / started / live
    // ==========================================================

    final QueryDocumentSnapshot<
            Map<String, dynamic>>?
        liveDocument =
        _findCurrentLiveSession(
      sessionDocs,
    );

    if (liveDocument != null) {
      final Map<String, dynamic> data =
          liveDocument.data();

      final String walkId =
          _walkIdFromData(
        data,
        liveDocument.id,
      );

      if (walkId.isNotEmpty) {
        return ActiveWalkStripState(
          show: true,
          isLive: true,
          walkId: walkId,
        );
      }
    }

    // ==========================================================
    // STEP 2
    // ONLY ACCEPTED REQUEST
    //
    // Pending/searching/requested are intentionally ignored.
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
    // HARD HIDE
    // ==========================================================

    if (_isEndedStatus(requestStatus)) {
      return const ActiveWalkStripState.hidden();
    }

    // ==========================================================
    // CHECK MATCHING SESSION
    // ==========================================================

    final QueryDocumentSnapshot<
            Map<String, dynamic>>?
        matchingSession =
        _findSessionForWalk(
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

      // Completed session = hide old walk.
      if (_isSessionEnded(sessionStatus)) {
        return const ActiveWalkStripState.hidden();
      }

      // Active session = live strip.
      if (_isLiveStatus(sessionStatus)) {
        return ActiveWalkStripState(
          show: true,
          isLive: true,
          walkId: walkId,
        );
      }
    }

    // ==========================================================
    // ACCEPTED REQUEST
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
  // FIND CURRENT LIVE SESSION
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findCurrentLiveSession(
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
            doc,
      ) {
        final String status =
            _status(
          doc.data()['status'],
        );

        return _isLiveStatus(status);
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
  // FIND ONLY ACCEPTED REQUEST
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
            doc,
      ) {
        final String status =
            _status(
          doc.data()['status'],
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
  // FIND SESSION FOR WALK
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findSessionForWalk(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
    String walkId,
  ) {
    final String targetId = walkId.trim();

    if (targetId.isEmpty) {
      return null;
    }

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc in documents) {
      final String sessionWalkId =
          _walkIdFromData(
        doc.data(),
        '',
      );

      if (sessionWalkId == targetId) {
        return doc;
      }
    }

    return null;
  }

  // ============================================================
  // ACCEPTED ONLY
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
  // LIVE SESSION
  // ============================================================

  bool _isLiveStatus(
    String status,
  ) {
    switch (status) {
      case 'REACHED':
      case 'ARRIVED':
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
  // REQUEST ENDED
  // ============================================================

  bool _isEndedStatus(
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
  // SESSION ENDED
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
      final String result = _string(value);

      if (result.isNotEmpty) {
        return result;
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
      data['createdAt'],
      data['acceptedAt'],
      data['startedAt'],
      data['reachedAt'],
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
