// File:
// lib/features/incoming_walk/services/insta_walk_request_service.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../services/walker_availability_service.dart';
import '../../../services/walker_location_service.dart';
import '../models/insta_walk_request.dart';

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

  bool _disposed = false;
  bool _availabilityListenerAttached = false;

  int _listenerGeneration = 0;

  Future<void> _restartQueue = Future<void>.value();

  Stream<List<InstaWalkRequest>> pendingRequestsStream() {
    _controller ??= StreamController<List<InstaWalkRequest>>.broadcast(
      onListen: _handleControllerListen,
      onCancel: _handleControllerCancel,
    );

    return _controller!.stream;
  }

  void _handleControllerListen() {
    if (_disposed) return;

    _attachAvailabilityListener();

    _authSubscription ??= _auth.authStateChanges().listen((_) {
      _scheduleListenerRefresh('auth_changed');
    });

    _scheduleListenerRefresh('stream_listened');
  }

  Future<void> _handleControllerCancel() async {
    await _stopRequestListener();

    await _authSubscription?.cancel();
    _authSubscription = null;

    _detachAvailabilityListener();

    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _attachAvailabilityListener() {
    if (_availabilityListenerAttached) return;

    _availabilityListenerAttached = true;
    _availabilityService.addListener(_onAvailabilityChanged);
  }

  void _detachAvailabilityListener() {
    if (!_availabilityListenerAttached) return;

    _availabilityListenerAttached = false;
    _availabilityService.removeListener(_onAvailabilityChanged);
  }

  void _onAvailabilityChanged() {
    if (_disposed) return;

    _scheduleListenerRefresh('availability_changed');
  }

  void _scheduleListenerRefresh(String reason) {
    if (_disposed || _controller == null || _controller!.isClosed) {
      return;
    }

    final int generation = ++_listenerGeneration;

    _restartQueue = _restartQueue.then((_) async {
      if (_disposed) return;

      await _syncRequestListener(
        generation: generation,
        reason: reason,
      );
    }).catchError((Object error, StackTrace stackTrace) {
      debugPrint(
        '[InstaWalkRequestService] listener restart error: '
        '$error',
      );
      debugPrintStack(stackTrace: stackTrace);
    });
  }

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
        '[InstaWalkRequestService] STALE SYNC '
        'generation=$generation '
        'latest=$_listenerGeneration',
      );
      return;
    }

    if (!_canReceiveInstaWalkRequests()) {
      debugPrint(
        '[InstaWalkRequestService] FIRESTORE LISTENER OFF '
        'because receive conditions are not satisfied.',
      );

      _emitEmpty();
      return;
    }

    final String? walkerId = await _getWalkerId();

    if (_disposed) return;

    if (generation != _listenerGeneration) {
      debugPrint(
        '[InstaWalkRequestService] STALE AFTER WALKER ID '
        'generation=$generation '
        'latest=$_listenerGeneration',
      );
      return;
    }

    if (walkerId == null || walkerId.trim().isEmpty) {
      debugPrint(
        '[InstaWalkRequestService] WALKER ID NOT FOUND. '
        'Firestore listener not started.',
      );

      _emitEmpty();
      return;
    }

    debugPrint(
      '[InstaWalkRequestService] FIRESTORE LISTENER STARTING '
      'walkerId=$walkerId',
    );

    final Query<Map<String, dynamic>> query = _firestore
        .collection('walk_request')
        .where('status', isEqualTo: 'searching');

    _requestSubscription = query.snapshots().listen(
      (snapshot) {
        unawaited(
          _processSnapshot(
            snapshot,
            walkerId,
            generation,
          ),
        );
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint(
          '[InstaWalkRequestService] FIRESTORE LISTENER ERROR: $error',
        );
        debugPrintStack(stackTrace: stackTrace);

        if (!_disposed &&
            _canReceiveInstaWalkRequests() &&
            generation == _listenerGeneration) {
          _scheduleListenerRefresh('firestore_error');
        }
      },
      cancelOnError: false,
    );

    debugPrint(
      '[InstaWalkRequestService] FIRESTORE LISTENER ACTIVE '
      'walkerId=$walkerId',
    );
  }

  Future<void> _processSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
    String walkerId,
    int generation,
  ) async {
    if (_disposed) return;

    if (generation != _listenerGeneration) {
      return;
    }

    if (!_canReceiveInstaWalkRequests()) {
      _emitEmpty();
      return;
    }

    debugPrint(
      '[InstaWalkRequestService] REQUEST SNAPSHOT '
      'count=${snapshot.docs.length}',
    );

    if (snapshot.docs.isEmpty) {
      _emitEmpty();
      return;
    }

    final List<InstaWalkRequest> validRequests = <InstaWalkRequest>[];

    for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
        in snapshot.docs) {
      if (_disposed) return;

      if (generation != _listenerGeneration) {
        return;
      }

      try {
        final InstaWalkRequest? request =
            await _processSingleRequest(doc, walkerId);

        if (request != null) {
          validRequests.add(request);
        }
      } catch (error, stackTrace) {
        debugPrint(
          '[InstaWalkRequestService] REQUEST PROCESS ERROR '
          'id=${doc.id}: $error',
        );
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (_disposed) return;

    if (generation != _listenerGeneration) {
      return;
    }

    validRequests.sort(
      (InstaWalkRequest a, InstaWalkRequest b) {
        final DateTime aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final DateTime bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

        return aTime.compareTo(bTime);
      },
    );

    debugPrint(
      '[InstaWalkRequestService] VALID REQUESTS '
      'count=${validRequests.length}',
    );

    if (validRequests.isNotEmpty) {
      debugPrint(
        '[InstaWalkRequestService] REQUEST READY '
        'id=${validRequests.first.requestId}',
      );
    }

    _emit(validRequests);
  }

  Future<InstaWalkRequest?> _processSingleRequest(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    String walkerId,
  ) async {
    final Map<String, dynamic> data = doc.data();

    final String requestId = doc.id;

    final String status =
        (data['status'] ?? '').toString().trim().toLowerCase();

    if (status != 'searching') {
      return null;
    }

    final String? existingClaimWalkerUid =
        _cleanString(data['incomingWalkerUid']);

    final String currentUid = _auth.currentUser?.uid ?? '';

    if (existingClaimWalkerUid != null &&
        existingClaimWalkerUid.isNotEmpty &&
        existingClaimWalkerUid != currentUid) {
      debugPrint(
        '[InstaWalkRequestService] REQUEST ALREADY CLAIMED '
        'id=$requestId',
      );
      return null;
    }

    final DocumentReference<Map<String, dynamic>> requestRef =
        _firestore.collection('walk_request').doc(requestId);

    final DocumentReference<Map<String, dynamic>> rejectionRef =
        requestRef.collection('rejections').doc(walkerId);

    final DocumentSnapshot<Map<String, dynamic>> rejectionSnapshot =
        await rejectionRef.get();

    if (rejectionSnapshot.exists) {
      debugPrint(
        '[InstaWalkRequestService] REQUEST REJECTED BEFORE '
        'id=$requestId',
      );
      return null;
    }

    final GeoPoint? ownerLocation = _readGeoPoint(data['ownerLocation']);

    if (ownerLocation == null) {
      debugPrint(
        '[InstaWalkRequestService] OWNER LOCATION MISSING '
        'id=$requestId',
      );
      return null;
    }

    final GeoPoint? walkerLocation = _locationService.currentPosition != null
        ? GeoPoint(
            _locationService.currentPosition!.latitude,
            _locationService.currentPosition!.longitude,
          )
        : null;

    if (walkerLocation == null) {
      debugPrint(
        '[InstaWalkRequestService] WALKER LOCATION MISSING '
        'id=$requestId',
      );
      return null;
    }

    final double distanceKm = _distanceInKm(
      walkerLocation.latitude,
      walkerLocation.longitude,
      ownerLocation.latitude,
      ownerLocation.longitude,
    );

    debugPrint(
      '[InstaWalkRequestService] DISTANCE '
      'id=$requestId '
      'distance=${distanceKm.toStringAsFixed(2)}km '
      'radius=$_searchRadiusKm km',
    );

    if (distanceKm > _searchRadiusKm) {
      return null;
    }

    final bool claimed = await _claimRequest(
      requestRef: requestRef,
      walkerId: walkerId,
      walkerUid: currentUid,
    );

    if (!claimed) {
      debugPrint(
        '[InstaWalkRequestService] CLAIM FAILED '
        'id=$requestId',
      );
      return null;
    }

    debugPrint(
      '[InstaWalkRequestService] CLAIM SUCCESS '
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

  Future<bool> _claimRequest({
    required DocumentReference<Map<String, dynamic>> requestRef,
    required String walkerId,
    required String walkerUid,
  }) async {
    try {
      return await _firestore.runTransaction<bool>(
        (transaction) async {
          final DocumentSnapshot<Map<String, dynamic>> snapshot =
              await transaction.get(requestRef);

          if (!snapshot.exists) {
            return false;
          }

          final Map<String, dynamic> data =
              snapshot.data() ?? <String, dynamic>{};

          final String status =
              (data['status'] ?? '').toString().trim().toLowerCase();

          if (status != 'searching') {
            return false;
          }

          final String? existingUid =
              _cleanString(data['incomingWalkerUid']);

          if (existingUid != null &&
              existingUid.isNotEmpty &&
              existingUid != walkerUid) {
            return false;
          }

          transaction.update(
            requestRef,
            <String, dynamic>{
              'incomingWalkerUid': walkerUid,
              'incomingWalkerId': walkerId,
              'incomingClaimedAt': FieldValue.serverTimestamp(),
            },
          );

          return true;
        },
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[InstaWalkRequestService] CLAIM TRANSACTION ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

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
          final DocumentReference<Map<String, dynamic>> requestRef =
              _firestore.collection('walk_request').doc(requestId);

          final DocumentReference<Map<String, dynamic>> rejectionRef =
              requestRef.collection('rejections').doc(walkerId);

          await _firestore.runTransaction<void>(
            (transaction) async {
              final DocumentSnapshot<Map<String, dynamic>> snapshot =
                  await transaction.get(requestRef);

              if (!snapshot.exists) return;

              final Map<String, dynamic> data =
                  snapshot.data() ?? <String, dynamic>{};

              final String? claimedUid =
                  _cleanString(data['incomingWalkerUid']);

              if (claimedUid != walkerUid) {
                return;
              }

              final String status =
                  (data['status'] ?? '').toString().trim().toLowerCase();

              if (status != 'searching') {
                return;
              }

              transaction.set(
                rejectionRef,
                <String, dynamic>{
                  'walkerId': walkerId,
                  'walkerUid': walkerUid,
                  'createdAt': FieldValue.serverTimestamp(),
                },
              );

              transaction.update(
                requestRef,
                <String, dynamic>{
                  'incomingWalkerUid': null,
                  'incomingWalkerId': null,
                  'incomingClaimedAt': null,
                },
              );
            },
          );

          debugPrint(
            '[InstaWalkRequestService] CLAIM TIMEOUT '
            'id=$requestId',
          );
        } catch (error, stackTrace) {
          debugPrint(
            '[InstaWalkRequestService] CLAIM TIMEOUT ERROR '
            'id=$requestId: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
        }
      },
    );
  }

  bool _canReceiveInstaWalkRequests() {
    final bool online = _availabilityService.isOnline;
    final bool insta = _availabilityService.isInstaWalkSelected;
    final bool searching = _availabilityService.isInstaWalkSearching;
    final bool activeWalk = _availabilityService.isActiveWalk;
    final bool gps = _locationService.isTracking;

    final bool result =
        online &&
        insta &&
        searching &&
        !activeWalk &&
        gps;

    return result;
  }

  Future<String?> _getWalkerId() async {
    final User? user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        '[InstaWalkRequestService] AUTH USER NOT FOUND',
      );
      return null;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('walkers').doc(user.uid).get();

      if (!snapshot.exists) {
        debugPrint(
          '[InstaWalkRequestService] WALKER DOCUMENT NOT FOUND',
        );
        return user.uid;
      }

      final Map<String, dynamic> data =
          snapshot.data() ?? <String, dynamic>{};

      final String? walkerId =
          _cleanString(data['walkerId']) ??
          _cleanString(data['uid']) ??
          _cleanString(data['id']);

      return walkerId ?? user.uid;
    } catch (error, stackTrace) {
      debugPrint(
        '[InstaWalkRequestService] WALKER ID ERROR: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      return user.uid;
    }
  }

  Future<void> _stopRequestListener() async {
    await _requestSubscription?.cancel();
    _requestSubscription = null;
  }

  void _emit(List<InstaWalkRequest> requests) {
    if (_disposed || _controller == null || _controller!.isClosed) {
      return;
    }

    _controller!.add(requests);
  }

  void _emitEmpty() {
    _emit(<InstaWalkRequest>[]);
  }

  GeoPoint? _readGeoPoint(dynamic value) {
    if (value is GeoPoint) {
      return value;
    }

    if (value is Map) {
      final dynamic latitude = value['latitude'];
      final dynamic longitude = value['longitude'];

      final double? lat = _toDouble(latitude);
      final double? lng = _toDouble(longitude);

      if (lat != null && lng != null) {
        return GeoPoint(lat, lng);
      }
    }

    return null;
  }

  double _distanceInKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadiusKm = 6371.0;

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        math.pow(math.sin(dLat / 2), 2).toDouble() +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.pow(math.sin(dLon / 2), 2).toDouble();

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  double? _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  String? _cleanString(dynamic value) {
    if (value == null) return null;

    final String text = value.toString().trim();

    if (text.isEmpty) return null;

    return text;
  }

  void dispose() {
    if (_disposed) return;

    _disposed = true;

    _listenerGeneration++;

    _refreshTimer?.cancel();
    _refreshTimer = null;

    _detachAvailabilityListener();

    unawaited(_requestSubscription?.cancel());
    _requestSubscription = null;

    unawaited(_authSubscription?.cancel());
    _authSubscription = null;

    final StreamController<List<InstaWalkRequest>>? controller =
        _controller;

    _controller = null;

    unawaited(controller?.close());
  }
}
