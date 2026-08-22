// File:
// lib/features/walks/services/insta_walk_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/walks_constants.dart';
import '../models/walk_request.dart';
import 'walk_request_sound_service.dart';
import 'walker_location_service.dart';

class InstaWalkService {
  InstaWalkService._();

  static final InstaWalkService instance =
      InstaWalkService._();

  // ============================================================
  // FIREBASE
  // ============================================================

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ============================================================
  // LOCATION
  // ============================================================

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  StreamSubscription<Position>? _locationSubscription;

  // ============================================================
  // REQUEST LISTENER
  // ============================================================

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  // ============================================================
  // TIMER
  // ============================================================

  Timer? _expiryTimer;

  // ============================================================
  // SEARCH STATE
  // ============================================================

  bool _searching = false;

  String? _walkerId;

  Position? _currentPosition;

  DateTime? _lastActivityAt;

  final List<WalkRequest> _requests = [];

  // ============================================================
  // GETTERS
  // ============================================================

  bool get searching => _searching;

  String? get walkerId => _walkerId;

  Position? get currentPosition => _currentPosition;

  List<WalkRequest> get requests =>
      List.unmodifiable(_requests);

  DateTime? get lastActivityAt => _lastActivityAt;

  // ============================================================
  // START SEARCH
  // ============================================================

  Future<bool> startSearch() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return false;
    }

    // ----------------------------------------------------------
    // WALKER ID
    // ----------------------------------------------------------

    final String? walkerId =
        await _getWalkerId();

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      return false;
    }

    // ----------------------------------------------------------
    // REAL GPS
    // ----------------------------------------------------------

    final Position? position =
        await _locationService.getCurrentLocation();

    if (position == null) {
      debugPrint(
        'Insta Walk: current GPS unavailable.',
      );

      return false;
    }

    try {
      final DateTime now = DateTime.now();

      _walkerId = walkerId;
      _currentPosition = position;

      _searching = true;

      _requests.clear();

      _lastActivityAt = now;

      // --------------------------------------------------------
      // SAVE PERSISTENT SEARCH STATE
      // --------------------------------------------------------

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
              Timestamp.fromDate(now),

          'instaWalkSearchLastActivityAt':
              Timestamp.fromDate(now),

          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),

          'instaWalkSearchLatitude':
              position.latitude,

          'instaWalkSearchLongitude':
              position.longitude,
        },
        SetOptions(merge: true),
      );

      // --------------------------------------------------------
      // STOP OLD SOUND
      // --------------------------------------------------------

      await WalkRequestSoundService.instance
          .stopAll();

      // --------------------------------------------------------
      // START GPS
      // --------------------------------------------------------

      await _startLocationListener();

      // --------------------------------------------------------
      // START FIRESTORE REQUEST LISTENER
      // --------------------------------------------------------

      _startRequestListener();

      // --------------------------------------------------------
      // START 2 HOUR INACTIVITY TIMER
      // --------------------------------------------------------

      _startInactivityTimer(
        _lastActivityAt!,
      );

      return true;
    } catch (e) {
      debugPrint(
        'Start Insta Walk Error: $e',
      );

      _searching = false;

      return false;
    }
  }

  // ============================================================
  // RESTORE SEARCH
  // ============================================================

  Future<void> restoreSearch() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic>? data =
          snapshot.data();

      if (data == null) {
        return;
      }

      final bool searching =
          data['instaWalkSearching'] == true;

      if (!searching) {
        return;
      }

      // --------------------------------------------------------
      // RESTORE LAST ACTIVITY
      // --------------------------------------------------------

      DateTime? lastActivityAt;

      final dynamic rawActivity =
          data['instaWalkSearchLastActivityAt'];

      if (rawActivity is Timestamp) {
        lastActivityAt =
            rawActivity.toDate();
      }

      // Backward compatibility
      if (lastActivityAt == null) {
        final dynamic rawStarted =
            data['instaWalkSearchStartedAt'];

        if (rawStarted is Timestamp) {
          lastActivityAt =
              rawStarted.toDate();
        }
      }

      if (lastActivityAt == null) {
        await stopSearch();
        return;
      }

      // --------------------------------------------------------
      // 2 HOUR IDLE CHECK
      // --------------------------------------------------------

      final Duration idle =
          DateTime.now()
              .difference(lastActivityAt);

      if (idle >=
          const Duration(hours: 2)) {
        await stopSearch();
        return;
      }

      // --------------------------------------------------------
      // RESTORE WALKER ID
      // --------------------------------------------------------

      final dynamic savedWalkerId =
          data['walkerId'];

      if (savedWalkerId != null) {
        final String id =
            savedWalkerId.toString().trim();

        if (id.isNotEmpty) {
          _walkerId = id;
        }
      }

      if (_walkerId == null ||
          _walkerId!.isEmpty) {
        _walkerId =
            await _getWalkerId();
      }

      if (_walkerId == null ||
          _walkerId!.isEmpty) {
        await stopSearch();
        return;
      }

      // --------------------------------------------------------
      // GET REAL GPS AGAIN
      // --------------------------------------------------------

      final Position? position =
          await _locationService
              .getCurrentLocation();

      if (position == null) {
        // Keep persistent search state.
        // GPS can reconnect later.
        _searching = true;
        _lastActivityAt =
            lastActivityAt;

        _startRequestListener();

        _startInactivityTimer(
          lastActivityAt,
        );

        return;
      }

      _currentPosition = position;

      _searching = true;

      _lastActivityAt =
          lastActivityAt;

      // --------------------------------------------------------
      // START GPS
      // --------------------------------------------------------

      await _startLocationListener();

      // --------------------------------------------------------
      // START REQUEST LISTENER
      // --------------------------------------------------------

      _startRequestListener();

      // --------------------------------------------------------
      // RESTORE TIMER
      // --------------------------------------------------------

      _startInactivityTimer(
        lastActivityAt,
      );
    } catch (e) {
      debugPrint(
        'Restore Insta Walk Error: $e',
      );
    }
  }

  // ============================================================
  // GPS LISTENER
  // ============================================================

  Future<void> _startLocationListener() async {
    if (!_searching) {
      return;
    }

    await _locationSubscription?.cancel();

    final bool started =
        await _locationService
            .startTracking();

    if (!started) {
      debugPrint(
        'Insta Walk: GPS tracking could not start.',
      );

      return;
    }

    _locationSubscription =
        _locationService.locationStream.listen(
      (Position position) {
        if (!_searching) {
          return;
        }

        _currentPosition = position;

        // ------------------------------------------------------
        // REAL GPS UPDATE
        // ------------------------------------------------------

        _handleRequests(
          _lastSnapshot,
        );
      },
      onError: (Object error) {
        debugPrint(
          'Insta Walk GPS Error: $error',
        );
      },
    );
  }

  // ============================================================
  // LAST FIRESTORE SNAPSHOT
  // ============================================================

  QuerySnapshot<Map<String, dynamic>>?
      _lastSnapshot;

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
      (QuerySnapshot<Map<String, dynamic>>
          snapshot) {
        if (!_searching) {
          return;
        }

        _lastSnapshot = snapshot;

        _handleRequests(snapshot);
      },
      onError: (Object error) {
        debugPrint(
          'Insta Walk Request Listener Error: $error',
        );

        // IMPORTANT:
        // Do NOT stop search on network error.
      },
    );
  }

  // ============================================================
  // HANDLE REQUESTS
  // ============================================================

  void _handleRequests(
    QuerySnapshot<Map<String, dynamic>>?
        snapshot,
  ) {
    if (!_searching ||
        snapshot == null) {
      return;
    }

    final Position? position =
        _currentPosition;

    if (position == null) {
      return;
    }

    final List<WalkRequest> incoming =
        [];

    // ==========================================================
    // READ REQUESTS
    // ==========================================================

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>> document
        in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      // --------------------------------------------------------
      // WALK TYPE
      // --------------------------------------------------------

      final String walkType =
          data['walkType']
                  ?.toString()
                  .trim()
                  .toLowerCase() ??
              '';

      if (walkType.isNotEmpty &&
          walkType != 'insta walk' &&
          walkType != 'instawalk') {
        continue;
      }

      // --------------------------------------------------------
      // WALKER ALREADY ASSIGNED
      // --------------------------------------------------------

      final String assignedWalker =
          data['walkerId']
                  ?.toString()
                  .trim() ??
              '';

      if (assignedWalker.isNotEmpty) {
        continue;
      }

      // --------------------------------------------------------
      // PICKUP LOCATION
      // --------------------------------------------------------

      final double pickupLat =
          _readDouble(
        data['pickupLat'],
      );

      final double pickupLng =
          _readDouble(
        data['pickupLng'],
      );

      if (pickupLat == 0 ||
          pickupLng == 0) {
        continue;
      }

      // --------------------------------------------------------
      // REAL GPS DISTANCE
      // --------------------------------------------------------

      final double distanceKm =
          _locationService.distanceInKm(
        walkerLatitude:
            position.latitude,
        walkerLongitude:
            position.longitude,
        requestLatitude:
            pickupLat,
        requestLongitude:
            pickupLng,
      );

      // --------------------------------------------------------
      // 3.5 KM FILTER
      // --------------------------------------------------------

      if (distanceKm >
          WalksConstants.searchRadiusKm) {
        continue;
      }

      // --------------------------------------------------------
      // MODEL
      // --------------------------------------------------------

      try {
        final WalkRequest request =
            WalkRequest.fromFirestore(
          document,
        );

        incoming.add(
          request,
        );
      } catch (e) {
        debugPrint(
          'Walk Request Parse Error: $e',
        );
      }
    }

    // ==========================================================
    // SORT BY REAL GPS DISTANCE
    // ==========================================================

    incoming.sort(
      (a, b) {
        final double distanceA =
            _locationService.distanceInKm(
          walkerLatitude:
              position.latitude,
          walkerLongitude:
              position.longitude,
          requestLatitude:
              a.pickupLat,
          requestLongitude:
              a.pickupLng,
        );

        final double distanceB =
            _locationService.distanceInKm(
          walkerLatitude:
              position.latitude,
          walkerLongitude:
              position.longitude,
          requestLatitude:
              b.pickupLat,
          requestLongitude:
              b.pickupLng,
        );

        return distanceA.compareTo(
          distanceB,
        );
      },
    );

    // ==========================================================
    // ACTIVITY DETECTION
    // ==========================================================

    final Set<String> incomingIds =
        incoming
            .map(
              (request) => request.id,
            )
            .toSet();

    final Set<String> oldIds =
        _requests
            .map(
              (request) => request.id,
            )
            .toSet();

    final bool requestActivity =
        incomingIds.length !=
            oldIds.length ||
        incomingIds.difference(
          oldIds,
        ).isNotEmpty ||
        oldIds.difference(
          incomingIds,
        ).isNotEmpty;

    if (requestActivity) {
      _markActivity();
    }

    // ==========================================================
    // NEW REQUEST SOUND
    // ==========================================================

    for (final WalkRequest request
        in incoming) {
      final bool alreadyExists =
          _requests.any(
        (oldRequest) =>
            oldRequest.id ==
            request.id,
      );

      if (!alreadyExists) {
        WalkRequestSoundService
            .instance
            .playForRequest(
          request.id,
        );
      }
    }

    // ==========================================================
    // REMOVED REQUEST SOUND
    // ==========================================================

    for (final WalkRequest oldRequest
        in List<WalkRequest>.from(
      _requests,
    )) {
      if (!incomingIds.contains(
        oldRequest.id,
      )) {
        WalkRequestSoundService
            .instance
            .stopRequest(
          oldRequest.id,
        );
      }
    }

    // ==========================================================
    // UPDATE
    // ==========================================================

    _requests
      ..clear()
      ..addAll(incoming);
  }

  // ============================================================
  // MARK ACTIVITY
  // ============================================================

  void _markActivity() {
    if (!_searching) {
      return;
    }

    final DateTime now =
        DateTime.now();

    _lastActivityAt = now;

    _startInactivityTimer(now);

    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    // Fire-and-forget.
    _firestore
        .collection('users')
        .doc(user.uid)
        .set(
      {
        'instaWalkSearchLastActivityAt':
            Timestamp.fromDate(now),
        'instaWalkSearchUpdatedAt':
            FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    )
        .catchError(
      (Object error) {
        debugPrint(
          'Insta Walk Activity Save Error: $error',
        );
      },
    );
  }

  // ============================================================
  // 2 HOUR INACTIVITY TIMER
  // ============================================================

  void _startInactivityTimer(
    DateTime lastActivity,
  ) {
    _expiryTimer?.cancel();

    final Duration elapsed =
        DateTime.now()
            .difference(lastActivity);

    final Duration maximumIdle =
        const Duration(hours: 2);

    final Duration remaining =
        maximumIdle - elapsed;

    if (remaining <= Duration.zero) {
      stopSearch();
      return;
    }

    _expiryTimer = Timer(
      remaining,
      () async {
        if (!_searching) {
          return;
        }

        final DateTime? latest =
            _lastActivityAt;

        if (latest == null) {
          await stopSearch();
          return;
        }

        final Duration idle =
            DateTime.now()
                .difference(latest);

        if (idle >= maximumIdle) {
          await stopSearch();
        } else {
          _startInactivityTimer(
            latest,
          );
        }
      },
    );
  }

  // ============================================================
  // STOP SEARCH
  // ============================================================

  Future<void> stopSearch() async {
    final User? user =
        _auth.currentUser;

    _searching = false;

    // ----------------------------------------------------------
    // TIMER
    // ----------------------------------------------------------

    _expiryTimer?.cancel();
    _expiryTimer = null;

    // ----------------------------------------------------------
    // GPS
    // ----------------------------------------------------------

    await _locationSubscription
        ?.cancel();

    _locationSubscription = null;

    await _locationService
        .stopTracking();

    // ----------------------------------------------------------
    // FIRESTORE LISTENER
    // ----------------------------------------------------------

    await _requestSubscription
        ?.cancel();

    _requestSubscription = null;

    _lastSnapshot = null;

    // ----------------------------------------------------------
    // SOUND
    // ----------------------------------------------------------

    await WalkRequestSoundService
        .instance
        .stopAll();

    // ----------------------------------------------------------
    // REQUESTS
    // ----------------------------------------------------------

    _requests.clear();

    _lastActivityAt = null;

    // ----------------------------------------------------------
    // FIRESTORE STATE
    // ----------------------------------------------------------

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
        debugPrint(
          'Stop Insta Walk Firestore Error: $e',
        );
      }
    }
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
      final DocumentSnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection('phoneAccounts')
              .doc(user.uid)
              .get();

      final Map<String, dynamic>? data =
          snapshot.data();

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
      debugPrint(
        'Walker ID Load Error: $e',
      );
    }

    return null;
  }

  // ============================================================
  // SAFE DOUBLE
  // ============================================================

  double _readDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString().trim() ??
              '',
        ) ??
        0.0;
  }

  // ============================================================
  // DISPOSE SERVICE
  // ============================================================

  Future<void> disposeService() async {
    await _expiryTimer?.cancel();

    _expiryTimer = null;

    await _requestSubscription
        ?.cancel();

    _requestSubscription = null;

    await _locationSubscription
        ?.cancel();

    _locationSubscription = null;

    await _locationService
        .stopTracking();

    await WalkRequestSoundService
        .instance
        .stopAll();

    _requests.clear();

    _lastSnapshot = null;

    _lastActivityAt = null;

    _searching = false;
  }
}
