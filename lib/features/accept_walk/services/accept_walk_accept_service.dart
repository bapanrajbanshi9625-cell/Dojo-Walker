import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/walker_availability_service.dart';
import '../../../services/walker_location_service.dart';

class AcceptWalkAcceptService {
  AcceptWalkAcceptService._();

  static final AcceptWalkAcceptService instance =
      AcceptWalkAcceptService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  final WalkerAvailabilityService _availabilityService =
      WalkerAvailabilityService.instance;

  static const double _maxSearchRadiusKm = 3.5;
  static const Duration _offerDuration = Duration(minutes: 3);

  StreamSubscription<Position>? _locationSubscription;

  bool _isAccepting = false;

  // ============================================================
  // WALKER PROFILE
  // ============================================================

  Future<Map<String, dynamic>> _getWalkerProfile(String uid) async {
    final walkerDoc =
        await _firestore.collection('walkers').doc(uid).get();

    final data = walkerDoc.data() ?? <String, dynamic>{};

    final walkerId =
        (data['walkerId'] ?? data['id'] ?? '').toString();

    final walkerName =
        (data['name'] ?? data['walkerName'] ?? 'Dojo Walker').toString();

    final walkerPhone =
        (data['phone'] ?? data['phoneNumber'] ?? '').toString();

    final walkerProfileImage =
        (data['profileImage'] ??
                data['profileImageUrl'] ??
                data['photoUrl'] ??
                '')
            .toString();

    return <String, dynamic>{
      'walkerId': walkerId,
      'walkerName': walkerName,
      'walkerPhone': walkerPhone,
      'walkerProfileImage': walkerProfileImage,
    };
  }

  // ============================================================
  // VALIDATION
  // ============================================================

  bool _isValidWalkId(String requestId) {
    return RegExp(r'^DW\d{6}$').hasMatch(requestId);
  }

  GeoPoint? _getOwnerLocation(Map<String, dynamic> data) {
    final ownerLocation = data['ownerLocation'];

    if (ownerLocation is GeoPoint) {
      return ownerLocation;
    }

    final latitude = _toDouble(
      data['latitude'] ??
          data['lat'] ??
          data['pickupLatitude'],
    );

    final longitude = _toDouble(
      data['longitude'] ??
          data['lng'] ??
          data['pickupLongitude'],
    );

    if (latitude == null || longitude == null) {
      return null;
    }

    return GeoPoint(latitude, longitude);
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

  bool _isOfferExpired(Timestamp? claimedAt) {
    if (claimedAt == null) {
      return true;
    }

    final claimedTime = claimedAt.toDate();

    return DateTime.now().difference(claimedTime) >= _offerDuration;
  }

  double _distanceKm(
    Position walkerPosition,
    GeoPoint ownerLocation,
  ) {
    final distanceMeters = Geolocator.distanceBetween(
      walkerPosition.latitude,
      walkerPosition.longitude,
      ownerLocation.latitude,
      ownerLocation.longitude,
    );

    return distanceMeters / 1000.0;
  }

  // ============================================================
  // ACCEPT WALK
  // ============================================================

  Future<bool> acceptWalk(String requestId) async {
    if (_isAccepting) {
      return false;
    }

    if (!_isValidWalkId(requestId)) {
      debugPrint(
        'AcceptWalkAcceptService: invalid walk id: $requestId',
      );
      return false;
    }

    // ----------------------------------------------------------
    // Availability guards
    // ----------------------------------------------------------

    if (!_availabilityService.isOnline) {
      debugPrint(
        'AcceptWalkAcceptService: walker is offline.',
      );
      return false;
    }

    if (!_availabilityService.isInstaWalkSelected) {
      debugPrint(
        'AcceptWalkAcceptService: Insta Walk is not selected.',
      );
      return false;
    }

    if (!_availabilityService.isInstaWalkSearching) {
      debugPrint(
        'AcceptWalkAcceptService: Insta Walk search is not active.',
      );
      return false;
    }

    if (_availabilityService.isActiveWalk) {
      debugPrint(
        'AcceptWalkAcceptService: walker already has an active walk.',
      );
      return false;
    }

    if (!_availabilityService.canPerformWalkAction()) {
      debugPrint(
        'AcceptWalkAcceptService: walk action is not available.',
      );
      return false;
    }

    final user = _auth.currentUser;

    if (user == null) {
      debugPrint(
        'AcceptWalkAcceptService: no authenticated user.',
      );
      return false;
    }

    final walkerUid = user.uid;

    final currentPosition = _locationService.currentPosition;

    if (currentPosition == null) {
      debugPrint(
        'AcceptWalkAcceptService: current walker location unavailable.',
      );
      return false;
    }

    _isAccepting = true;

    try {
      final walkerProfile = await _getWalkerProfile(walkerUid);

      final walkerId =
          (walkerProfile['walkerId'] ?? '').toString();

      if (walkerId.isEmpty) {
        debugPrint(
          'AcceptWalkAcceptService: walkerId unavailable.',
        );
        return false;
      }

      final requestRef =
          _firestore.collection('walk_request').doc(requestId);

      // ========================================================
      // ATOMIC ACCEPT
      // ========================================================

      await _firestore.runTransaction((transaction) async {
        final requestSnapshot =
            await transaction.get(requestRef);

        if (!requestSnapshot.exists) {
          throw StateError(
            'Walk request no longer exists.',
          );
        }

        final data =
            requestSnapshot.data() ?? <String, dynamic>{};

        final status =
            (data['status'] ?? '').toString().toLowerCase();

        if (status != 'searching') {
          throw StateError(
            'Walk request is no longer searching.',
          );
        }

        // ------------------------------------------------------
        // Current incoming Walker must be this Walker
        // ------------------------------------------------------

        final incomingWalkerUid =
            (data['incomingWalkerUid'] ?? '').toString();

        if (incomingWalkerUid != walkerUid) {
          throw StateError(
            'This walk offer belongs to another Walker.',
          );
        }

        // ------------------------------------------------------
        // 3-minute offer validation
        // ------------------------------------------------------

        final claimedAtValue = data['incomingClaimedAt'];

        Timestamp? claimedAt;

        if (claimedAtValue is Timestamp) {
          claimedAt = claimedAtValue;
        }

        if (_isOfferExpired(claimedAt)) {
          final rejectionRef = requestRef
              .collection('rejections')
              .doc(walkerId);

          transaction.set(
            rejectionRef,
            <String, dynamic>{
              'walkerId': walkerId,
              'walkerUid': walkerUid,
              'type': 'timeout',
              'expiredAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );

          transaction.update(
            requestRef,
            <String, dynamic>{
              'incomingWalkerUid': FieldValue.delete(),
              'incomingWalkerId': FieldValue.delete(),
              'incomingClaimedAt': FieldValue.delete(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );

          throw StateError(
            'Walk offer expired after 3 minutes.',
          );
        }

        // ------------------------------------------------------
        // This Walker must not already have rejected/timed out
        // ------------------------------------------------------

        final rejectionRef = requestRef
            .collection('rejections')
            .doc(walkerId);

        final rejectionSnapshot =
            await transaction.get(rejectionRef);

        if (rejectionSnapshot.exists) {
          throw StateError(
            'This Walker is already blocked for this request.',
          );
        }

        // ------------------------------------------------------
        // Owner location
        // ------------------------------------------------------

        final ownerLocation = _getOwnerLocation(data);

        if (ownerLocation == null) {
          throw StateError(
            'Owner location is unavailable.',
          );
        }

        // ------------------------------------------------------
        // 3.5 KM distance re-check
        // ------------------------------------------------------

        final distanceKm = _distanceKm(
          currentPosition,
          ownerLocation,
        );

        if (distanceKm > _maxSearchRadiusKm) {
          throw StateError(
            'Owner is outside the 3.5 km search radius.',
          );
        }

        // ------------------------------------------------------
        // Accept
        // ------------------------------------------------------

        transaction.update(
          requestRef,
          <String, dynamic>{
            'requestId': requestId,
            'status': 'accepted',

            'walkerId': walkerId,
            'walkerUid': walkerUid,
            'walkerName': walkerProfile['walkerName'],
            'walkerPhone': walkerProfile['walkerPhone'],
            'walkerProfileImage':
                walkerProfile['walkerProfileImage'],

            'acceptedBy': walkerId,
            'acceptedByUid': walkerUid,
            'acceptedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      // ========================================================
      // ACCEPT SUCCESS
      // ========================================================

      // Search must stop, but Walker remains ONLINE.
      _availabilityService.stopInstaWalkSearch();

      // Keep backend search state synchronized.
      try {
        await _firestore
            .collection('users')
            .doc(walkerUid)
            .set(
          <String, dynamic>{
            'instaWalkSearching': false,
            'instaWalkSearchUpdatedAt':
                FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        // Accept has already succeeded.
        // Do not undo the walk.
        debugPrint(
          'AcceptWalkAcceptService: failed to sync search state: $e',
        );
      }

      // Active walk is now locked.
      // GPS remains ON.
      await _availabilityService.setActiveWalk(true);

      // Start listening to walker location updates.
      // This does NOT start or stop GPS.
      await _startLocationUpdates(requestId);

      return true;
    } catch (e) {
      debugPrint(
        'AcceptWalkAcceptService.acceptWalk error: $e',
      );
      return false;
    } finally {
      _isAccepting = false;
    }
  }

  // ============================================================
  // WALKER LOCATION UPDATES
  // ============================================================

  Future<void> _startLocationUpdates(String requestId) async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    final requestRef =
        _firestore.collection('walk_request').doc(requestId);

    // Immediately publish current location.
    final initialPosition = _locationService.currentPosition;

    if (initialPosition != null) {
      await _writeLocation(
        requestRef,
        initialPosition,
      );
    }

    _locationSubscription = _locationService.locationStream.listen(
      (position) async {
        try {
          // Do not control GPS here.
          // WalkerLocationService remains the sole GPS owner.

          final availability = _availabilityService;

          if (!availability.isOnline ||
              !availability.isActiveWalk) {
            return;
          }

          await _writeLocation(
            requestRef,
            position,
          );
        } catch (e) {
          debugPrint(
            'AcceptWalkAcceptService location update error: $e',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'AcceptWalkAcceptService location stream error: $error',
        );
      },
    );
  }

  Future<void> _writeLocation(
    DocumentReference<Map<String, dynamic>> requestRef,
    Position position,
  ) async {
    await requestRef.update(
      <String, dynamic>{
        'walkerLocation': GeoPoint(
          position.latitude,
          position.longitude,
        ),
        'walkerHeading': position.heading,
        'walkerSpeed': position.speed,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await _locationSubscription?.cancel();
    _locationSubscription = null;

    // IMPORTANT:
    // Never stop WalkerLocationService here.
    // GPS lifecycle belongs exclusively to WalkerLocationService.
  }
}
