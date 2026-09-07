import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActiveWalkStripState {
  const ActiveWalkStripState({
    required this.show,
    required this.isLive,
    required this.requestId,
  });

  final bool show;
  final bool isLive;

  /// Canonical Dojo Walk ID.
  final String requestId;

  /// Compatibility getter.
  ///
  /// The canonical value is requestId.
  String get walkId => requestId;

  const ActiveWalkStripState.hidden()
      : show = false,
        isLive = false,
        requestId = '';
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
  // walk_request/{requestId}
  //
  // ACCEPTED
  //    ↓
  // ON_THE_WAY
  //    ↓
  // REACHED
  //
  // PHASE 2:
  // liveWalkSessions/{requestId}
  //
  // ACTIVE / STARTED / LIVE / IN_PROGRESS
  //    ↓
  // LIVE STRIP
  //
  // COMPLETED / ENDED / walkEnded / completedAt
  //    ↓
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
    // Once REACHED is detected,
    // walk_request is NEVER used for resolving
    // the active strip again.
    //
    // liveWalkSessions becomes the only source.
    // ==========================================================

    bool reachedPhase = false;

    String reachedRequestId = '';

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
        reachedRequestId: reachedRequestId,
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

            final String requestId =
                _requestIdFromDocument(
              request,
            );

            // ==================================================
            // REACHED = SWITCH TO SESSION-ONLY MODE
            // ==================================================

            if (_isReachedStatus(status) &&
                _isValidRequestId(requestId)) {
              reachedPhase = true;
              reachedRequestId = requestId;
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
        // If a session itself reports REACHED,
        // switch to session-only mode.
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

            final String requestId =
                _requestIdFromDocument(
              session,
            );

            if (_isReachedStatus(status) &&
                _isValidRequestId(requestId)) {
              reachedPhase = true;
              reachedRequestId = requestId;
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
    required String reachedRequestId,
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
    // ONLY liveWalkSessions.
    // ==========================================================

    if (reachedPhase) {
      final String requestId =
          reachedRequestId.trim();

      if (!_isValidRequestId(requestId)) {
        return const ActiveWalkStripState.hidden();
      }

      final QueryDocumentSnapshot<
              Map<String, dynamic>>?
          session =
          _findLatestSessionForRequest(
        sessionDocs,
        requestId,
      );

      if (session == null) {
        // Session may not have appeared yet.
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
          requestId: requestId,
        );
      }

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

    final String requestId =
        _requestIdFromDocument(
      request,
    );

    if (!_isValidRequestId(requestId)) {
      return const ActiveWalkStripState.hidden();
    }

    // ==========================================================
    // REACHED
    //
    // The next stream event will switch to session-only mode.
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
    // ACCEPTED / ON THE WAY
    // ==========================================================

    if (_isAcceptedStatus(requestStatus)) {
      return ActiveWalkStripState(
        show: true,
        isLive: false,
        requestId: requestId,
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
  // FIND SESSION FOR REQUEST
  //
  // Canonical:
  //
  // liveWalkSessions/{requestId}
  //
  // The document ID is authoritative.
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findLatestSessionForRequest(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
    String requestId,
  ) {
    final String targetRequestId =
        requestId.trim();

    if (!_isValidRequestId(targetRequestId)) {
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
        // ======================================================
        // IMPORTANT:
        //
        // liveWalkSessions/{requestId}
        //
        // Document ID is the canonical ID.
        // ======================================================

        return document.id.trim() ==
            targetRequestId;
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
  // REQUEST ID FROM DOCUMENT
  //
  // Canonical source = document.id
  //
  // requestId field is checked only as a safety validation.
  // ============================================================

  String _requestIdFromDocument(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final String documentId =
        document.id.trim();

    if (!_isValidRequestId(documentId)) {
      return '';
    }

    final Map<String, dynamic> data =
        document.data();

    final String storedRequestId =
        _string(data['requestId']);

    if (storedRequestId.isNotEmpty &&
        storedRequestId != documentId) {
      return '';
    }

    return documentId;
  }

  // ============================================================
  // VALID REQUEST ID
  // ============================================================

  bool _isValidRequestId(
    String value,
  ) {
    return RegExp(
      r'^DW\d{6}$',
    ).hasMatch(value.trim());
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
      case 'ON_THE_WAY':
      case 'ONTHEWAY':
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
      case 'ONGOING':
      case 'WALKING':
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

    if (data['trackingEnded'] == true) {
      return true;
    }

    if (data['completedAt'] != null) {
      return true;
    }

    if (data['endedAt'] != null) {
      return true;
    }

    return false;
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
