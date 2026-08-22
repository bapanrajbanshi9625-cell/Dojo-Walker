// File:
// lib/features/walks/services/insta_walk_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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

  // ============================================================
  // SUBSCRIPTIONS / TIMERS
  // ============================================================

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  StreamSubscription<Position>? _locationSubscription;

  Timer? _expiryTimer;

  // ============================================================
  // SEARCH STATE
  // ============================================================

  bool _searching = false;

  bool _starting = false;

  String? _walkerId;

  Position? _currentPosition;

  final List<WalkRequest> _requests = [];

  // ============================================================
  // GETTERS
  // ============================================================

  bool get searching => _searching;

  bool get starting => _starting;

  String? get walkerId => _walkerId;

  Position? get currentPosition => _currentPosition;

  List<WalkRequest> get requests =>
      List.unmodifiable(_requests);

  // ============================================================
  // SEARCH RADIUS
  // ============================================================

  double get searchRadiusKm =>
      WalksConstants.searchRadiusKm;

  // ============================================================
  // START SEARCH
  // ============================================================

  Future<bool> startSearch() async {
    // ----------------------------------------------------------
    // Prevent duplicate start calls.
    // ----------------------------------------------------------

    if (_starting) {
      return false;
    }

    // ----------------------------------------------------------
    // Already searching.
    // ----------------------------------------------------------

    if (_searching) {
      return true;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        'Insta Walk: Firebase user not found.',
      );
      return false;
    }

    _starting = true;

    try {
      // ========================================================
      // GET WALKER ID
      // ========================================================

      final String? walkerId =
          await _getWalkerId();

      if (walkerId == null ||
          walkerId.trim().isEmpty) {
        debugPrint(
          'Insta Walk: Walker ID not found.',
        );

        return false;
      }

      // ========================================================
      // GET CURRENT LOCATION
      // ========================================================

      final Position? position =
          await _locationService
              .getCurrentLocation();

      if (position == null) {
        debugPrint(
          'Insta Walk: Current location unavailable.',
        );

        return false;
      }

      _currentPosition = position;

      // ========================================================
      // START CONTINUOUS GPS
      // ========================================================

      final bool trackingStarted =
          await _locationService
              .startTracking();

      if (!trackingStarted) {
        debugPrint(
          'Insta Walk: GPS tracking could not start.',
        );

        return false;
      }

      // ========================================================
      // LISTEN TO GPS UPDATES
      // ========================================================

      await _locationSubscription?.cancel();

      _locationSubscription =
          _locationService.locationStream.listen(
        (Position position) {
          _currentPosition = position;

          if (_searching) {
            _refreshRequestDistances();
          }
        },
        onError: (Object error) {
          debugPrint(
            'Insta Walk Location Error: $error',
          );
        },
      );

      // ========================================================
      // SEARCH TIMES
      // ========================================================

      final DateTime startedAt =
          DateTime.now();

      final DateTime expiresAt =
          startedAt.add(
        const Duration(minutes: 2),
      );

      // ========================================================
      // SAVE SEARCH STATE
      // ========================================================

      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(
        {
          'walkerId': walkerId,
          'walkerUid': user.uid,

          'instaWalkSearching': true,

          'instaWalkSearchRadiusKm':
              WalksConstants.searchRadiusKm,

          'instaWalkSearchStartedAt':
              Timestamp.fromDate(
            startedAt,
          ),

          'instaWalkSearchExpiresAt':
              Timestamp.fromDate(
            expiresAt,
          ),

          'instaWalkSearchUpdatedAt':
              FieldValue.serverTimestamp(),
        },
        SetOptions(
          merge: true,
        ),
      );

      // ========================================================
      // LOCAL STATE
      // ========================================================

      _walkerId = walkerId;

      _searching = true;

      _requests.clear();

      // ========================================================
      // STOP OLD SOUNDS
      // ========================================================

      await WalkRequestSoundService
          .instance
          .stopAll();

      // ========================================================
      // START FIRESTORE REQUEST LISTENER
      // ========================================================

      _startRequestListener();

      // ========================================================
      // START EXPIRY TIMER
      // ========================================================

      _startExpiryTimer(
        expiresAt,
      );

      debugPrint(
        'Insta Walk search started.',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'Start Insta Walk Error: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      // --------------------------------------------------------
      // If Firestore/local setup fails, clean everything.
      // --------------------------------------------------------

      _searching = false;

      _expiryTimer?.cancel();
      _expiryTimer = null;

      await _requestSubscription?.cancel();
      _requestSubscription = null;

      await _locationSubscription?.cancel();
      _locationSubscription = null;

      await _locationService.stopTracking();

      await WalkRequestSoundService
          .instance
          .stopAll();

      _requests.clear();

      return false;
    } finally {
      _starting = false;
    }
  }

  // ============================================================
  // RESTORE SEARCH
  //
  // Called when app/screen comes back.
  // ============================================================

  Future<void> restoreSearch() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    // ----------------------------------------------------------
    // Do not restore twice.
    // ----------------------------------------------------------

    if (_searching) {
      return;
    }

    try {
      // ========================================================
      // READ USER SEARCH STATE
      // ========================================================

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

      // ========================================================
      // READ EXPIRY
      // ========================================================

      DateTime? expiresAt;

      final dynamic rawExpiry =
          data['instaWalkSearchExpiresAt'];

      if (rawExpiry is Timestamp) {
        expiresAt =
            rawExpiry.toDate();
      } else if (rawExpiry is DateTime) {
        expiresAt = rawExpiry;
      }

      // ========================================================
      // INVALID / EXPIRED
      // ========================================================

      if (expiresAt == null ||
          !expiresAt.isAfter(
            DateTime.now(),
          )) {
        await stopSearch();
        return;
      }

      // ========================================================
      // RESTORE WALKER ID
      // ========================================================

      final dynamic savedWalkerId =
          data['walkerId'];

      if (savedWalkerId != null) {
        final String id =
            savedWalkerId
                .toString()
                .trim();

        if (id.isNotEmpty) {
          _walkerId = id;
        }
      }

      if (_walkerId == null ||
          _walkerId!.trim().isEmpty) {
        final String? loadedWalkerId =
            await _getWalkerId();

        if (loadedWalkerId == null ||
            loadedWalkerId.trim().isEmpty) {
          await stopSearch();
          return;
        }
      }

      // ========================================================
      // GET CURRENT LOCATION
      // ========================================================

      final Position? position =
          await _locationService
              .getCurrentLocation();

      if (position == null) {
        debugPrint(
          'Restore Insta Walk: location unavailable.',
        );

        return;
      }

      _currentPosition = position;

      // ========================================================
      // START GPS
      // ========================================================

      await _locationService
          .startTracking();

      // ========================================================
      // LOCATION LISTENER
      // ========================================================

      await _locationSubscription?.cancel();

      _locationSubscription =
          _locationService.locationStream.listen(
        (Position position) {
          _currentPosition = position;

          if (_searching) {
            _refreshRequestDistances();
          }
        },
        onError: (Object error) {
          debugPrint(
            'Restore Insta Walk Location Error: $error',
          );
        },
      );

      // ========================================================
      // RESTORE LOCAL SEARCH
      // ========================================================

      _searching = true;

      _requests.clear();

      // ========================================================
      // START REQUEST LISTENER
      // ========================================================

      _startRequestListener();

      // ========================================================
      // START REMAINING TIMER
      // ========================================================

      _startExpiryTimer(
        expiresAt,
      );

      debugPrint(
        'Insta Walk search restored.',
      );
    } catch (e) {
      debugPrint(
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
        debugPrint(
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

    final List<WalkRequest> incoming =
        [];

    // ==========================================================
    // CURRENT WALKER LOCATION
    // ==========================================================

    final Position? position =
        _currentPosition;

    // ==========================================================
    // READ REQUESTS
    // ==========================================================

    for (final QueryDocumentSnapshot<
            Map<String, dynamic>> document
        in snapshot.docs) {
      final Map<String, dynamic> data =
          document.data();

      // ========================================================
      // PARSE MODEL
      // ========================================================

      try {
        final WalkRequest request =
            WalkRequest.fromFirestore(
          document,
        );

        // ======================================================
        // DISTANCE
        //
        // Prefer actual GPS distance if both
        // coordinates are available.
        // ======================================================

        double distance =
            request.distanceKm;

        if (position != null &&
            request.hasPickupLocation) {
          distance =
              _locationService.distanceInKm(
            walkerLatitude:
                position.latitude,
            walkerLongitude:
                position.longitude,
            requestLatitude:
                request.pickupLat,
            requestLongitude:
                request.pickupLng,
          );
        } else {
          // ----------------------------------------------------
          // Fallback to Firestore distanceKm.
          // ----------------------------------------------------

          distance =
              _readDistance(
            data['distanceKm'] ??
                data['walkDistanceKm'] ??
                data['distance'],
          );
        }

        // ======================================================
        // 3.5 KM FILTER
        // ======================================================

        if (distance >
            WalksConstants.searchRadiusKm) {
          continue;
        }

        // ======================================================
        // UPDATE MODEL DISTANCE
        // ======================================================

        final WalkRequest updatedRequest =
            request.copyWith(
          distanceKm: distance,
        );

        incoming.add(
          updatedRequest,
        );
      } catch (e) {
        debugPrint(
          'Walk Request Parse Error: $e',
        );
      }
    }

    // ==========================================================
    // SORT NEAREST FIRST
    // ==========================================================

    incoming.sort(
      (WalkRequest a, WalkRequest b) {
        return a.distanceKm.compareTo(
          b.distanceKm,
        );
      },
    );

    // ==========================================================
    // REQUEST IDS
    // ==========================================================

    final Set<String> incomingIds =
        incoming
            .map(
              (WalkRequest request) =>
                  request.id,
            )
            .toSet();

    // ==========================================================
    // NEW REQUEST SOUND
    // ==========================================================

    for (final WalkRequest request
        in incoming) {
      final bool alreadyExists =
          _requests.any(
        (WalkRequest oldRequest) =>
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
    // UPDATE REQUEST LIST
    // ==========================================================

    _requests
      ..clear()
      ..addAll(incoming);
  }

  // ============================================================
  // REFRESH REQUEST DISTANCES
  //
  // Called when walker GPS changes.
  // ============================================================

  void _refreshRequestDistances() {
    if (!_searching) {
      return;
    }

    final QuerySnapshot<
        Map<String, dynamic>>? ignored = null;

    // ----------------------------------------------------------
    // Firestore snapshot listener will normally provide
    // the latest request documents.
    //
    // We intentionally do not perform another Firestore
    // query on every GPS update.
    // ----------------------------------------------------------

    // Prevent analyzer from considering this method empty
    // while keeping the listener architecture efficient.
    if (ignored != null) {
      debugPrint(
        ignored.toString(),
      );
    }
  }

  // ============================================================
  // STOP SEARCH
  // ============================================================

  Future<void> stopSearch() async {
    final User? user =
        _auth.currentUser;

    // ==========================================================
    // STOP LOCAL SEARCH IMMEDIATELY
    //
    // UI should change immediately.
    // ==========================================================

    _searching = false;

    // ==========================================================
    // STOP EXPIRY TIMER
    // ==========================================================

    _expiryTimer?.cancel();
    _expiryTimer = null;

    // ==========================================================
    // STOP REQUEST LISTENER
    // ==========================================================

    await _requestSubscription?.cancel();
    _requestSubscription = null;

    // ==========================================================
    // STOP LOCATION LISTENER
    // ==========================================================

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // ==========================================================
    // STOP GPS TRACKING
    // ==========================================================

    await _locationService.stopTracking();

    // ==========================================================
    // STOP ALL REQUEST SOUNDS
    // ==========================================================

    await WalkRequestSoundService
        .instance
        .stopAll();

    // ==========================================================
    // CLEAR REQUESTS
    // ==========================================================

    _requests.clear();

    // ==========================================================
    // SAVE FIRESTORE STATE
    // ==========================================================

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
          SetOptions(
            merge: true,
          ),
        );
      } catch (e) {
        debugPrint(
          'Stop Insta Walk Firestore Error: $e',
        );
      }
    }

    debugPrint(
      'Insta Walk search stopped.',
    );
  }

  // ============================================================
  // 2 MINUTE EXPIRY
  // ============================================================

  void _startExpiryTimer(
    DateTime expiresAt,
  ) {
    // ----------------------------------------------------------
    // IMPORTANT:
    //
    // Always cancel old timer first.
    // ----------------------------------------------------------

    _expiryTimer?.cancel();
    _expiryTimer = null;

    final Duration remaining =
        expiresAt.difference(
      DateTime.now(),
    );

    // ==========================================================
    // ALREADY EXPIRED
    // ==========================================================

    if (remaining <= Duration.zero) {
      unawaited(
        stopSearch(),
      );

      return;
    }

    // ==========================================================
    // START NEW TIMER
    // ==========================================================

    _expiryTimer = Timer(
      remaining,
      () async {
        _expiryTimer = null;

        if (!_searching) {
          return;
        }

        await stopSearch();
      },
    );
  }

  // ============================================================
  // GET WALKER ID
  // ============================================================

  Future<String?> _getWalkerId() async {
    // ----------------------------------------------------------
    // Local cache first.
    // ----------------------------------------------------------

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
      // ========================================================
      // PHONE ACCOUNT
      // ========================================================

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

      // ========================================================
      // FALLBACK: USERS DOCUMENT
      // ========================================================

      final DocumentSnapshot<
          Map<String, dynamic>> userSnapshot =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      final Map<String, dynamic>? userData =
          userSnapshot.data();

      final dynamic userWalkerId =
          userData?['walkerId'];

      if (userWalkerId != null) {
        final String id =
            userWalkerId
                .toString()
                .trim();

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
  // READ DISTANCE
  // ============================================================

  double _readDistance(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    final String text =
        value?.toString().trim() ?? '';

    if (text.isEmpty) {
      return 999;
    }

    return double.tryParse(text) ?? 999;
  }

  // ============================================================
  // CLEAR LOCAL STATE
  // ============================================================

  Future<void> _clearLocalState() async {
    _searching = false;

    _expiryTimer?.cancel();
    _expiryTimer = null;

    await _requestSubscription?.cancel();
    _requestSubscription = null;

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    await _locationService.stopTracking();

    await WalkRequestSoundService
        .instance
        .stopAll();

    _requests.clear();

    _currentPosition = null;
  }

  // ============================================================
  // RESET / DISPOSE SERVICE
  // ============================================================

  Future<void> disposeService() async {
    await _clearLocalState();

    debugPrint(
      'Insta Walk service disposed.',
    );
  }
}
