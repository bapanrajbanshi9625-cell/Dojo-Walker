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
  // ONLY THESE TWO COLLECTIONS ARE USED:
  //
  // 1. walk_requests
  // 2. liveWalkSessions
  //
  // active_walks is NOT USED.
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
  // COMBINE REQUEST + LIVE SESSION
  // ============================================================

  Stream<ActiveWalkStripState> _combineStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>>
        requestStream,
    Stream<QuerySnapshot<Map<String, dynamic>>>
        sessionStream,
  ) {
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

    final StreamController<ActiveWalkStripState>
        controller =
        StreamController<ActiveWalkStripState>();

    bool cancelled = false;

    void emit() {
      if (cancelled || controller.isClosed) {
        return;
      }

      final ActiveWalkStripState state =
          _resolve(
        requestSnapshot: latestRequests,
        sessionSnapshot: latestSessions,
      );

      controller.add(state);
    }

    requestSubscription = requestStream.listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        latestRequests = snapshot;
        emit();
      },
      onError: (Object error, StackTrace stackTrace) {
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
      onError: (Object error, StackTrace stackTrace) {
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
  // RESOLVE CURRENT LIVE WALK
  //
  // PRIORITY:
  //
  // 1. Active liveWalkSessions
  // 2. Accepted/request state
  // 3. Pending request
  // 4. Nothing
  //
  // REJECTED/CANCELLED/COMPLETED/ENDED
  // NEVER SHOW.
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
                    Map<String, dynamic>> >[];

    final List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        requestDocs =
        requestSnapshot?.docs ??
            const <
                QueryDocumentSnapshot<
                    Map<String, dynamic>> >[];

    // ==========================================================
    // STEP 1
    // ACTIVE LIVE SESSION
    //
    // reached / started / live
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
    // CURRENT REQUEST
    //
    // pending/searching/requested/accepted
    // ==========================================================

    final QueryDocumentSnapshot<
            Map<String, dynamic>>?
        requestDocument =
        _findCurrentRequest(
      requestDocs,
    );

    if (requestDocument == null) {
      return const ActiveWalkStripState.hidden();
    }

    final Map<String, dynamic> requestData =
        requestDocument.data();

    final String walkId =
        _walkIdFromData(
      requestData,
      requestDocument.id,
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

    if (_isRejectedOrEnded(requestStatus)) {
      return const ActiveWalkStripState.hidden();
    }

    // ==========================================================
    // CHECK MATCHING LIVE SESSION
    //
    // If this particular walk has a completed/ended session,
    // do not show its old request.
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

      if (_isSessionEnded(sessionStatus)) {
        return const ActiveWalkStripState.hidden();
      }

      if (_isLiveStatus(sessionStatus)) {
        return ActiveWalkStripState(
          show: true,
          isLive: true,
          walkId: walkId,
        );
      }
    }

    // ==========================================================
    // ACTIVE REQUEST
    //
    // pending/searching/requested
    // accepted
    // ==========================================================

    if (_isRequestActive(requestStatus)) {
      return ActiveWalkStripState(
        show: true,
        isLive: false,
        walkId: walkId,
      );
    }

    // ==========================================================
    // UNKNOWN STATUS
    //
    // Safer to hide rather than showing a stale walk.
    // ==========================================================

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
        final Map<String, dynamic> data =
            doc.data();

        final String status =
            _status(
          data['status'],
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
        return _documentTime(b)
            .compareTo(
          _documentTime(a),
        );
      },
    );

    return candidates.first;
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
            doc,
      ) {
        final Map<String, dynamic> data =
            doc.data();

        final String status =
            _status(
          data['status'],
        );

        return _isRequestActive(status);
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
        return _documentTime(b)
            .compareTo(
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
      _findSessionForWalk(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
    String walkId,
  ) {
    final String targetId =
        walkId.trim();

    if (targetId.isEmpty) {
      return null;
    }

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        doc in documents) {
      final Map<String, dynamic> data =
          doc.data();

      final String sessionWalkId =
          _walkIdFromData(
        data,
        '',
      );

      if (sessionWalkId == targetId) {
        return doc;
      }
    }

    return null;
  }

  // ============================================================
  // REQUEST STATUS
  // ============================================================

  bool _isRequestActive(
    String status,
  ) {
    switch (status) {
      case 'PENDING':
      case 'SEARCHING':
      case 'REQUESTED':
      case 'CREATED':
      case 'ACCEPTED':
      case 'ACCEPT':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // LIVE SESSION STATUS
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
  // REQUEST REJECTED / ENDED
  // ============================================================

  bool _isRejectedOrEnded(
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
  //
  // Supports both:
  // walkId
  // requestId
  // id
  // document ID
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
      final String result =
          _string(value);

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
  //
  // Used only to choose the newest request/session when
  // multiple documents exist.
  // ============================================================

  DateTime _documentTime(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final Map<String, dynamic> data =
        document.data();

    final List<dynamic> values =
        <dynamic>[
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

    return DateTime.fromMillisecondsSinceEpoch(
      0,
    );
  }
}
