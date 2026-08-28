// File: lib/core/services/app_state_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// DOJO WALKER - CENTRAL APP STATE SERVICE
/// ============================================================
///
/// Primary collection:
///     walk_request
///
/// Optional collections:
///     active_walk
///     liveWalkSessions
///
/// IMPORTANT:
/// ActiveWalkStrip के लिए walk_request ही primary source है.
/// active_walk document होना जरूरी नहीं है.
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
      get _activeWalks =>
          _firestore.collection('active_walk');

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

  String? get activeWalkId =>
      _activeWalkId;

  String? get activeSessionId =>
      _activeSessionId;

  Map<String, dynamic>?
      get activeWalkData =>
          _activeWalkData;

  Map<String, dynamic>?
      get activeSessionData =>
          _activeSessionData;

  bool get hasActiveWalk =>
      _activeWalkId != null &&
      _activeWalkData != null &&
      _activeWalkData!.isNotEmpty;

  // ============================================================
  // SUBSCRIPTIONS
  // ============================================================

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _walkSubscription;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _activeWalkSubscription;

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
  // ============================================================

  Future<void> recoverCurrentState() async {
    final User? user =
        _auth.currentUser;

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
              .where(
                'status',
                whereIn: <String>[
                  'accepted',
                  'active',
                  'started',
                  'live',
                ],
              )
              .get();

      if (snapshot.docs.isEmpty) {
        await _clearIfNoActiveRequest();
        return;
      }

      DocumentSnapshot<Map<String, dynamic>>
          selected =
          snapshot.docs.first;

      Map<String, dynamic>?
          firstData =
          selected.data();

      if (firstData == null) {
        await _clearIfNoActiveRequest();
        return;
      }

      int selectedPriority =
          _statusPriority(
        firstData['status'],
      );

      for (final DocumentSnapshot<
              Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic>?
            docData =
            doc.data();

        if (docData == null) {
          continue;
        }

        final int priority =
            _statusPriority(
          docData['status'],
        );

        if (priority > selectedPriority) {
          selected = doc;
          selectedPriority = priority;
        }
      }

      final Map<String, dynamic>?
          selectedData =
          selected.data();

      if (selectedData == null) {
        await _clearIfNoActiveRequest();
        return;
      }

      _activeWalkId =
          selected.id;

      _activeWalkData =
          Map<String, dynamic>.from(
        selectedData,
      );

      _activeSessionId =
          _firstNonEmpty(
        <dynamic>[
          selectedData['liveWalkSessionId'],
          selectedData['sessionId'],
        ],
      );

      await _startRequestListener();

      await _startOptionalActiveWalkListener();

      await _startSessionListener();

    } catch (_) {
      // Keep cached state on temporary Firebase errors.
    }
  }

  // ============================================================
  // REALTIME WALK REQUEST LISTENER
  // ============================================================

  Future<void> _startRequestListener() async {
    await _walkSubscription?.cancel();

    final User? user =
        _auth.currentUser;

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
      (snapshot) {
        DocumentSnapshot<Map<String, dynamic>>?
            selected;

        int bestPriority = 0;

        for (final DocumentSnapshot<
                Map<String, dynamic>> doc
            in snapshot.docs) {
          final Map<String, dynamic>?
              docData =
              doc.data();

          if (docData == null) {
            continue;
          }

          final int priority =
              _statusPriority(
            docData['status'],
          );

          if (priority > bestPriority ||
              (priority == bestPriority &&
                  doc.id == _activeWalkId)) {
            selected = doc;
            bestPriority = priority;
          }
        }

        if (selected == null) {
          unawaited(
            _clearIfNoActiveRequest(),
          );
          return;
        }

        final Map<String, dynamic>?
            selectedData =
            selected.data();

        if (selectedData == null) {
          return;
        }

        _activeWalkId =
            selected.id;

        _activeWalkData =
            Map<String, dynamic>.from(
          selectedData,
        );

        final String sessionId =
            _firstNonEmpty(
          <dynamic>[
            selectedData['liveWalkSessionId'],
            selectedData['sessionId'],
          ],
        );

        if (sessionId !=
            (_activeSessionId ?? '')) {
          _activeSessionId =
              sessionId.isEmpty
                  ? null
                  : sessionId;

          unawaited(
            _startSessionListener(),
          );
        }

        unawaited(
          _startOptionalActiveWalkListener(),
        );
      },
      onError: (_) {
        // Preserve cached state.
      },
    );
  }

  // ============================================================
  // OPTIONAL ACTIVE WALK
  // ============================================================

  Future<void>
      _startOptionalActiveWalkListener() async {
    final Map<String, dynamic>?
        currentData =
        _activeWalkData;

    if (currentData == null) {
      return;
    }

    final String activeWalkId =
        _firstNonEmpty(
      <dynamic>[
        currentData['activeWalkId'],
        currentData['active_walk_id'],
      ],
    );

    if (activeWalkId.isEmpty) {
      await _activeWalkSubscription?.cancel();

      _activeWalkSubscription = null;

      return;
    }

    await _activeWalkSubscription?.cancel();

    _activeWalkSubscription =
        _activeWalks
            .doc(activeWalkId)
            .snapshots()
            .listen(
      (snapshot) {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic>?
            activeData =
            snapshot.data();

        if (activeData == null) {
          return;
        }

        final Map<String, dynamic>
            baseData =
            _activeWalkData == null
                ? <String, dynamic>{}
                : Map<String, dynamic>.from(
                    _activeWalkData!,
                  );

        _activeWalkData = <String, dynamic>{
          ...baseData,
          ...activeData,
        };
      },
      onError: (_) {
        // Optional listener only.
      },
    );
  }

  // ============================================================
  // LIVE SESSION
  // ============================================================

  Future<void> _startSessionListener() async {
    await _sessionSubscription?.cancel();

    _sessionSubscription = null;

    final String? sessionId =
        _activeSessionId;

    if (sessionId == null ||
        sessionId.isEmpty) {
      _activeSessionData = null;
      return;
    }

    _sessionSubscription =
        _liveWalkSessions
            .doc(sessionId)
            .snapshots()
            .listen(
      (snapshot) {
        if (!snapshot.exists) {
          return;
        }

        final Map<String, dynamic>?
            data =
            snapshot.data();

        if (data == null) {
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
  // ============================================================

  void startWalkRequestMonitor() {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    _walkSubscription?.cancel();

    _walkSubscription =
        _walkRequests
            .where(
              'walkerUid',
              isEqualTo: user.uid,
            )
            .snapshots()
            .listen(
      (snapshot) {
        DocumentSnapshot<Map<String, dynamic>>?
            selected;

        int bestPriority = 0;

        for (final DocumentSnapshot<
                Map<String, dynamic>> doc
            in snapshot.docs) {
          final Map<String, dynamic>?
              docData =
              doc.data();

          if (docData == null) {
            continue;
          }

          final int priority =
              _statusPriority(
            docData['status'],
          );

          if (priority > bestPriority ||
              (priority == bestPriority &&
                  doc.id == _activeWalkId)) {
            selected = doc;
            bestPriority = priority;
          }
        }

        if (selected == null) {
          unawaited(
            _clearIfNoActiveRequest(),
          );
          return;
        }

        final Map<String, dynamic>?
            selectedData =
            selected.data();

        if (selectedData == null) {
          return;
        }

        _activeWalkId =
            selected.id;

        _activeWalkData =
            Map<String, dynamic>.from(
          selectedData,
        );

        final String sessionId =
            _firstNonEmpty(
          <dynamic>[
            selectedData['liveWalkSessionId'],
            selectedData['sessionId'],
          ],
        );

        if (sessionId !=
            (_activeSessionId ?? '')) {
          _activeSessionId =
              sessionId.isEmpty
                  ? null
                  : sessionId;

          unawaited(
            _startSessionListener(),
          );
        }

        unawaited(
          _startOptionalActiveWalkListener(),
        );
      },
      onError: (_) {
        // Preserve cached state.
      },
    );
  }

  // ============================================================
  // SET ACTIVE WALK
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

      await _startOptionalActiveWalkListener();

      await _startSessionListener();

    } catch (_) {
      // Preserve state.
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await recoverCurrentState();
  }

  // ============================================================
  // CLEAR
  // ============================================================

  Future<void>
      _clearIfNoActiveRequest() async {
    await _activeWalkSubscription?.cancel();
    await _sessionSubscription?.cancel();

    _activeWalkSubscription = null;
    _sessionSubscription = null;

    _activeWalkId = null;
    _activeSessionId = null;
    _activeWalkData = null;
    _activeSessionData = null;
  }

  Future<void> clearState() async {
    await _walkSubscription?.cancel();
    await _activeWalkSubscription?.cancel();
    await _sessionSubscription?.cancel();

    _walkSubscription = null;
    _activeWalkSubscription = null;
    _sessionSubscription = null;

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
    await _activeWalkSubscription?.cancel();
    await _sessionSubscription?.cancel();
    await _authSubscription?.cancel();

    _walkSubscription = null;
    _activeWalkSubscription = null;
    _sessionSubscription = null;
    _authSubscription = null;

    _activeWalkId = null;
    _activeSessionId = null;
    _activeWalkData = null;
    _activeSessionData = null;
  }

  // ============================================================
  // STATUS PRIORITY
  // ============================================================

  int _statusPriority(
    dynamic value,
  ) {
    final String status =
        _readString(value).toLowerCase();

    switch (status) {
      case 'live':
        return 4;

      case 'started':
        return 3;

      case 'active':
        return 2;

      case 'accepted':
        return 1;

      default:
        return 0;
    }
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
}
