// File:
// lib/features/insta_walk/services/insta_walk_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/insta_walk_request.dart';
import '../../walks/constants/walks_constants.dart';
import '../../walks/services/walk_request_sound_service.dart';
import '../../walks/services/walker_location_service.dart';

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

  final List<InstaWalkRequest> _requests =
      <InstaWalkRequest>[];

  // ============================================================
  // GETTERS
  // ============================================================

  bool get searching => _searching;

  bool get starting => _starting;

  String? get walkerId => _walkerId;

  Position? get currentPosition =>
      _currentPosition;

  List<InstaWalkRequest> get requests =>
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
    if (_starting) {
      return false;
    }

    if (_searching) {
      return true;
    }

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        'INSTA WALK: Firebase user not found.',
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
          'INSTA WALK: Walker ID not found.',
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
          'INSTA WALK: Current location unavailable.',
        );
        return false;
      }

      _currentPosition = position;

      debugPrint(
        'INSTA WALK: Walker location '
        '${position.latitude}, '
        '${position.longitude}',
      );

      // ========================================================
      // START CONTINUOUS GPS
      // ========================================================

      final bool trackingStarted =
          await _locationService.startTracking();

      if (!trackingStarted) {
        debugPrint(
          'INSTA WALK: GPS tracking could not start.',
        );
        return false;
      }

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
            'INSTA WALK LOCATION ERROR: $error',
          );
        },
      );

      // ========================================================
      // SEARCH TIME
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
        <String, dynamic>{
          'walkerId': walkerId,
          'walkerUid': user.uid,
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
        SetOptions(
          merge: true,
        ),
      );

      debugPrint(
        'INSTA WALK: Firestore search state saved.',
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
      // START REQUEST LISTENER
      // ========================================================

      _startRequestListener();

      // ========================================================
      // START EXPIRY TIMER
      // ========================================================

      _startExpiryTimer(expiresAt);

      debugPrint(
        'INSTA WALK: SEARCH STARTED '
        'radius='
        '${WalksConstants.searchRadiusKm}km',
      );

      return true;
    } catch (e, stackTrace) {
      debugPrint(
        'INSTA WALK START ERROR: $e',
      );

      debugPrint(
        '$stackTrace',
      );

      await _clearLocalState();

      return false;
    } finally {
      _starting = false;
    }
  }

  // ============================================================
  // RESTORE SEARCH
  // ============================================================

  Future<void> restoreSearch() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      return;
    }

    if (_searching) {
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

      debugPrint(
        'INSTA WALK RESTORE: '
        'searching=$searching',
      );

      if (!searching) {
        return;
      }

      // ========================================================
      // EXPIRY
      // ========================================================

      DateTime? expiresAt;

      final dynamic rawExpiry =
          data['instaWalkSearchExpiresAt'];

      if (rawExpiry is Timestamp) {
        expiresAt = rawExpiry.toDate();
      } else if (rawExpiry is DateTime) {
        expiresAt = rawExpiry;
      }

      if (expiresAt == null ||
          !expiresAt.isAfter(
            DateTime.now(),
          )) {
        debugPrint(
          'INSTA WALK RESTORE: Search expired.',
        );

        await stopSearch();
        return;
      }

      // ========================================================
      // WALKER ID
      // ========================================================

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
          _walkerId!.trim().isEmpty) {
        final String? loadedWalkerId =
            await _getWalkerId();

        if (loadedWalkerId == null ||
            loadedWalkerId.trim().isEmpty) {
          debugPrint(
            'INSTA WALK RESTORE: '
            'Walker ID missing.',
          );

          await stopSearch();
          return;
        }
      }

      // ========================================================
      // CURRENT LOCATION
      // ========================================================

      final Position? position =
          await _locationService
              .getCurrentLocation();

      if (position == null) {
        debugPrint(
          'INSTA WALK RESTORE: '
          'Location unavailable.',
        );
        return;
      }

      _currentPosition = position;

      // ========================================================
      // GPS
      // ========================================================

      await _locationService.startTracking();

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
            'INSTA WALK RESTORE LOCATION ERROR: '
            '$error',
          );
        },
      );

      // ========================================================
      // LOCAL SEARCH
      // ========================================================

      _searching = true;

      _requests.clear();

      // ========================================================
      // REQUEST LISTENER
      // ========================================================

      _startRequestListener();

      // ========================================================
      // TIMER
      // ========================================================

      _startExpiryTimer(expiresAt);

      debugPrint(
        'INSTA WALK: SEARCH RESTORED.',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'INSTA WALK RESTORE ERROR: $e',
      );

      debugPrint(
        '$stackTrace',
      );
    }
  }

  // ============================================================
  // REQUEST LISTENER
  // ============================================================

  void _startRequestListener() {
    _requestSubscription?.cancel();

    debugPrint(
      'INSTA WALK: Starting walk_requests listener...',
    );

    _requestSubscription =
        _firestore
            .collection('walk_requests')
            .where(
              'status',
              isEqualTo: 'searching',
            )
            .snapshots()
            .listen(
      (
        QuerySnapshot<Map<String, dynamic>>
            snapshot,
      ) {
        debugPrint(
          'INSTA WALK: Firestore returned '
          '${snapshot.docs.length} '
          'searching request(s).',
        );

        _handleRequests(snapshot);
      },
      onError: (Object error) {
        debugPrint(
          'INSTA WALK REQUEST LISTENER ERROR: '
          '$error',
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
      debugPrint(
        'INSTA WALK: Request received '
        'but search is OFF.',
      );
      return;
    }

    final List<InstaWalkRequest> incoming =
        <InstaWalkRequest>[];

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

      debugPrint(
        'INSTA WALK REQUEST FOUND: '
        '${document.id} '
        'status=${data['status']} '
        'pickupLat='
        '${data['pickupLat'] ?? data['pickuplatitude']} '
        'pickupLng='
        '${data['pickupLng'] ?? data['pickuplongitude']} '
        'distance='
        '${data['distanceKm'] ?? data['distance']}',
      );

      try {
        // ======================================================
        // USE EXISTING INSTA WALK MODEL
        // ======================================================

        final InstaWalkRequest request =
            InstaWalkRequest.fromFirestore(
          document,
        );

        // ======================================================
        // CALCULATE DISTANCE
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

          debugPrint(
            'INSTA WALK DISTANCE: '
            '${document.id} = '
            '${distance.toStringAsFixed(2)} km',
          );
        } else {
          distance = _readDistance(
            data['distanceKm'] ??
                data['walkDistanceKm'] ??
                data['distance'],
          );

          debugPrint(
            'INSTA WALK FIRESTORE DISTANCE: '
            '${document.id} = '
            '$distance km',
          );
        }

        // ======================================================
        // DISTANCE FILTER
        // ======================================================

        if (distance >
            WalksConstants.searchRadiusKm) {
          debugPrint(
            'INSTA WALK: Request '
            '${document.id} REJECTED - '
            'outside '
            '${WalksConstants.searchRadiusKm} km.',
          );

          continue;
        }

        // ======================================================
        // UPDATE DISTANCE
        // ======================================================

        final InstaWalkRequest updatedRequest =
            request.copyWith(
          distanceKm: distance,
        );

        incoming.add(
          updatedRequest,
        );

        debugPrint(
          'INSTA WALK: Request '
          '${document.id} ADDED '
          'to Walker list.',
        );
      } catch (e, stackTrace) {
        debugPrint(
          'INSTA WALK REQUEST PARSE ERROR '
          '${document.id}: $e',
        );

        debugPrint(
          '$stackTrace',
        );
      }
    }

    // ==========================================================
    // SORT
    // ==========================================================

    incoming.sort(
      (
        InstaWalkRequest a,
        InstaWalkRequest b,
      ) {
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
              (InstaWalkRequest request) =>
                  request.id,
            )
            .toSet();

    // ==========================================================
    // NEW REQUEST SOUND
    // ==========================================================

    for (final InstaWalkRequest request
        in incoming) {
      final bool alreadyExists =
          _requests.any(
        (InstaWalkRequest oldRequest) =>
            oldRequest.id == request.id,
      );

      if (!alreadyExists) {
        unawaited(
          WalkRequestSoundService
              .instance
              .playForRequest(
            request.id,
          ),
        );
      }
    }

    // ==========================================================
    // REMOVED REQUEST SOUND
    // ==========================================================

    for (final InstaWalkRequest oldRequest
        in List<InstaWalkRequest>.from(
      _requests,
    )) {
      if (!incomingIds.contains(
        oldRequest.id,
      )) {
        unawaited(
          WalkRequestSoundService
              .instance
              .stopRequest(
            oldRequest.id,
          ),
        );
      }
    }

    // ==========================================================
    // UPDATE LIST
    // ==========================================================

    _requests
      ..clear()
      ..addAll(incoming);

    debugPrint(
      'INSTA WALK: FINAL REQUEST COUNT = '
      '${_requests.length}',
    );
  }

  // ============================================================
  // REFRESH REQUEST DISTANCES
  // ============================================================

  void _refreshRequestDistances() {
    if (!_searching) {
      return;
    }

    final Position? position =
        _currentPosition;

    if (position == null ||
        _requests.isEmpty) {
      return;
    }

    final List<InstaWalkRequest>
        updatedRequests =
        <InstaWalkRequest>[];

    for (final InstaWalkRequest request
        in _requests) {
      // --------------------------------------------------------
      // No coordinates.
      // --------------------------------------------------------

      if (!request.hasPickupLocation) {
        updatedRequests.add(request);
        continue;
      }

      // --------------------------------------------------------
      // Real GPS distance.
      // --------------------------------------------------------

      final double distance =
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

      // --------------------------------------------------------
      // Outside radius.
      // --------------------------------------------------------

      if (distance >
          WalksConstants.searchRadiusKm) {
        unawaited(
          WalkRequestSoundService
              .instance
              .stopRequest(
            request.id,
          ),
        );

        continue;
      }

      updatedRequests.add(
        request.copyWith(
          distanceKm: distance,
        ),
      );
    }

    // ==========================================================
    // SORT
    // ==========================================================

    updatedRequests.sort(
      (
        InstaWalkRequest a,
        InstaWalkRequest b,
      ) {
        return a.distanceKm.compareTo(
          b.distanceKm,
        );
      },
    );

    // ==========================================================
    // UPDATE
    // ==========================================================

    _requests
      ..clear()
      ..addAll(updatedRequests);
  }

  // ============================================================
  // STOP SEARCH
  // ============================================================

  Future<void> stopSearch() async {
    final User? user =
        _auth.currentUser;

    debugPrint(
      'INSTA WALK: STOP SEARCH requested.',
    );

    // ==========================================================
    // LOCAL STATE
    // ==========================================================

    _searching = false;

    // ==========================================================
    // TIMER
    // ==========================================================

    _expiryTimer?.cancel();
    _expiryTimer = null;

    // ==========================================================
    // REQUEST LISTENER
    // ==========================================================

    await _requestSubscription?.cancel();
    _requestSubscription = null;

    // ==========================================================
    // LOCATION LISTENER
    // ==========================================================

    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // ==========================================================
    // GPS
    // ==========================================================

    await _locationService.stopTracking();

    // ==========================================================
    // SOUND
    // ==========================================================

    await WalkRequestSoundService
        .instance
        .stopAll();

    // ==========================================================
    // CLEAR REQUESTS
    // ==========================================================

    _requests.clear();

    // ==========================================================
    // FIRESTORE
    // ==========================================================

    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(
          <String, dynamic>{
            'instaWalkSearching': false,
            'instaWalkSearchUpdatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );

        debugPrint(
          'INSTA WALK: Firestore search state = false.',
        );
      } catch (e) {
        debugPrint(
          'INSTA WALK STOP FIRESTORE ERROR: $e',
        );
      }
    }

    debugPrint(
      'INSTA WALK: SEARCH STOPPED.',
    );
  }

  // ============================================================
  // EXPIRY TIMER
  // ============================================================

  void _startExpiryTimer(
    DateTime expiresAt,
  ) {
    _expiryTimer?.cancel();
    _expiryTimer = null;

    final Duration remaining =
        expiresAt.difference(
      DateTime.now(),
    );

    if (remaining <= Duration.zero) {
      unawaited(
        stopSearch(),
      );
      return;
    }

    debugPrint(
      'INSTA WALK: Search expires in '
      '${remaining.inSeconds} seconds.',
    );

    _expiryTimer = Timer(
      remaining,
      () async {
        _expiryTimer = null;

        if (!_searching) {
          return;
        }

        debugPrint(
          'INSTA WALK: Search expired.',
        );

        await stopSearch();
      },
    );
  }

  // ============================================================
  // GET WALKER ID
  // ============================================================

  Future<String?> _getWalkerId() async {
    // ==========================================================
    // CACHE
    // ==========================================================

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
      // PHONE ACCOUNTS
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

          debugPrint(
            'INSTA WALK: Walker ID from '
            'phoneAccounts = $id',
          );

          return id;
        }
      }

      // ========================================================
      // USERS FALLBACK
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
            userWalkerId.toString().trim();

        if (id.isNotEmpty) {
          _walkerId = id;

          debugPrint(
            'INSTA WALK: Walker ID from '
            'users = $id',
          );

          return id;
        }
      }
    } catch (e) {
      debugPrint(
        'INSTA WALK WALKER ID ERROR: $e',
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
  //
  // IMPORTANT:
  // This DOES NOT change Firestore instaWalkSearching.
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
  // DISPOSE SERVICE
  //
  // IMPORTANT:
  // Do NOT call stopSearch() here.
  //
  // Screen navigation/dispose will NOT write
  // instaWalkSearching=false to Firestore.
  // ============================================================

  Future<void> disposeService() async {
    await _clearLocalState();

    debugPrint(
      'INSTA WALK: Local service disposed. '
      'Firestore search state was NOT changed.',
    );
  }
}
