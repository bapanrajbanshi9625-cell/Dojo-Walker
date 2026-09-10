import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/accept_live_strip_data.dart';

class AcceptLiveStripService {
  AcceptLiveStripService._();

  static final AcceptLiveStripService instance =
      AcceptLiveStripService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // PUBLIC WATCH
  //
  // SOURCE OF TRUTH:
  //
  // 1. walk_request
  // 2. liveWalkSessions
  //
  // FLOW:
  //
  // accepted
  //     ↓
  // Accepted Strip
  //     ↓
  // reached
  //     ↓
  // liveWalkSessions
  //     ↓
  // Live Strip
  //     ↓
  // completed
  //     ↓
  // Hide
  // ============================================================

  Stream<AcceptLiveStripData> watch() {
    final String walkerUid =
        _auth.currentUser?.uid.trim() ?? '';

    if (walkerUid.isEmpty) {
      return Stream<AcceptLiveStripData>.value(
        const AcceptLiveStripData.hidden(),
      );
    }

    final Stream<
            QuerySnapshot<Map<String, dynamic>>>
        requestStream =
        _firestore
            .collection('walk_request')
            .where(
              'walkerUid',
              isEqualTo: walkerUid,
            )
            .snapshots();

    final Stream<
            QuerySnapshot<Map<String, dynamic>>>
        sessionStream =
        _firestore
            .collection('liveWalkSessions')
            .where(
              'walkerUid',
              isEqualTo: walkerUid,
            )
            .snapshots();

    return _combineStreams(
      requestStream,
      sessionStream,
    );
  }

  // ============================================================
  // COMBINE FIRESTORE STREAMS
  // ============================================================

  Stream<AcceptLiveStripData> _combineStreams(
    Stream<QuerySnapshot<Map<String, dynamic>>>
        requestStream,
    Stream<QuerySnapshot<Map<String, dynamic>>>
        sessionStream,
  ) {
    final StreamController<AcceptLiveStripData>
        controller =
        StreamController<AcceptLiveStripData>();

    StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>?
        requestSubscription;

    StreamSubscription<
            QuerySnapshot<Map<String, dynamic>>>?
        sessionSubscription;

    QuerySnapshot<Map<String, dynamic>>?
        latestRequests;

    QuerySnapshot<Map<String, dynamic>>?
        latestSessions;

    bool cancelled = false;

    // ------------------------------------------------------------
    // Once a request reaches the pickup point, this ID becomes
    // the active live-walk identity.
    //
    // After this point we NEVER use another request to switch
    // the strip back to Incoming.
    // ------------------------------------------------------------

    String reachedRequestId = '';

    void emit() {
      if (cancelled || controller.isClosed) {
        return;
      }

      final AcceptLiveStripData state =
          _resolve(
        requestSnapshot: latestRequests,
        sessionSnapshot: latestSessions,
        reachedRequestId: reachedRequestId,
      );

      controller.add(state);
    }

    // ==========================================================
    // WALK REQUEST STREAM
    // ==========================================================

    requestSubscription =
        requestStream.listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        latestRequests = snapshot;

        // ------------------------------------------------------
        // Detect REACHED.
        //
        // Once detected, lock the request ID.
        // ------------------------------------------------------

        if (reachedRequestId.isEmpty) {
          final QueryDocumentSnapshot<
                  Map<String, dynamic>>?
              reachedRequest =
              _findReachedRequest(
            snapshot.docs,
          );

          if (reachedRequest != null) {
            reachedRequestId =
                reachedRequest.id.trim();
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

    sessionSubscription =
        sessionStream.listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        latestSessions = snapshot;

        // ------------------------------------------------------
        // A session may already exist when the strip starts
        // listening.
        //
        // Therefore discover its request ID here as well.
        // ------------------------------------------------------

        if (reachedRequestId.isEmpty) {
          final QueryDocumentSnapshot<
                  Map<String, dynamic>>?
              session =
              _findLatestActiveOrReachedSession(
            snapshot.docs,
          );

          if (session != null) {
            final String requestId =
                _requestIdFromSession(
              session,
            );

            if (requestId.isNotEmpty) {
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

      await requestSubscription?.cancel();
      await sessionSubscription?.cancel();
    };

    return controller.stream;
  }

  // ============================================================
  // RESOLVE CURRENT STRIP
  // ============================================================

  AcceptLiveStripData _resolve({
    QuerySnapshot<Map<String, dynamic>>?
        requestSnapshot,
    QuerySnapshot<Map<String, dynamic>>?
        sessionSnapshot,
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
    // LIVE PHASE
    //
    // Once REACHED is known, only the matching live session
    // controls the strip.
    //
    // This prevents Incoming Screen from returning after
    // reaching the pickup point.
    // ==========================================================

    if (reachedRequestId.isNotEmpty) {
      final QueryDocumentSnapshot<
              Map<String, dynamic>>?
          session =
          _findSessionForRequest(
        sessionDocs,
        reachedRequestId,
      );

      if (session == null) {
        // Session may be created a moment after REACHED.
        // Do not fall back to Incoming.
        return const AcceptLiveStripData.hidden();
      }

      final Map<String, dynamic> data =
          session.data();

      if (_isSessionCompleted(data)) {
        return const AcceptLiveStripData.hidden();
      }

      final String status =
          _normaliseStatus(data['status']);

      if (_isLiveStatus(status)) {
        return AcceptLiveStripData(
          status: AcceptLiveStripStatus.live,
          requestId: reachedRequestId,
        );
      }

      return const AcceptLiveStripData.hidden();
    }

    // ==========================================================
    // ACCEPTED PHASE
    // ==========================================================

    final QueryDocumentSnapshot<
            Map<String, dynamic>>?
        request =
        _findAcceptedRequest(
      requestDocs,
    );

    if (request == null) {
      return const AcceptLiveStripData.hidden();
    }

    final String requestId =
        request.id.trim();

    if (!_isValidRequestId(requestId)) {
      return const AcceptLiveStripData.hidden();
    }

    final Map<String, dynamic> data =
        request.data();

    final String status =
        _normaliseStatus(data['status']);

    // ----------------------------------------------------------
    // If request is already reached, wait for its live session.
    // Never show Incoming here.
    // ----------------------------------------------------------

    if (_isReachedStatus(status)) {
      return const AcceptLiveStripData.hidden();
    }

    // ----------------------------------------------------------
    // Request ended.
    // ----------------------------------------------------------

    if (_isRequestEnded(status)) {
      return const AcceptLiveStripData.hidden();
    }

    // ----------------------------------------------------------
    // Accepted / on the way.
    // ----------------------------------------------------------

    if (_isAcceptedStatus(status)) {
      return AcceptLiveStripData(
        status: AcceptLiveStripStatus.accepted,
        requestId: requestId,
      );
    }

    return const AcceptLiveStripData.hidden();
  }

  // ============================================================
  // FIND ACCEPTED REQUEST
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
            _normaliseStatus(
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
  // FIND REACHED REQUEST
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findReachedRequest(
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
            _normaliseStatus(
          document.data()['status'],
        );

        return _isReachedStatus(status);
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
  // FIND SESSION
  //
  // Canonical structure:
  //
  // liveWalkSessions/{requestId}
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findSessionForRequest(
    List<QueryDocumentSnapshot<
            Map<String, dynamic>>>
        documents,
    String requestId,
  ) {
    final String target =
        requestId.trim();

    if (!_isValidRequestId(target)) {
      return null;
    }

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>>
        document in documents) {
      if (document.id.trim() == target) {
        return document;
      }
    }

    return null;
  }

  // ============================================================
  // FIND EXISTING ACTIVE SESSION
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _findLatestActiveOrReachedSession(
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
        final Map<String, dynamic> data =
            document.data();

        if (_isSessionCompleted(data)) {
          return false;
        }

        final String status =
            _normaliseStatus(
          data['status'],
        );

        return _isLiveStatus(status) ||
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
  // REQUEST ID FROM SESSION
  //
  // Document ID is authoritative.
  // ============================================================

  String _requestIdFromSession(
    QueryDocumentSnapshot<
            Map<String, dynamic>>
        document,
  ) {
    final String documentId =
        document.id.trim();

    if (_isValidRequestId(documentId)) {
      return documentId;
    }

    final String storedRequestId =
        _string(
      document.data()['requestId'],
    );

    if (_isValidRequestId(storedRequestId)) {
      return storedRequestId;
    }

    return '';
  }

  // ============================================================
  // REQUEST ID VALIDATION
  // ============================================================

  bool _isValidRequestId(
    String value,
  ) {
    return RegExp(
      r'^DW\d{6}$',
    ).hasMatch(
      value.trim(),
    );
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
      case 'ON_THE_WAY':
      case 'ONTHEWAY':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // REACHED STATUS
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
  // LIVE SESSION STATUS
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
  // REQUEST END STATUS
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
        _normaliseStatus(data['status']);

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
  // NORMALISE STATUS
  // ============================================================

  String _normaliseStatus(
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
