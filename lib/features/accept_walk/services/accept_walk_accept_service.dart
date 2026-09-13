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

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  final WalkerAvailabilityService _availabilityService =
      WalkerAvailabilityService.instance;

  static const double _maxSearchRadiusKm = 3.5;

  static const Duration _offerDuration =
      Duration(minutes: 3);

  StreamSubscription<Position>? _locationSubscription;

  bool _isAccepting = false;

  // ============================================================
  // WALKER PROFILE
  // ============================================================

  Future<Map<String, dynamic>> _getWalkerProfile(
    String uid,
  ) async {
    final DocumentSnapshot<Map<String, dynamic>> walkerDoc =
        await _firestore
            .collection('walkers')
            .doc(uid)
            .get();

    final Map<String, dynamic> data =
        walkerDoc.data() ?? <String, dynamic>{};

    final String walkerName =
        (data['name'] ??
                data['walkerName'] ??
                'Dojo Walker')
            .toString()
            .trim();

    final String walkerPhone =
        (data['phone'] ??
                data['phoneNumber'] ??
                '')
            .toString()
            .trim();

    final String walkerProfileImage =
        (data['profileImage'] ??
                data['profileImageUrl'] ??
                data['photoUrl'] ??
                '')
            .toString()
            .trim();

    return <String, dynamic>{
      // IMPORTANT:
      // Walker ID is Firebase Auth UID.
      'walkerId': uid,
      'walkerName': walkerName.isEmpty
          ? 'Dojo Walker'
          : walkerName,
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

  GeoPoint? _getOwnerLocation(
    Map<String, dynamic> data,
  ) {
    final dynamic ownerLocation =
        data['ownerLocation'];

    if (ownerLocation is GeoPoint) {
      return ownerLocation;
    }

    final double? latitude = _toDouble(
      data['latitude'] ??
          data['lat'] ??
          data['pickupLatitude'],
    );

    final double? longitude = _toDouble(
      data['longitude'] ??
          data['lng'] ??
          data['pickupLongitude'],
    );

    if (latitude == null || longitude == null) {
      return null;
    }

    return GeoPoint(
      latitude,
      longitude,
    );
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

  bool _isOfferExpired(
    Timestamp? claimedAt,
  ) {
    if (claimedAt == null) {
      return true;
    }

    final DateTime claimedTime =
        claimedAt.toDate();

    return DateTime.now()
            .difference(claimedTime) >=
        _offerDuration;
  }

  double _distanceKm(
    Position walkerPosition,
    GeoPoint ownerLocation,
  ) {
    final double distanceMeters =
        Geolocator.distanceBetween(
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

  Future<bool> acceptWalk(
    String requestId,
  ) async {
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

    final User? user =
        _auth.currentUser;

    if (user == null) {
      debugPrint(
        'AcceptWalkAcceptService: no authenticated user.',
      );
      return false;
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      debugPrint(
        'AcceptWalkAcceptService: walker UID is empty.',
      );
      return false;
    }

    // IMPORTANT:
    // Walker ID is the same as Firebase Auth UID.
    final String walkerId =
        walkerUid;

    final Position? currentPosition =
        _locationService.currentPosition;

    if (currentPosition == null) {
      debugPrint(
        'AcceptWalkAcceptService: current walker location unavailable.',
      );
      return false;
    }

    _isAccepting = true;

    try {
      final Map<String, dynamic> walkerProfile =
          await _getWalkerProfile(
        walkerUid,
      );

      final DocumentReference<Map<String, dynamic>>
          requestRef =
          _firestore
              .collection('walk_request')
              .doc(requestId);

      // ========================================================
      // ATOMIC ACCEPT
      // ========================================================

      await _firestore.runTransaction(
        (Transaction transaction) async {
          final DocumentSnapshot<Map<String, dynamic>>
              requestSnapshot =
              await transaction.get(
            requestRef,
          );

          if (!requestSnapshot.exists) {
            throw StateError(
              'Walk request no longer exists.',
            );
          }

          final Map<String, dynamic> data =
              requestSnapshot.data() ??
                  <String, dynamic>{};

          final String status =
              (data['status'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();

          if (status != 'searching') {
            throw StateError(
              'Walk request is no longer searching.',
            );
          }

          // ----------------------------------------------------
          // Current incoming Walker must be this Walker
          // ----------------------------------------------------

          final String incomingWalkerUid =
              (data['incomingWalkerUid'] ?? '')
                  .toString()
                  .trim();

          if (incomingWalkerUid != walkerUid) {
            throw StateError(
              'This walk offer belongs to another Walker.',
            );
          }

          // ----------------------------------------------------
          // 3-minute offer validation
          // ----------------------------------------------------

          final dynamic claimedAtValue =
              data['incomingClaimedAt'];

          Timestamp? claimedAt;

          if (claimedAtValue is Timestamp) {
            claimedAt = claimedAtValue;
          }

          if (_isOfferExpired(claimedAt)) {
            final DocumentReference<
                    Map<String, dynamic>>
                rejectionRef =
                requestRef
                    .collection('rejections')
                    .doc(walkerId);

            transaction.set(
              rejectionRef,
              <String, dynamic>{
                'walkerId': walkerId,
                'walkerUid': walkerUid,
                'type': 'timeout',
                'expiredAt':
                    FieldValue.serverTimestamp(),
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
              SetOptions(
                merge: true,
              ),
            );

            transaction.update(
              requestRef,
              <String, dynamic>{
                'incomingWalkerUid':
                    FieldValue.delete(),
                'incomingWalkerId':
                    FieldValue.delete(),
                'incomingClaimedAt':
                    FieldValue.delete(),
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
            );

            throw StateError(
              'Walk offer expired after 3 minutes.',
            );
          }

          // ----------------------------------------------------
          // Rejection check
          // ----------------------------------------------------

          final DocumentReference<
                  Map<String, dynamic>>
              rejectionRef =
              requestRef
                  .collection('rejections')
                  .doc(walkerId);

          final DocumentSnapshot<
                  Map<String, dynamic>>
              rejectionSnapshot =
              await transaction.get(
            rejectionRef,
          );

          if (rejectionSnapshot.exists) {
            throw StateError(
              'This Walker is already blocked for this request.',
            );
          }

          // ----------------------------------------------------
          // Owner location
          // ----------------------------------------------------

          final GeoPoint? ownerLocation =
              _getOwnerLocation(data);

          if (ownerLocation == null) {
            throw StateError(
              'Owner location is unavailable.',
            );
          }

          // ----------------------------------------------------
          // 3.5 KM distance re-check
          // ----------------------------------------------------

          final double distanceKm =
              _distanceKm(
            currentPosition,
            ownerLocation,
          );

          if (distanceKm > _maxSearchRadiusKm) {
            throw StateError(
              'Owner is outside the 3.5 km search radius.',
            );
          }

          // ----------------------------------------------------
          // ACCEPT
          // ----------------------------------------------------
          //
          // IMPORTANT:
          // The canonical Walker ID is Auth UID.
          //
          // This update is intentionally done directly on
          // walk_request/{DW######}.
          //
          // status       -> accepted
          // walkerUid    -> Firebase Auth UID
          // walkerId     -> Firebase Auth UID
          // acceptedBy   -> Firebase Auth UID
          // acceptedByUid-> Firebase Auth UID
          //
          // No liveWalkSessions document is created here.
          // That happens at REACHED.
          // ----------------------------------------------------

          transaction.update(
            requestRef,
            <String, dynamic>{
              'requestId': requestId,
              'status': 'accepted',

              'walkerId': walkerId,
              'walkerUid': walkerUid,

              'walkerName':
                  walkerProfile['walkerName'],
              'walkerPhone':
                  walkerProfile['walkerPhone'],
              'walkerProfileImage':
                  walkerProfile[
                      'walkerProfileImage'],

              'acceptedBy': walkerUid,
              'acceptedByUid': walkerUid,

              'acceptedAt':
                  FieldValue.serverTimestamp(),
              'updatedAt':
                  FieldValue.serverTimestamp(),

              // The offer is consumed after acceptance.
              'incomingWalkerUid':
                  FieldValue.delete(),
              'incomingWalkerId':
                  FieldValue.delete(),
              'incomingClaimedAt':
                  FieldValue.delete(),
            },
          );
        },
      );

      // ========================================================
      // ACCEPT SUCCESS
      // ========================================================

      debugPrint(
        'AcceptWalkAcceptService: ACCEPTED $requestId '
        'by walkerUid=$walkerUid',
      );

      // --------------------------------------------------------
      // Search OFF
      // Walker remains ONLINE.
      // --------------------------------------------------------

      _availabilityService
          .stopInstaWalkSearch();

      // --------------------------------------------------------
      // Backend search state
      // --------------------------------------------------------

      try {
        await _firestore
            .collection('users')
            .doc(walkerUid)
            .set(
          <String, dynamic>{
            'instaWalkSearching': false,
            'instaWalkSearchUpdatedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
          SetOptions(
            merge: true,
          ),
        );
      } catch (error) {
        // Accept already succeeded.
        debugPrint(
          'AcceptWalkAcceptService: '
          'failed to sync search state: $error',
        );
      }

      // --------------------------------------------------------
      // Active walk ON / LOCKED
      // GPS remains ON.
      // --------------------------------------------------------

      await _availabilityService
          .setActiveWalk(true);

      // --------------------------------------------------------
      // Continue publishing walker location.
      // This service does NOT start or stop GPS.
      // --------------------------------------------------------

      await _startLocationUpdates(
        requestId,
      );

      return true;
    } catch (error) {
      debugPrint(
        'AcceptWalkAcceptService.acceptWalk error: $error',
      );

      return false;
    } finally {
      _isAccepting = false;
    }
  }

  // ============================================================
  // WALKER LOCATION UPDATES
  // ============================================================

  Future<void> _startLocationUpdates(
    String requestId,
  ) async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;

    final DocumentReference<Map<String, dynamic>>
        requestRef =
        _firestore
            .collection('walk_request')
            .doc(requestId);

    // ----------------------------------------------------------
    // Immediately publish current location.
    // ----------------------------------------------------------

    final Position? initialPosition =
        _locationService.currentPosition;

    if (initialPosition != null) {
      await _writeLocation(
        requestRef,
        initialPosition,
      );
    }

    // ----------------------------------------------------------
    // Listen to canonical GPS source.
    // ----------------------------------------------------------

    _locationSubscription =
        _locationService.locationStream.listen(
      (Position position) async {
        try {
          // IMPORTANT:
          // Do not start or stop GPS here.
          // WalkerLocationService owns GPS lifecycle.

          final WalkerAvailabilityService
              availability =
              _availabilityService;

          if (!availability.isOnline ||
              !availability.isActiveWalk) {
            return;
          }

          await _writeLocation(
            requestRef,
            position,
          );
        } catch (error) {
          debugPrint(
            'AcceptWalkAcceptService '
            'location update error: $error',
          );
        }
      },
      onError: (Object error) {
        debugPrint(
          'AcceptWalkAcceptService '
          'location stream error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // WRITE WALKER LOCATION
  // ============================================================

  Future<void> _writeLocation(
    DocumentReference<Map<String, dynamic>>
        requestRef,
    Position position,
  ) async {
    await requestRef.update(
      <String, dynamic>{
        'walkerLocation': GeoPoint(
          position.latitude,
          position.longitude,
        ),
        'walkerHeading':
            position.heading,
        'walkerSpeed':
            position.speed,
        'locationUpdatedAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
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
    // GPS lifecycle belongs exclusively to
    // WalkerLocationService.
  }
}
