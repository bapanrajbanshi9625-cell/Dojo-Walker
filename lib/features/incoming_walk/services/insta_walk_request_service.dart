// File:
// lib/features/incoming_walk/services/insta_walk_request_service.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../services/walker_availability_service.dart';
import '../../../services/walker_location_service.dart';
import '../../insta_walk/models/insta_walk_request.dart';

class InstaWalkRequestService {
  InstaWalkRequestService._();

  static final InstaWalkRequestService instance =
      InstaWalkRequestService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final WalkerAvailabilityService _availabilityService =
      WalkerAvailabilityService.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  static const double _searchRadiusKm = 3.5;
  static const Duration _offerDuration = Duration(minutes: 3);

  StreamSubscription<User?>? _authSubscription;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
      _requestSubscription;

  StreamController<List<InstaWalkRequest>>? _controller;

  Timer? _refreshTimer;
  Timer? _gpsRetryTimer;

  bool _disposed = false;
  bool _availabilityListenerAttached = false;

  int _listenerGeneration = 0;

  Future<void> _restartQueue = Future<void>.value();

  // ============================================================
  // PUBLIC STREAM
  // ============================================================

  Stream<List<InstaWalkRequest>> pendingRequestsStream() {
    _controller ??= StreamController<List<InstaWalkRequest>>.broadcast(
      onListen: _handleControllerListen,
      onCancel: _handleControllerCancel,
    );

    return _controller!.stream;
  }

  // ============================================================
  // CONTROLLER LISTEN
  // ============================================================

  void _handleControllerListen() {
    if (_disposed) return;

    _attachAvailabilityListener();

    _authSubscription ??= _auth.authStateChanges().listen((_) {
      _scheduleListenerRefresh('auth_changed');
    });

    _scheduleListenerRefresh('stream_listened');

    // ------------------------------------------------------------
    // GPS can become active slightly after Online is enabled.
    //
    // Keep checking for a short period so that:
    //
    // Owner searches first
    //        ↓
    // request stays searching
    //        ↓
    // Walker goes Online
    //        ↓
    // GPS starts
    //        ↓
    // existing request is processed
    // ------------------------------------------------------------
    _startGpsRetryTimer();
  }

  // ============================================================
  // CONTROLLER CANCEL
  // ============================================================

  Future<void> _handleControllerCancel() async {
    await _stopRequestListener();

    await _authSubscription?.cancel();
    _authSubscription = null;

    _detachAvailabilityListener();

    _refreshTimer?.cancel();
    _refreshTimer = null;

    _gpsRetryTimer?.cancel();
    _gpsRetryTimer = null;
  }

  // ============================================================
  // AVAILABILITY LISTENER
  // ============================================================

  void _attachAvailabilityListener() {
    if (_availabilityListenerAttached) return;

    _availabilityListenerAttached = true;

    _availabilityService.addListener(
      _onAvailabilityChanged,
    );
  }

  void _detachAvailabilityListener() {
    if (!_availabilityListenerAttached) return;

    _availabilityListenerAttached = false;

    _availabilityService.removeListener(
      _onAvailabilityChanged,
    );
  }

  void _onAvailabilityChanged() {
    if (_disposed) return;

    debugPrint(
      '[InstaWalkRequestService] '
      'AVAILABILITY CHANGED '
      'online=${_availabilityService.isOnline} '
      'insta=${_availabilityService.isInstaWalkSelected} '
      'searching=${_availabilityService.isInstaWalkSearching} '
      'activeWalk=${_availabilityService.isActiveWalk} '
      'gps=${_locationService.isTracking}',
    );

    _scheduleListenerRefresh(
      'availability_changed',
    );

    _startGpsRetryTimer();
  }

  // ============================================================
  // GPS RETRY
  //
  // This specifically protects the Online -> GPS startup race.
  // We do NOT start GPS here.
  //
  // WalkerAvailabilityService remains the owner of GPS lifecycle.
  // ============================================================

  void _startGpsRetryTimer() {
    if (_disposed) return;

    _gpsRetryTimer?.cancel();

    if (_controller == null ||
        _controller!.isClosed) {
      return;
    }

    if (!_canBeSearchingForRequests()) {
      return;
    }

    if (_locationService.isTracking) {
      return;
    }

    int attempts = 0;

    _gpsRetryTimer = Timer.periodic(
      const Duration(seconds: 1),
      (Timer timer) {
        if (_disposed) {
          timer.cancel();
          return;
        }

        attempts++;

        if (!_canBeSearchingForRequests()) {
          timer.cancel();
          return;
        }

        if (_locationService.isTracking) {
          timer.cancel();

          _scheduleListenerRefresh(
            'gps_became_active',
          );

          return;
        }

        // Keep trying long enough for Android location startup.
        if (attempts >= 15) {
          timer.cancel();

          debugPrint(
            '[InstaWalkRequestService] '
            'GPS RETRY WINDOW FINISHED '
            'gps=${_locationService.isTracking}',
          );

          return;
        }

        debugPrint(
          '[InstaWalkRequestService] '
          'WAITING FOR GPS '
          'attempt=$attempts',
        );
      },
    );
  }

  // ============================================================
  // LISTENER REFRESH
  // ============================================================

  void _scheduleListenerRefresh(
    String reason,
  ) {
    if (_disposed ||
        _controller == null ||
        _controller!.isClosed) {
      return;
    }

    final int generation = ++_listenerGeneration;

    _restartQueue = _restartQueue.then(
      (_) async {
        if (_disposed) return;

        await _syncRequestListener(
          generation: generation,
          reason: reason,
        );
      },
    ).catchError(
      (error, stackTrace) {
        debugPrint(
          '[InstaWalkRequestService] '
          'listener restart error: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      },
    );
  }

  // ============================================================
  // SYNC FIRESTORE LISTENER
  // ============================================================

  Future<void> _syncRequestListener({
    required int generation,
    required String reason,
  }) async {
    if (_disposed) return;

    debugPrint(
      '[InstaWalkRequestService] SYNC '
      'reason=$reason '
      'generation=$generation '
      'online=${_availabilityService.isOnline} '
      'insta=${_availabilityService.isInstaWalkSelected} '
      'searching=${_availabilityService.isInstaWalkSearching} '
      'activeWalk=${_availabilityService.isActiveWalk} '
      'gps=${_locationService.isTracking}',
    );

    await _stopRequestListener();

    if (_disposed) return;

    if (generation != _listenerGeneration) {
      debugPrint(
        '[InstaWalkRequestService] '
        'STALE SYNC '
        'generation=$generation '
        'latest=$_listenerGeneration',
      );

      return;
    }

    // ------------------------------------------------------------
    // IMPORTANT:
    //
    // Firestore listening is allowed as soon as the Walker is
    // Online and available for Insta Walk.
    //
    // GPS is checked later when a request is processed.
    //
    // This prevents:
    //
    // Owner request created first
    // +
    // Walker comes Online
    // +
    // GPS starts a moment later
    //
    // from causing the Firestore listener to miss the request.
    // ------------------------------------------------------------

    if (!_canBeSearchingForRequests()) {
      debugPrint(
        '[InstaWalkRequestService] '
        'FIRESTORE LISTENER OFF '
        'because Walker is not available for Insta Walk.',
      );

      _emitEmpty();

      return;
    }

    final String? walkerId = await _getWalkerId();

    if (_disposed) return;

    if (generation != _listenerGeneration) {
      debugPrint(
        '[InstaWalkRequestService] '
        'STALE AFTER WALKER ID '
        'generation=$generation '
        'latest=$_listenerGeneration',
      );

      return;
    }

    if (walkerId == null ||
        walkerId.trim().isEmpty) {
      debugPrint(
        '[InstaWalkRequestService] '
        'WALKER ID NOT FOUND. '
        'Firestore listener not started.',
      );

      _emitEmpty();

      return;
    }

    debugPrint(
      '[InstaWalkRequestService] '
      'FIRESTORE LISTENER STARTING '
      'walkerId=$walkerId '
      'gps=${_locationService.isTracking}',
    );

    final Query<Map<String, dynamic>> query =
        _firestore
            .collection('walk_request')
            .where(
              'status',
              isEqualTo: 'searching',
            );

    _requestSubscription =
        query.snapshots().listen(
      (QuerySnapshot<Map<String, dynamic>> snapshot) {
        unawaited(
          _processSnapshot(
            snapshot,
            walkerId,
            generation,
          ),
        );
      },
      onError: (
        Object error,
        StackTrace stackTrace,
      ) {
        debugPrint(
          '[InstaWalkRequestService] '
          'FIRESTORE LISTENER ERROR: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );

        if (!_disposed &&
            _canBeSearchingForRequests() &&
            generation == _listenerGeneration) {
          _scheduleListenerRefresh(
            'firestore_error',
          );
        }
      },
      cancelOnError: false,
    );

    debugPrint(
      '[InstaWalkRequestService] '
      'FIRESTORE LISTENER ACTIVE '
      'walkerId=$walkerId',
    );
  }

  // ============================================================
  // PROCESS SNAPSHOT
  // ============================================================

  Future<void> _processSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String walkerId,
    int generation,
  ) async {
    if (_disposed) return;

    if (generation != _listenerGeneration) {
      return;
    }

    if (!_canBeSearchingForRequests()) {
      _emitEmpty();

      return;
    }

    debugPrint(
      '[InstaWalkRequestService] '
      'REQUEST SNAPSHOT '
      'count=${snapshot.docs.length} '
      'gps=${_locationService.isTracking}',
    );

    if (snapshot.docs.isEmpty) {
      _emitEmpty();

      return;
    }

    final List<InstaWalkRequest> validRequests =
        <InstaWalkRequest>[];

    for (
      final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs
    ) {
      if (_disposed) return;

      if (generation != _listenerGeneration) {
        return;
      }

      try {
        final InstaWalkRequest? request =
            await _processSingleRequest(
          doc,
          walkerId,
        );

        if (request != null) {
          validRequests.add(request);
        }
      } catch (error, stackTrace) {
        debugPrint(
          '[InstaWalkRequestService] '
          'REQUEST PROCESS ERROR '
          'id=${doc.id}: $error',
        );

        debugPrintStack(
          stackTrace: stackTrace,
        );
      }
    }

    if (_disposed) return;

    if (generation != _listenerGeneration) {
      return;
    }

    validRequests.sort(
      (
        InstaWalkRequest a,
        InstaWalkRequest b,
      ) {
        final DateTime aTime =
            a.createdAt?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final DateTime bTime =
            b.createdAt?.toDate() ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return aTime.compareTo(bTime);
      },
    );

    debugPrint(
      '[InstaWalkRequestService] '
      'VALID REQUESTS '
      'count=${validRequests.length}',
    );

    if (validRequests.isNotEmpty) {
      debugPrint(
        '[InstaWalkRequestService] '
        'REQUEST READY '
        'id=${validRequests.first.requestId}',
      );
    }

    _emit(validRequests);
  }

  // ============================================================
  // PROCESS SINGLE REQUEST
  // ============================================================

  Future<InstaWalkRequest?> _processSingleRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String walkerId,
  ) async {
    final Map<String, dynamic> data = doc.data();

    final String requestId = doc.id;

    final String status =
        (data['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

    if (status != 'searching') {
      return null;
    }

    final String? existingClaimWalkerUid =
        _cleanString(
      data['incomingWalkerUid'],
    );

    final String currentUid =
        _auth.currentUser?.uid ?? '';

    if (currentUid.isEmpty) {
      debugPrint(
        '[InstaWalkRequestService] '
        'AUTH UID NOT FOUND '
        'id=$requestId',
      );

      return null;
    }

    if (existingClaimWalkerUid != null &&
        existingClaimWalkerUid.isNotEmpty &&
        existingClaimWalkerUid != currentUid) {
      debugPrint(
        '[InstaWalkRequestService] '
        'REQUEST ALREADY CLAIMED '
        'id=$requestId',
      );

      return null;
    }

    final DocumentReference<Map<String, dynamic>>
        requestRef =
        _firestore
            .collection('walk_request')
            .doc(requestId);

    final DocumentReference<Map<String, dynamic>>
        rejectionRef =
        requestRef
            .collection('rejections')
            .doc(walkerId);

    final DocumentSnapshot<Map<String, dynamic>>
        rejectionSnapshot =
        await rejectionRef.get();

    if (rejectionSnapshot.exists) {
      debugPrint(
        '[InstaWalkRequestService] '
        'REQUEST REJECTED BEFORE '
        'id=$requestId',
      );

      return null;
    }

    // ==========================================================
    // ALREADY CLAIMED BY THIS WALKER
    // ==========================================================

    if (existingClaimWalkerUid == currentUid) {
      debugPrint(
        '[InstaWalkRequestService] '
        'REQUEST ALREADY CLAIMED BY THIS WALKER '
        'id=$requestId',
      );

      return InstaWalkRequest.fromFirestore(
        doc,
      );
    }

    // ==========================================================
    // OWNER LOCATION
    // ==========================================================

    final GeoPoint? ownerLocation =
        _readGeoPoint(
      data['ownerLocation'],
    );

    if (ownerLocation == null) {
      debugPrint(
        '[InstaWalkRequestService] '
        'OWNER LOCATION MISSING '
        'id=$requestId',
      );

      return null;
    }

    // ==========================================================
    // WALKER LOCATION
    //
    // GPS is still mandatory for accepting an eligible request.
    // We simply do not block the Firestore listener itself on GPS.
    // ==========================================================

    final currentPosition =
        _locationService.currentPosition;

    if (currentPosition == null) {
      debugPrint(
        '[InstaWalkRequestService] '
        'WALKER LOCATION NOT READY '
        'id=$requestId '
        'gps=${_locationService.isTracking}',
      );

      return null;
    }

    final GeoPoint walkerLocation =
        GeoPoint(
      currentPosition.latitude,
      currentPosition.longitude,
    );

    // ==========================================================
    // DISTANCE
    // ==========================================================

    final double distanceKm =
        _distanceInKm(
      walkerLocation.latitude,
      walkerLocation.longitude,
      ownerLocation.latitude,
      ownerLocation.longitude,
    );

    debugPrint(
      '[InstaWalkRequestService] '
      'DISTANCE '
      'id=$requestId '
      'distance=${distanceKm.toStringAsFixed(2)}km '
      'radius=$_searchRadiusKm km',
    );

    if (distanceKm > _searchRadiusKm) {
      return null;
    }

    // ==========================================================
    // CLAIM
    // ==========================================================

    final bool claimed =
        await _claimRequest(
      requestRef: requestRef,
      walkerId: walkerId,
      walkerUid: currentUid,
    );

    if (!claimed) {
      debugPrint(
        '[InstaWalkRequestService] '
        'CLAIM FAILED '
        'id=$requestId',
      );

      return null;
    }

    debugPrint(
      '[InstaWalkRequestService] '
      'CLAIM SUCCESS '
      'id=$requestId',
    );

    _scheduleClaimTimeout(
      requestId: requestId,
      walkerId: walkerId,
      walkerUid: currentUid,
    );

    return InstaWalkRequest.fromFirestore(
      doc,
    );
  }

  // ============================================================
  // CLAIM REQUEST
  // ============================================================

  Future<bool> _claimRequest({
    required DocumentReference<Map<String, dynamic>>
        requestRef,
    required String walkerId,
    required String walkerUid,
  }) async {
    try {
      return await _firestore.runTransaction<bool>(
        (
          Transaction transaction,
        ) async {
          final DocumentSnapshot<Map<String, dynamic>>
              snapshot =
              await transaction.get(
            requestRef,
          );

          if (!snapshot.exists) {
            return false;
          }

          final Map<String, dynamic> data =
              snapshot.data() ??
              <String, dynamic>{};

          final String status =
              (data['status'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();

          if (status != 'searching') {
            return false;
          }

          final String? existingUid =
              _cleanString(
            data['incomingWalkerUid'],
          );

          if (existingUid != null &&
              existingUid.isNotEmpty) {
            if (existingUid == walkerUid) {
              return true;
            }

            return false;
          }

          transaction.update(
            requestRef,
            <String, dynamic>{
              'incomingWalkerUid': walkerUid,
              'incomingClaimedAt':
                  FieldValue.serverTimestamp(),
            },
          );

          return true;
        },
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[InstaWalkRequestService] '
        'CLAIM TRANSACTION ERROR: $error',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );

      return false;
    }
  }

  // ============================================================
  // CLAIM TIMEOUT
  // ============================================================

  void _scheduleClaimTimeout({
    required String requestId,
    required String walkerId,
    required String walkerUid,
  }) {
    Timer(
      _offerDuration,
      () async {
        if (_disposed) return;

        try {
          final DocumentReference<Map<String, dynamic>>
              requestRef =
              _firestore
                  .collection('walk_request')
                  .doc(requestId);

          final DocumentReference<Map<String, dynamic>>
              rejectionRef =
              requestRef
                  .collection('rejections')
                  .doc(walkerId);

          await _firestore.runTransaction<void>(
            (
              Transaction transaction,
            ) async {
              final DocumentSnapshot<Map<String, dynamic>>
                  snapshot =
                  await transaction.get(
                requestRef,
              );

              if (!snapshot.exists) {
                return;
              }

              final Map<String, dynamic> data =
                  snapshot.data() ??
                  <String, dynamic>{};

              final String? claimedUid =
                  _cleanString(
                data['incomingWalkerUid'],
              );

              if (claimedUid != walkerUid) {
                return;
              }

              final String status =
                  (data['status'] ?? '')
                      .toString()
                      .trim()
                      .toLowerCase();

              if (status != 'searching') {
                return;
              }

              transaction.set(
                rejectionRef,
                <String, dynamic>{
                  'walkerId': walkerId,
                  'walkerUid': walkerUid,
                  'createdAt':
                      FieldValue.serverTimestamp(),
                },
              );

              transaction.update(
                requestRef,
                <String, dynamic>{
                  'incomingWalkerUid': null,
                  'incomingClaimedAt': null,
                },
              );
            },
          );

          debugPrint(
            '[InstaWalkRequestService] '
            'CLAIM TIMEOUT '
            'id=$requestId',
          );
        } catch (error, stackTrace) {
          debugPrint(
            '[InstaWalkRequestService] '
            'CLAIM TIMEOUT ERROR '
            'id=$requestId: $error',
          );

          debugPrintStack(
            stackTrace: stackTrace,
          );
        }
      },
    );
  }

  // ============================================================
  // BASIC RECEIVE CONDITION
  //
  // Firestore listener condition.
  //
  // GPS deliberately NOT included here.
  // ============================================================

  bool _canBeSearchingForRequests() {
    final bool online =
        _availabilityService.isOnline;

    final bool insta =
        _availabilityService.isInstaWalkSelected;

    final bool searching =
        _availabilityService.isInstaWalkSearching;

    final bool activeWalk =
        _availabilityService.isActiveWalk;

    return online &&
        insta &&
        searching &&
        !activeWalk;
  }

  // ============================================================
  // GET WALKER ID
  // ============================================================

  Future<String?> _getWalkerId() async {
    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        '[InstaWalkRequestService] '
        'AUTH USER NOT FOUND',
      );

      return null;
    }

    return user.uid;
  }

  // ============================================================
  // STOP LISTENER
  // ============================================================

  Future<void> _stopRequestListener() async {
    await _requestSubscription?.cancel();

    _requestSubscription = null;
  }

  // ============================================================
  // EMIT
  // ============================================================

  void _emit(
    List<InstaWalkRequest> requests,
  ) {
    if (_disposed ||
        _controller == null ||
        _controller!.isClosed) {
      return;
    }

    _controller!.add(requests);
  }

  void _emitEmpty() {
    _emit(
      <InstaWalkRequest>[],
    );
  }

  // ============================================================
  // GEOPOINT
  // ============================================================

  GeoPoint? _readGeoPoint(
    dynamic value,
  ) {
    if (value is GeoPoint) {
      return value;
    }

    if (value is Map) {
      final dynamic latitude =
          value['latitude'];

      final dynamic longitude =
          value['longitude'];

      final double? lat =
          _toDouble(latitude);

      final double? lng =
          _toDouble(longitude);

      if (lat != null &&
          lng != null) {
        return GeoPoint(
          lat,
          lng,
        );
      }
    }

    return null;
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  double _distanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm =
        6371.0;

    final double dLat =
        _degreesToRadians(
      lat2 - lat1,
    );

    final double dLon =
        _degreesToRadians(
      lon2 - lon1,
    );

    final double a =
        math.pow(
              math.sin(dLat / 2),
              2,
            ).toDouble() +
        math.cos(
              _degreesToRadians(lat1),
            ) *
            math.cos(
              _degreesToRadians(lat2),
            ) *
            math.pow(
              math.sin(dLon / 2),
              2,
            ).toDouble();

    final double c =
        2 *
        math.atan2(
          math.sqrt(a),
          math.sqrt(1 - a),
        );

    return earthRadiusKm * c;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        math.pi /
        180.0;
  }

  // ============================================================
  // DOUBLE
  // ============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(
        value,
      );
    }

    return null;
  }

  // ============================================================
  // STRING
  // ============================================================

  String? _cleanString(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    final String text =
        value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    return text;
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  void dispose() {
    if (_disposed) return;

    _disposed = true;

    _listenerGeneration++;

    _refreshTimer?.cancel();
    _refreshTimer = null;

    _gpsRetryTimer?.cancel();
    _gpsRetryTimer = null;

    _detachAvailabilityListener();

    unawaited(
      _requestSubscription?.cancel(),
    );

    _requestSubscription = null;

    unawaited(
      _authSubscription?.cancel(),
    );

    _authSubscription = null;

    final StreamController<List<InstaWalkRequest>>?
        controller =
        _controller;

    _controller = null;

    unawaited(
      controller?.close(),
    );
  }
}
