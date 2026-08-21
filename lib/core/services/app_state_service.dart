// File location: lib/core/services/app_state_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ============================================================
/// DOJO WALKER - CENTRAL APP STATE SERVICE
/// ============================================================
///
/// यह service app के important runtime state को centralize करती है।
///
/// इसका उद्देश्य:
///
/// 1. Current Firebase user को track करना
/// 2. Current active walk को Firebase से recover करना
/// 3. App बंद / restart होने के बाद active walk पहचानना
/// 4. Logout/login के बाद current Firebase data से state recover करना
/// 5. Network वापस आने पर Firebase listener अपने आप continue करना
///
/// IMPORTANT:
/// यह service ringtone / UI / navigation को change नहीं करती।
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
          _firestore.collection('walk_requests');

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
      _activeWalkId != null;

  // ============================================================
  // STREAM SUBSCRIPTIONS
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
  // START
  // ============================================================

  Future<void> initialize() async {
    // ----------------------------------------------------------
    // AUTH LISTENER
    // ----------------------------------------------------------

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

    // ----------------------------------------------------------
    // CURRENT USER ALREADY AVAILABLE
    // ----------------------------------------------------------

    if (_auth.currentUser != null) {
      await recoverCurrentState();
    }
  }

  // ============================================================
  // RECOVER CURRENT STATE
  // ============================================================
  //
  // Firebase is the source of truth.
  //
  // App memory is only a temporary cache.
  //
  // इसलिए:
  //
  // App restart
  // Mobile restart
  // Login again
  //
  // के बाद Firebase से state दोबारा मिल सकती है।
  // ============================================================

  Future<void> recoverCurrentState() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      await clearState();
      return;
    }

    try {
      // --------------------------------------------------------
      // Find active/accepted walks belonging to this walker.
      // --------------------------------------------------------

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
                ],
              )
              .get();

      // --------------------------------------------------------
      // No active walk
      // --------------------------------------------------------

      if (snapshot.docs.isEmpty) {
        await _cancelWalkListeners();

        _activeWalkId = null;
        _activeSessionId = null;
        _activeWalkData = null;
        _activeSessionData = null;

        return;
      }

      // --------------------------------------------------------
      // Prefer ACTIVE walk.
      // --------------------------------------------------------

      DocumentSnapshot<Map<String, dynamic>> selected =
          snapshot.docs.first;

      for (final doc in snapshot.docs) {
        final data =
            doc.data();

        if (data['status'] == 'active') {
          selected = doc;
          break;
        }
      }

      final Map<String, dynamic> walkData =
          selected.data();

      _activeWalkId =
          selected.id;

      _activeWalkData =
          Map<String, dynamic>.from(
        walkData,
      );

      _activeSessionId =
          _readString(
        walkData['liveWalkSessionId'],
      );

      // --------------------------------------------------------
      // Start realtime listeners.
      // --------------------------------------------------------

      await _startActiveWalkListeners();

    } catch (e) {
      // --------------------------------------------------------
      // IMPORTANT:
      //
      // Firebase offline cache / temporary network issue
      // should NOT destroy local runtime state.
      // --------------------------------------------------------

      // State को intentionally clear नहीं कर रहे।
      //
      // Firebase reconnect होने पर listener फिर update करेगा।
    }
  }

  // ============================================================
  // START ACTIVE WALK LISTENERS
  // ============================================================

  Future<void>
      _startActiveWalkListeners() async {
    final String? walkId =
        _activeWalkId;

    if (walkId == null ||
        walkId.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // Cancel old listeners
    // ----------------------------------------------------------

    await _activeWalkSubscription?.cancel();

    await _sessionSubscription?.cancel();

    // ----------------------------------------------------------
    // ACTIVE WALK
    // ----------------------------------------------------------

    _activeWalkSubscription =
        _activeWalks
            .doc(walkId)
            .snapshots()
            .listen(
      (snapshot) {
        if (!snapshot.exists) {
          return;
        }

        final data =
            snapshot.data();

        if (data == null) {
          return;
        }

        _activeWalkData =
            Map<String, dynamic>.from(
          data,
        );
      },
    );

    // ----------------------------------------------------------
    // LIVE SESSION
    // ----------------------------------------------------------

    final String? sessionId =
        _activeSessionId;

    if (sessionId == null ||
        sessionId.isEmpty) {
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

        final data =
            snapshot.data();

        if (data == null) {
          return;
        }

        _activeSessionData =
            Map<String, dynamic>.from(
          data,
        );

        // ------------------------------------------------------
        // If Firebase says walk is completed,
        // remove active runtime state.
        // ------------------------------------------------------

        final String status =
            _readString(
          data['status'],
        ).toUpperCase();

        if (status == 'COMPLETED') {
          _clearActiveWalkOnly();
        }
      },
    );
  }

  // ============================================================
  // WATCH ALL WALK REQUESTS
  // ============================================================
  //
  // यह listener केवल current walker के requests को monitor
  // करने के लिए है।
  //
  // Ringtone यहां नहीं है।
  //
  // Existing ringtone system untouched रहेगा।
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
      (_) {
        // ------------------------------------------------------
        // Intentionally empty.
        //
        // Existing WalkRequestService / ringtone system
        // अपना काम करेगा.
        // ------------------------------------------------------
      },
    );
  }

  // ============================================================
  // MANUALLY SET ACTIVE WALK
  // ============================================================
  //
  // accept/start flow के बाद इसे call किया जा सकता है।
  // ============================================================

  Future<void> setActiveWalk({
    required String walkId,
    String? sessionId,
  }) async {
    _activeWalkId =
        walkId;

    _activeSessionId =
        sessionId;

    try {
      final DocumentSnapshot<
              Map<String, dynamic>>
          walkSnapshot =
          await _walkRequests
              .doc(walkId)
              .get();

      if (walkSnapshot.exists) {
        _activeWalkData =
            walkSnapshot.data();
      }

      final String resolvedSessionId =
          sessionId ??
              _readString(
                _activeWalkData?[
                    'liveWalkSessionId'],
              );

      if (resolvedSessionId.isNotEmpty) {
        _activeSessionId =
            resolvedSessionId;

        final DocumentSnapshot<
                Map<String, dynamic>>
            sessionSnapshot =
            await _liveWalkSessions
                .doc(
                  resolvedSessionId,
                )
                .get();

        if (sessionSnapshot.exists) {
          _activeSessionData =
              sessionSnapshot.data();
        }
      }

      await _startActiveWalkListeners();

    } catch (_) {
      // Do not destroy active state on temporary Firebase error.
    }
  }

  // ============================================================
  // REFRESH FROM FIREBASE
  // ============================================================

  Future<void> refresh() async {
    await recoverCurrentState();
  }

  // ============================================================
  // CLEAR ACTIVE WALK ONLY
  // ============================================================

  void _clearActiveWalkOnly() {
    _activeWalkId = null;
    _activeSessionId = null;
    _activeWalkData = null;
    _activeSessionData = null;
  }

  // ============================================================
  // CLEAR STATE
  // ============================================================

  Future<void> clearState() async {
    await _activeWalkSubscription?.cancel();
    await _sessionSubscription?.cancel();

    _activeWalkSubscription = null;
    _sessionSubscription = null;

    _clearActiveWalkOnly();
  }

  // ============================================================
  // CANCEL WALK LISTENERS
  // ============================================================

  Future<void> _cancelWalkListeners() async {
    await _activeWalkSubscription?.cancel();
    await _sessionSubscription?.cancel();

    _activeWalkSubscription = null;
    _sessionSubscription = null;
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
}
