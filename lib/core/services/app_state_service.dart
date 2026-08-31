// File: lib/core/services/app_state_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// DOJO WALKER - CENTRAL APP STATE SERVICE
/// ============================================================
///
/// Firestore collections used by this service:
///
///     1. walk_request
///     2. liveWalkSessions
///
/// IMPORTANT:
///     active_walk / active_walks are NOT used.
///
/// Request lifecycle:
///
///     pending/searching
///          ↓
///       accepted
///          ↓
///       reached
///          ↓
///       started/live
///          ↓
///       completed/ended
///
/// LIVE WALK UI:
///
///     Pending/Search → SHOW
///     Accepted       → SHOW
///     Rejected       → HIDE
///     Cancelled      → HIDE
///     Reached        → SHOW
///     Started/Live   → SHOW
///     Completed      → HIDE
/// ============================================================

class AppStateService {
  AppStateService._();

  static final AppStateService instance =
      AppStateService._();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests =>
          _firestore.collection('walk_request');

  CollectionReference<Map<String, dynamic>>
      get _liveWalkSessions =>
          _firestore.collection('liveWalkSessions');

  // ============================================================
  // ACTIVE STATE
  // ============================================================

  String? _activeWalkId;

  String? _activeSessionId;

  Map<String, dynamic>? _activeWalkData;

  Map<String, dynamic>? _activeSessionData;

  // ============================================================
  // GETTERS
  // ============================================================

  String? get activeWalkId => _activeWalkId;

  String? get activeSessionId => _activeSessionId;

  Map<String, dynamic>? get activeWalkData =>
      _activeWalkData;

  Map<String, dynamic>? get activeSessionData =>
      _activeSessionData;

  bool get hasActiveWalk =>
      _activeWalkId != null &&
      _activeWalkData != null &&
      _activeWalkData!.isNotEmpty;

  bool get hasActiveSession =>
      _activeSessionId != null &&
      _activeSessionData != null &&
      _activeSessionData!.isNotEmpty;

  // ============================================================
  // SUBSCRIPTIONS
  // ============================================================

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _walkSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _sessionSubscription;

  StreamSubscription<User?>?
      _authSubscription;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    await _authSubscription?.cancel();

    _authSubscription =
        _auth.authStateChanges().listen(
      (User? user) async {
        if (user == null) {
          await clearState();
          return;
        }

        await recoverCurrentState();
      },
    );

    if (_auth.currentUser != null) {
      await recoverCurrentState();
    }
  }

  // ============================================================
  // RECOVER CURRENT STATE
  //
  // Used after:
  // - app startup
  // - app resume
  // - login
  //
  // We intentionally read ALL request documents for this walker
  // and resolve the current active one locally.
  // This avoids depending on a Firestore whereIn list that could
  // miss another valid request status.
  // ============================================================

  Future<void> recoverCurrentState() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      await clearState();
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _walkRequests
              .where(
                'walkerUid',
                isEqualTo: user.uid,
              )
              .get();

      final QueryDocumentSnapshot<
              Map<String, dynamic>>?
          selected =
          _selectCurrentRequest(
        snapshot.docs,
      );

      if (selected == null) {
        await _clearRequestAndSession();
        return;
      }

      final Map<String, dynamic>?
          data =
          selected.data();

      if (data == null) {
        await _clearRequestAndSession();
        return;
      }

      _setWalkData(
        selected.id,
        data,
      );

      await _resolveSessionForCurrentWalk(
        data,
      );

      await _startRequestListener();

    } catch (_) {
      // Keep existing cached state on temporary
      // Firebase/network errors.
    }
  }

  // ============================================================
  // REALTIME REQUEST LISTENER
  // ============================================================

  Future<void> _startRequestListener() async {
    await _walkSubscription?.cancel();

    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    _walkSubscription =
        _walkRequests
            .where(
              'walkerUid',
              isEqualTo: user.uid,
            )
            .snapshots()
            .listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        final QueryDocumentSnapshot<
                Map<String, dynamic>>?
            selected =
            _selectCurrentRequest(
          snapshot.docs,
        );

        if (selected == null) {
          unawaited(
            _clearRequestAndSession(),
          );
          return;
        }

        final Map<String, dynamic>?
            data =
            selected.data();

        if (data == null) {
          return;
        }

        _setWalkData(
          selected.id,
          data,
        );

        unawaited(
          _resolveSessionForCurrentWalk(
            data,
          ),
        );
      },
      onError: (_) {
        // Preserve cached state if Firestore temporarily
        // becomes unavailable.
      },
    );
  }

  // ============================================================
  // SELECT CURRENT REQUEST
  //
  // Only these request statuses are considered active:
  //
  // PENDING
  // SEARCHING
  // REQUESTED
  // CREATED
  // ACCEPTED
  // ACTIVE
  // REACHED
  // STARTED
  // LIVE
  //
  // Rejected/cancelled/completed/ended are ignored.
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _selectCurrentRequest(
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
        final int
            priorityCompare =
            _statusPriority(
          b.data()['status'],
        ).compareTo(
          _statusPriority(
            a.data()['status'],
          ),
        );

        if (priorityCompare != 0) {
          return priorityCompare;
        }

        return _documentTime(b)
            .compareTo(
          _documentTime(a),
        );
      },
    );

    return candidates.first;
  }

  // ============================================================
  // SET WALK DATA
  // ============================================================

  void _setWalkData(
    String walkId,
    Map<String, dynamic> data,
  ) {
    _activeWalkId =
        walkId.trim();

    _activeWalkData =
        Map<String, dynamic>.from(
      data,
    );

    final String sessionId =
        _firstNonEmpty(
      <dynamic>[
        data['liveWalkSessionId'],
        data['sessionId'],
      ],
    );

    if (sessionId.isNotEmpty &&
        sessionId !=
            (_activeSessionId ?? '')) {
      _activeSessionId =
          sessionId;
    }
  }

  // ============================================================
  // RESOLVE LIVE SESSION
  //
  // First uses session ID stored in walk_request.
  //
  // If request does not contain session ID, searches
  // liveWalkSessions using walkerUid + walkId.
  // ============================================================

  Future<void> _resolveSessionForCurrentWalk(
    Map<String, dynamic> requestData,
  ) async {
    final String walkId =
        _firstNonEmpty(
      <dynamic>[
        requestData['walkId'],
        requestData['requestId'],
        requestData['walkRequestId'],
        _activeWalkId,
      ],
    );

    String sessionId =
        _firstNonEmpty(
      <dynamic>[
        requestData['liveWalkSessionId'],
        requestData['sessionId'],
        _activeSessionId,
      ],
    );

    // ==========================================================
    // SESSION ID ALREADY KNOWN
    // ==========================================================

    if (sessionId.isNotEmpty) {
      _activeSessionId =
          sessionId;

      await _startSessionListener();

      return;
    }

    // ==========================================================
    // NO SESSION ID YET
    //
    // Search liveWalkSessions for this walk.
    // ==========================================================

    if (walkId.isEmpty) {
      _activeSessionData = null;
      return;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final QuerySnapshot<Map<String, dynamic>>
          snapshot =
          await _liveWalkSessions
              .where(
                'walkerUid',
                isEqualTo: user.uid,
              )
              .where(
                'walkId',
                isEqualTo: walkId,
              )
              .limit(10)
              .get();

      final QueryDocumentSnapshot<
              Map<String, dynamic>>?
          session =
          _selectCurrentSession(
        snapshot.docs,
      );

      if (session == null) {
        _activeSessionId = null;
        _activeSessionData = null;
        await _sessionSubscription?.cancel();
        _sessionSubscription = null;
        return;
      }

      sessionId = session.id;

      _activeSessionId =
          sessionId;

      final Map<String, dynamic>?
          sessionData =
          session.data();

      if (sessionData != null) {
        _activeSessionData =
            Map<String, dynamic>.from(
          sessionData,
        );
      }

      await _startSessionListener();

    } catch (_) {
      // Preserve cached session state.
    }
  }

  // ============================================================
  // CURRENT SESSION
  // ============================================================

  QueryDocumentSnapshot<
          Map<String, dynamic>>?
      _selectCurrentSession(
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

        return !_isSessionEnded(status);
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
  // LIVE SESSION LISTENER
  // ============================================================

  Future<void> _startSessionListener() async {
    await _sessionSubscription?.cancel();

    _sessionSubscription = null;

    final String? sessionId =
        _activeSessionId;

    if (sessionId == null ||
        sessionId.trim().isEmpty) {
      _activeSessionData = null;
      return;
    }

    _sessionSubscription =
        _liveWalkSessions
            .doc(sessionId.trim())
            .snapshots()
            .listen(
      (
        DocumentSnapshot<
                Map<String, dynamic>>
            snapshot,
      ) {
        if (!snapshot.exists) {
          _activeSessionData = null;
          return;
        }

        final Map<String, dynamic>?
            data =
            snapshot.data();

        if (data == null) {
          return;
        }

        final String status =
            _status(
          data['status'],
        );

        // ======================================================
        // SESSION COMPLETED / ENDED
        // ======================================================

        if (_isSessionEnded(status)) {
          _activeSessionData = null;
          _activeSessionId = null;

          unawaited(
            _clearCompletedRequestIfNecessary(),
          );

          return;
        }

        _activeSessionData =
            Map<String, dynamic>.from(
          data,
        );
      },
      onError: (_) {
        // Preserve cached state.
      },
    );
  }

  // ============================================================
  // WALK REQUEST MONITOR
  //
  // Kept for compatibility with existing callers.
  // ============================================================

  void startWalkRequestMonitor() {
    unawaited(
      _startRequestListener(),
    );
  }

  // ============================================================
  // SET ACTIVE WALK
  //
  // Compatibility API for existing code.
  // No active_walk collection is used.
  // ============================================================

  Future<void> setActiveWalk({
    required String walkId,
    String? sessionId,
  }) async {
    final String cleanWalkId =
        walkId.trim();

    if (cleanWalkId.isEmpty) {
      return;
    }

    _activeWalkId =
        cleanWalkId;

    final String cleanSessionId =
        sessionId?.trim() ?? '';

    _activeSessionId =
        cleanSessionId.isEmpty
            ? null
            : cleanSessionId;

    try {
      final DocumentSnapshot<
              Map<String, dynamic>>
          snapshot =
          await _walkRequests
              .doc(cleanWalkId)
              .get();

      if (snapshot.exists) {
        final Map<String, dynamic>?
            data =
            snapshot.data();

        if (data != null) {
          _activeWalkData =
              Map<String, dynamic>.from(
            data,
          );

          final String
              resolvedSessionId =
              _firstNonEmpty(
            <dynamic>[
              _activeSessionId,
              data['liveWalkSessionId'],
              data['sessionId'],
            ],
          );

          _activeSessionId =
              resolvedSessionId.isEmpty
                  ? null
                  : resolvedSessionId;
        }
      }

      await _startRequestListener();

      if (_activeWalkData != null) {
        await _resolveSessionForCurrentWalk(
          _activeWalkData!,
        );
      }
    } catch (_) {
      // Preserve current state.
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await recoverCurrentState();
  }

  // ============================================================
  // CLEAR REQUEST + SESSION
  // ============================================================

  Future<void>
      _clearRequestAndSession() async {
    await _sessionSubscription?.cancel();

    _sessionSubscription = null;

    _activeWalkId = null;
    _activeSessionId = null;
    _activeWalkData = null;
    _activeSessionData = null;
  }

  // ============================================================
  // CLEAR COMPLETED REQUEST
  //
  // Do not keep a completed session/request as active state.
  // ============================================================

  Future<void>
      _clearCompletedRequestIfNecessary() async {
    final String status =
        _status(
      _activeWalkData?['status'],
    );

    if (_isRequestEnded(status)) {
      await _clearRequestAndSession();
    }
  }

  // ============================================================
  // CLEAR ALL STATE
  // ============================================================

  Future<void> clearState() async {
    await _walkSubscription?.cancel();
    await _sessionSubscription?.cancel();
    await _authSubscription?.cancel();

    _walkSubscription = null;
    _sessionSubscription = null;
    _authSubscription = null;

    _activeWalkId = null;
    _activeSessionId = null;
    _activeWalkData = null;
    _activeSessionData = null;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await _walkSubscription?.cancel();
    await _sessionSubscription?.cancel();
    await _authSubscription?.cancel();

    _walkSubscription = null;
    _sessionSubscription = null;
    _authSubscription = null;

    _activeWalkId = null;
    _activeSessionId = null;
    _activeWalkData = null;
    _activeSessionData = null;
  }

  // ============================================================
  // REQUEST ACTIVE STATUS
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
      case 'ACTIVE':
      case 'REACHED':
      case 'STARTED':
      case 'LIVE':
      case 'IN_PROGRESS':
        return true;

      default:
        return false;
    }
  }

  // ============================================================
  // REQUEST ENDED STATUS
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
  // SESSION ENDED STATUS
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
  // STATUS PRIORITY
  // ============================================================

  int _statusPriority(
    dynamic value,
  ) {
    final String status =
        _status(value);

    switch (status) {
      case 'LIVE':
      case 'IN_PROGRESS':
        return 7;

      case 'STARTED':
        return 6;

      case 'REACHED':
        return 5;

      case 'ACTIVE':
        return 4;

      case 'ACCEPTED':
        return 3;

      case 'SEARCHING':
        return 2;

      case 'PENDING':
      case 'REQUESTED':
      case 'CREATED':
        return 1;

      default:
        return 0;
    }
  }

  // ============================================================
  // STATUS
  // ============================================================

  String _status(
    dynamic value,
  ) {
    return _readString(value)
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
  }

  // ============================================================
  // STRING
  // ============================================================

  String _readString(
    dynamic value,
  ) {
    if (value == null) {
      return '';
    }

    return value
        .toString()
        .trim();
  }

  // ============================================================
  // FIRST NON EMPTY
  // ============================================================

  String _firstNonEmpty(
    List<dynamic> values,
  ) {
    for (final dynamic value in values) {
      final String text =
          _readString(value);

      if (text.isNotEmpty) {
        return text;
      }
    }

    return '';
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

    final List<dynamic> values =
        <dynamic>[
      data['updatedAt'],
      data['createdAt'],
      data['acceptedAt'],
      data['reachedAt'],
      data['startedAt'],
      data['endedAt'],
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
