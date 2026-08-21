// File:
// lib/features/walks/services/insta_walk_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../constants/walks_constants.dart';
import '../models/walk_request.dart';
import 'walk_request_sound_service.dart';

class InstaWalkService {
  InstaWalkService._();

  static final InstaWalkService instance =
      InstaWalkService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  Timer? _expiryTimer;

  bool _searching = false;

  DateTime? _searchStartedAt;

  String? _walkerId;

  final List<WalkRequest> _requests = [];

  // ============================================================
  // GETTERS
  // ============================================================

  bool get searching => _searching;

  String? get walkerId => _walkerId;

  List<WalkRequest> get requests =>
      List.unmodifiable(_requests);

  // ============================================================
  // START SEARCH
  // ============================================================

  Future<bool> startSearch() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    final String? walkerId =
        await _getWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      return false;
    }

    try {
      final DateTime startedAt =
          DateTime.now();

      final DateTime expiresAt =
          startedAt.add(
        const Duration(minutes: 2),
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'walkerId': walkerId,
          'instaWalkSearching': true,

          'instaWalkSearchRadiusKm':
              WalksConstants.searchRadiusKm,

          'instaWalkSearchStartedAt':
              Timestamp.fromDate(startedAt),

          'instaWalkSearchExpiresAt':
              Timestamp.fromDate(expiresAt),

          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      _walkerId = walkerId;
      _searchStartedAt = startedAt;
      _searching = true;

      _requests.clear();

      // Old sounds must never continue.
      await WalkRequestSoundService.instance
          .stopAll();

      _startRequestListener();

      _startExpiryTimer(expiresAt);

      return true;
    } catch (e) {
      print(
        'Start Insta Walk Error: $e',
      );

      return false;
    }
  }

  // ============================================================
  // RESTORE SEARCH
  //
  // App/screen वापस आने पर Firestore state check होगी.
  // ============================================================

  Future<void> restoreSearch() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      final data = snapshot.data();

      if (data == null) {
        return;
      }

      final bool searching =
          data['instaWalkSearching'] == true;

      if (!searching) {
        return;
      }

      DateTime? expiresAt;

      final dynamic rawExpiry =
          data['instaWalkSearchExpiresAt'];

      if (rawExpiry is Timestamp) {
        expiresAt = rawExpiry.toDate();
      }

      // ========================================================
      // SEARCH ALREADY EXPIRED
      // ========================================================

      if (expiresAt == null ||
          !expiresAt.isAfter(DateTime.now())) {
        await stopSearch();
        return;
      }

      final dynamic savedWalkerId =
          data['walkerId'];

      if (savedWalkerId != null) {
        _walkerId =
            savedWalkerId.toString().trim();
      }

      _searching = true;

      _startRequestListener();

      _startExpiryTimer(expiresAt);
    } catch (e) {
      print(
        'Restore Insta Walk Error: $e',
      );
    }
  }

  // ============================================================
  // REQUEST LISTENER
  // ============================================================

  void _startRequestListener() {
    _requestSubscription?.cancel();

    _requestSubscription =
        _firestore
            .collection('walk_requests')
            .where(
              'status',
              isEqualTo: 'searching',
            )
            .snapshots()
            .listen(
      _handleRequests,
      onError: (Object error) {
        print(
          'Insta Walk Request Listener Error: $error',
        );
      },
    );
  }

  // ============================================================
  // HANDLE REQUESTS
  // ============================================================

  void _handleRequests(
    QuerySnapshot<Map<String, dynamic>>
        snapshot,
  ) {
    if (!_searching) {
      return;
    }

    final List<WalkRequest> incoming = [];

    for (final document in snapshot.docs) {
      final data = document.data();

      final double distance =
          _readDistance(
        data['distanceKm'],
      );

      if (distance >
          WalksConstants.searchRadiusKm) {
        continue;
      }

      try {
        final request =
            WalkRequest.fromFirestore(
          document,
        );

        incoming.add(request);
      } catch (e) {
        print(
          'Walk Request Parse Error: $e',
        );
      }
    }

    incoming.sort(
      (a, b) =>
          a.distanceKm.compareTo(
        b.distanceKm,
      ),
    );

    final Set<String> incomingIds =
        incoming
            .map((request) => request.id)
            .toSet();

    // ==========================================================
    // NEW REQUEST SOUND
    // ==========================================================

    for (final request in incoming) {
      final bool alreadyExists =
          _requests.any(
        (oldRequest) =>
            oldRequest.id == request.id,
      );

      if (!alreadyExists) {
        WalkRequestSoundService.instance
            .playForRequest(
          request.id,
        );
      }
    }

    // ==========================================================
    // REMOVED REQUEST SOUND
    // ==========================================================

    for (final oldRequest
        in List<WalkRequest>.from(_requests)) {
      if (!incomingIds.contains(
        oldRequest.id,
      )) {
        WalkRequestSoundService.instance
            .stopRequest(
          oldRequest.id,
        );
      }
    }

    _requests
      ..clear()
      ..addAll(incoming);
  }

  // ============================================================
  // STOP SEARCH
  // ============================================================

  Future<void> stopSearch() async {
    final User? user = _auth.currentUser;

    _searching = false;

    _expiryTimer?.cancel();
    _expiryTimer = null;

    await _requestSubscription?.cancel();
    _requestSubscription = null;

    await WalkRequestSoundService.instance
        .stopAll();

    _requests.clear();

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(
          {
            'instaWalkSearching': false,
            'instaWalkSearchUpdatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        print(
          'Stop Insta Walk Firestore Error: $e',
        );
      }
    }
  }

  // ============================================================
  // 2 MINUTE EXPIRY
  // ============================================================

  void _startExpiryTimer(
    DateTime expiresAt,
  ) {
    _expiryTimer?.cancel();

    final Duration remaining =
        expiresAt.difference(
      DateTime.now(),
    );

    if (remaining.isNegative ||
        remaining == Duration.zero) {
      stopSearch();
      return;
    }

    _expiryTimer = Timer(
      remaining,
      () async {
        await stopSearch();
      },
    );
  }

  // ============================================================
  // GET WALKER ID
  // ============================================================

  Future<String?> _getWalkerId() async {
    if (_walkerId != null &&
        _walkerId!.trim().isNotEmpty) {
      return _walkerId;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return null;
    }

    try {
      final snapshot =
          await _firestore
              .collection('phoneAccounts')
              .doc(user.uid)
              .get();

      final data = snapshot.data();

      final dynamic value =
          data?['walkerId'];

      if (value != null) {
        final String id =
            value.toString().trim();

        if (id.isNotEmpty) {
          _walkerId = id;
          return id;
        }
      }
    } catch (e) {
      print(
        'Walker ID Load Error: $e',
      );
    }

    return null;
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  double _readDistance(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        999;
  }

  // ============================================================
  // RESET
  // ============================================================

  Future<void> disposeService() async {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    await _requestSubscription?.cancel();
    _requestSubscription = null;

    await WalkRequestSoundService.instance
        .stopAll();

    _requests.clear();

    _searching = false;
  }
}
