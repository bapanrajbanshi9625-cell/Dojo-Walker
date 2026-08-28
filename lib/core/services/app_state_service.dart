// File: lib/core/services/app_state_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// DOJO WALKER - CENTRAL APP STATE SERVICE
/// ============================================================
///
/// Primary source:
///   walk_request
///
/// Optional:
///   active_walk
///   liveWalkSessions
///
/// ActiveWalkStrip के लिए accepted / active request
/// walk_request से सीधे recover होती है.
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
  // CURRENT USER
  // ============================================================

  User? get currentUser =>
      _auth.currentUser;

  String? get currentUid =>
      _auth.currentUser?.uid;

  // ============================================================
  // ACTIVE WALK CACHE
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
        startWalkRequestMonitor();
      },
    );

    final User? user =
        _auth.currentUser;

    if (user != null) {
      await recoverCurrentState();
      startWalkRequestMonitor();
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

      // --------------------------------------------------------
      // Select highest-priority active request.
      // --------------------------------------------------------

      DocumentSnapshot<Map<String, dynamic>>
          selected =
          snapshot.docs.first;

      int selectedPriority =
          _statusPriority(
        selected.data()['status'],
      );

      for (final DocumentSnapshot<
              Map<String, dynamic>> doc
          in snapshot.docs) {
        final Map<String, dynamic>
            data = doc.data();

        final int priority =
            _statusPriority(
          data['status'],
        );

        if (priority > selectedPriority) {
          selected = doc;
          selectedPriority = priority;
        }
      }

      // --------------------------------------------------------
      // SAFE NULL HANDLING
      // --------------------------------------------------------

      final Map<String, dynamic>?
          selectedData =
          selected.data();

      if (selectedData == null) {
        await _clearIfNoActiveRequest();
        return;
      }

      final Map<String, dynamic>
          data =
          Map<String, dynamic>.from(
        selectedData,
      );

      _activeWalkId =
          selected.id;

      _activeWalkData =
          data;

      _activeSessionId =
          _firstNonEmpty(
        <dynamic>[
          data['liveWalkSessionId'],
          data['sessionId'],
        ],
      );

      await _startRequestListener();

      await _startOptionalActiveWalkListener();

      await _startSessionListener();

    } catch (_) {
      // Temporary Firebase/network error.
      // Existing cached state is preserved.
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
        DocumentSnapshot<
                Map<String, dynamic>>?
            selected;

        int bestPriority = 0;

        for (final DocumentSnapshot<
                Map<String, dynamic>> doc
            in snapshot.docs) {
          final Map<String, dynamic>
              data = doc.data();

          final int priority =
              _statusPriority(
            data['status'],
          );

          if (priority > bestPriority ||
              (priority == bestPriority &&
                  doc.id == _activeWalkId)) {
            selected = doc;
            bestPriority = priority;
          }
        }

        if (selected == null) {
          _clearIfNoActiveRequest();
          return;
        }

        final Map<String, dynamic>?
            selectedData =
            selected.data();

        if (selectedData == null) {
          return;
        }

        final Map<String, dynamic>
            data =
            Map<String, dynamic>.from(
          selectedData,
        );

        _activeWalkId =
            selected.id;

        _activeWalkData =
            data;

        final String newSessionId =
            _firstNonEmpty(
          <dynamic>[
            data['liveWalkSessionId'],
            data['sessionId'],
          ],
        );

        if (newSessionId !=
            (_activeSessionId ?? '')) {
          _activeSessionId =
              newSessionId.isEmpty
                  ? null
                  : newSessionId;

          unawaited(
            _startSessionListener(),
          );
        }

        unawaited(
          _startOptionalActiveWalkListener(),
        );
      },
      onError: (_) {
        // Keep cached state.
      },
    );
  }

  // ============================================================
  // OPTIONAL ACTIVE WALK LISTENER
  // ============================================================

  Future<void>
      _startOptionalActiveWalkListener() async {
    final Map<String, dynamic>?
        data =
        _activeWalkData;

    if (data == null) {
      return;
    }

    final String activeWalkId =
        _firstNonEmpty(
      <dynamic>[
        data['activeWalkId'],
        data['active_walk_id'],
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
            currentData =
            _activeWalkData == null
                ? <String, dynamic>{}
                : Map<String, dynamic>.from(
                    _activeWalkData!,
                  );

        _activeWalkData = <String, dynamic>{
          ...currentData,
          ...activeData,
        };
      },
      onError: (_) {
        // Optional listener.
      },
    );
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

        final String status =
            _readString(
          data['status'],
        ).toLowerCase();

        if (status == 'completed' ||
            status == 'cancelled' ||
            status == 'ended') {
          _activeSessionData = null;
        }
      },
      onError: (_) {
        // Keep current state.
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
        DocumentSnapshot<
                Map<String, dynamic>>?
            selected;

        int bestPriority = 0;

        for (final DocumentSnapshot<
                Map<String, dynamic>> doc
            in snapshot.docs) {
          final Map<String, dynamic>
              data = doc.data();

          final int priority =
              _statusPriority(
            data['status'],
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

        final Map<String, dynamic>
            data =
            Map<String, dynamic>.from(
          selectedData,
        );

        _activeWalkId =
            selected.id;

        _activeWalkData =
            data;

        final String sessionId =
            _firstNonEmpty(
          <dynamic>[
            data['liveWalkSessionId'],
            data['sessionId'],
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
        // Keep cached state.
      },
    );
  }

  // ============================================================
  // MANUALLY SET ACTIVE WALK
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
      // Keep cached active state.
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> refresh() async {
    await recoverCurrentState();
  }

  // ============================================================
  // CLEAR WHEN NO ACTIVE REQUEST
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

  // ============================================================
  // CLEAR STATE
  // ============================================================

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
  // SAFE STRING
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
