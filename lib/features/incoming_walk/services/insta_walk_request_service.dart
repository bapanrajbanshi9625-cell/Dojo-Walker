import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/walker_availability_service.dart';
import '../../../services/walker_location_service.dart';
import '../../insta_walk/models/insta_walk_request.dart';

/// ============================================================
/// INCOMING WALK REQUEST SERVICE
///
/// Responsibilities:
///
/// - Discover searching Insta Walk requests
/// - Only discover when:
///     ONLINE
///     + INSTA WALK selected
///     + INSTA SEARCH ON
///     + no active walk
/// - Only discover requests within 3.5 km
/// - Claim one request for one Walker
/// - Give each claimed request a 3-minute offer window
/// - Automatically timeout the offer after 3 minutes
/// - Permanently skip requests timed out by this Walker
/// - Permanently skip requests rejected by this Walker
/// - Release the request so another Walker can receive it
///
/// GPS lifecycle:
///
///     WalkerAvailabilityService
///
/// owns GPS.
///
/// This service NEVER starts or stops GPS.
///
/// Location source:
///
///     WalkerLocationService.instance
///
/// ============================================================

class InstaWalkRequestService {
  InstaWalkRequestService._();

  static final InstaWalkRequestService instance =
      InstaWalkRequestService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final WalkerAvailabilityService _availabilityService =
      WalkerAvailabilityService.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  // ============================================================
  // CONFIGURATION
  // ============================================================

  static const double _maxSearchRadiusKm = 3.5;

  static const Duration _offerDuration =
      Duration(minutes: 3);

  // ============================================================
  // ACTIVE OFFER TIMERS
  //
  // One timer per request currently claimed by this Walker.
  // ============================================================

  final Map<String, Timer> _offerTimers =
      <String, Timer>{};

  // ============================================================
  // COLLECTIONS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _walkRequests {
    return _firestore.collection('walk_request');
  }

  CollectionReference<Map<String, dynamic>> get _walkers {
    return _firestore.collection('walkers');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get currentUser {
    return _auth.currentUser;
  }

  String? get currentWalkerUid {
    final User? user = _auth.currentUser;

    final String uid =
        user?.uid.trim() ?? '';

    if (uid.isEmpty) {
      return null;
    }

    return uid;
  }

  // ============================================================
  // CURRENT WALKER DOCUMENT
  // ============================================================

  Future<DocumentSnapshot<Map<String, dynamic>>?>
      _getCurrentWalkerDocument() async {
    final String? uid =
        currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>
        snapshot =
        await _walkers.doc(uid).get();

    if (!snapshot.exists) {
      return null;
    }

    return snapshot;
  }

  // ============================================================
  // CURRENT WALKER ID
  // ============================================================

  Future<String?> getCurrentWalkerId() async {
    final String? uid =
        currentWalkerUid;

    if (uid == null) {
      return null;
    }

    final DocumentSnapshot<Map<String, dynamic>>?
        snapshot =
        await _getCurrentWalkerDocument();

    if (snapshot != null) {
      final Map<String, dynamic>? data =
          snapshot.data();

      if (data != null) {
        String walkerId =
            data['walkerId']
                    ?.toString()
                    .trim() ??
                '';

        if (walkerId.isEmpty) {
          walkerId =
              data['Walker ID']
                      ?.toString()
                      .trim() ??
                  '';
        }

        if (walkerId.isNotEmpty) {
          return walkerId;
        }
      }
    }

    return uid;
  }

  // ============================================================
  // AVAILABILITY GUARD
  // ============================================================

  bool _canReceiveInstaWalkRequests() {
    return _availabilityService.isOnline &&
        _availabilityService.isInstaWalkSelected &&
        _availabilityService.isInstaWalkSearching &&
        !_availabilityService.isActiveWalk &&
        _locationService.isTracking;
  }

  // ============================================================
  // WALKER POSITION
  // ============================================================

  Position? get _currentWalkerPosition {
    return _locationService.currentPosition;
  }

  // ============================================================
  // OWNER LOCATION
  // ============================================================

  GeoPoint? _getOwnerLocation(
    Map<String, dynamic> data,
  ) {
    final dynamic ownerLocation =
        data['ownerLocation'];

    if (ownerLocation is GeoPoint) {
      return ownerLocation;
    }

    final double? latitude =
        _toDouble(
      data['latitude'] ??
          data['lat'] ??
          data['pickupLatitude'],
    );

    final double? longitude =
        _toDouble(
      data['longitude'] ??
          data['lng'] ??
          data['pickupLongitude'],
    );

    if (latitude == null ||
        longitude == null) {
      return null;
    }

    return GeoPoint(
      latitude,
      longitude,
    );
  }

  // ============================================================
  // DISTANCE
  // ============================================================

  double _distanceKm({
    required Position walkerPosition,
    required GeoPoint ownerLocation,
  }) {
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
  // WITHIN SEARCH RADIUS
  // ============================================================

  bool _isWithinSearchRadius(
    Map<String, dynamic> data,
  ) {
    final Position? walkerPosition =
        _currentWalkerPosition;

    if (walkerPosition == null) {
      return false;
    }

    final GeoPoint? ownerLocation =
        _getOwnerLocation(data);

    if (ownerLocation == null) {
      return false;
    }

    final double distanceKm =
        _distanceKm(
      walkerPosition: walkerPosition,
      ownerLocation: ownerLocation,
    );

    debugPrint(
      'Insta Walk distance: '
      '${distanceKm.toStringAsFixed(2)} km',
    );

    return distanceKm <=
        _maxSearchRadiusKm;
  }

  // ============================================================
  // TIMESTAMP
  // ============================================================

  DateTime? _timestampToDateTime(
    dynamic value,
  ) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    return null;
  }

  DateTime? _getOfferStartedAt(
    Map<String, dynamic> data,
  ) {
    return _timestampToDateTime(
      data['incomingClaimedAt'],
    );
  }

  // ============================================================
  // OFFER EXPIRED
  // ============================================================

  bool _isOfferExpired(
    Map<String, dynamic> data,
  ) {
    final DateTime? claimedAt =
        _getOfferStartedAt(data);

    if (claimedAt == null) {
      return false;
    }

    return DateTime.now()
            .difference(claimedAt) >=
        _offerDuration;
  }

  // ============================================================
  // SCHEDULE OFFER TIMEOUT
  //
  // Starts/restarts the local 3-minute timer based on the
  // actual incomingClaimedAt timestamp.
  //
  // Firestore transaction remains authoritative.
  // ============================================================

  void _scheduleOfferTimeout({
    required String walkId,
    required String walkerId,
    required String walkerUid,
    DateTime? claimedAt,
  }) {
    final String id =
        walkId.trim();

    final String wid =
        walkerId.trim();

    final String uid =
        walkerUid.trim();

    if (id.isEmpty ||
        wid.isEmpty ||
        uid.isEmpty) {
      return;
    }

    // Cancel any old timer for this request.
    _offerTimers[id]?.cancel();

    final DateTime now =
        DateTime.now();

    Duration remaining;

    if (claimedAt == null) {
      remaining =
          _offerDuration;
    } else {
      final Duration elapsed =
          now.difference(claimedAt);

      if (elapsed >= _offerDuration) {
        remaining =
            Duration.zero;
      } else {
        remaining =
            _offerDuration - elapsed;
      }
    }

    _offerTimers[id] = Timer(
      remaining,
      () async {
        _offerTimers.remove(id);

        await _markTimeout(
          walkId: id,
          walkerId: wid,
          walkerUid: uid,
        );
      },
    );

    debugPrint(
      'Insta Walk offer timer started: '
      '$id | '
      '${remaining.inSeconds}s remaining',
    );
  }

  // ============================================================
  // CANCEL OFFER TIMER
  // ============================================================

  void _cancelOfferTimer(
    String walkId,
  ) {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return;
    }

    _offerTimers[id]?.cancel();
    _offerTimers.remove(id);
  }

  // ============================================================
  // MARK TIMEOUT
  //
  // Existing structure:
  //
  // walk_request/{requestId}/rejections/{walkerId}
  //
  // is reused.
  //
  // Timeout means:
  //
  // This particular Walker must NEVER receive
  // this request again.
  // ============================================================

  Future<void> _markTimeout({
    required String walkId,
    required String walkerId,
    required String walkerUid,
  }) async {
    final String id =
        walkId.trim();

    final String wid =
        walkerId.trim();

    final String uid =
        walkerUid.trim();

    if (id.isEmpty ||
        wid.isEmpty ||
        uid.isEmpty) {
      return;
    }

    final DocumentReference<Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    final DocumentReference<Map<String, dynamic>>
        rejectionRef =
        walkRef
            .collection('rejections')
            .doc(wid);

    try {
      await _firestore.runTransaction(
        (
          Transaction transaction,
        ) async {
          final DocumentSnapshot<Map<String, dynamic>>
              walkSnapshot =
              await transaction.get(
            walkRef,
          );

          if (!walkSnapshot.exists) {
            return;
          }

          final Map<String, dynamic>? data =
              walkSnapshot.data();

          if (data == null) {
            return;
          }

          final String incomingWalkerUid =
              data['incomingWalkerUid']
                      ?.toString()
                      .trim() ??
                  '';

          // ------------------------------------------------------
          // Only the Walker who currently owns the offer can
          // timeout that offer.
          // ------------------------------------------------------

          if (incomingWalkerUid != uid) {
            return;
          }

          final String status =
              data['status']
                      ?.toString()
                      .trim()
                      .toLowerCase() ??
                  '';

          // ------------------------------------------------------
          // If already accepted/reached/completed/cancelled,
          // never mark timeout.
          // ------------------------------------------------------

          if (status != 'searching') {
            return;
          }

          final DateTime? claimedAt =
              _getOfferStartedAt(data);

          if (claimedAt == null) {
            return;
          }

          if (DateTime.now()
                  .difference(claimedAt) <
              _offerDuration) {
            return;
          }

          final DocumentSnapshot<Map<String, dynamic>>
              rejectionSnapshot =
              await transaction.get(
            rejectionRef,
          );

          if (!rejectionSnapshot.exists) {
            transaction.set(
              rejectionRef,
              <String, dynamic>{
                'walkerId': wid,
                'walkerUid': uid,
                'type': 'timeout',
                'expiredAt':
                    FieldValue.serverTimestamp(),
                'updatedAt':
                    FieldValue.serverTimestamp(),
              },
            );
          }

          transaction.update(
            walkRef,
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
        },
      );

      debugPrint(
        'Insta Walk offer timed out: '
        '$id for Walker $wid',
      );
    } catch (e, stackTrace) {
      debugPrint(
        'Unable to mark Insta Walk timeout: $e',
      );

      debugPrintStack(
        stackTrace: stackTrace,
      );
    }
  }

  // ============================================================
  // CLAIM INCOMING REQUEST
  // ============================================================

  Future<bool> _claimIncomingRequest({
    required String walkId,
    required String walkerUid,
    required String walkerId,
  }) async {
    if (!_canReceiveInstaWalkRequests()) {
      return false;
    }

    final String id =
        walkId.trim();

    final String uid =
        walkerUid.trim();

    final String wid =
        walkerId.trim();

    if (id.isEmpty ||
        uid.isEmpty ||
        wid.isEmpty) {
      return false;
    }

    final Position? walkerPosition =
        _currentWalkerPosition;

    if (walkerPosition == null) {
      return false;
    }

    final DocumentReference<Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    final DocumentReference<Map<String, dynamic>>
        rejectionRef =
        walkRef
            .collection('rejections')
            .doc(wid);

    return _firestore.runTransaction<bool>(
      (
        Transaction transaction,
      ) async {
        if (!_canReceiveInstaWalkRequests()) {
          return false;
        }

        final DocumentSnapshot<Map<String, dynamic>>
            walkSnapshot =
            await transaction.get(
          walkRef,
        );

        if (!walkSnapshot.exists) {
          return false;
        }

        final Map<String, dynamic>? data =
            walkSnapshot.data();

        if (data == null) {
          return false;
        }

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (status != 'searching') {
          return false;
        }

        // --------------------------------------------------------
        // Walker-specific permanent skip
        // --------------------------------------------------------

        final DocumentSnapshot<Map<String, dynamic>>
            rejectionSnapshot =
            await transaction.get(
          rejectionRef,
        );

        if (rejectionSnapshot.exists) {
          return false;
        }

        // --------------------------------------------------------
        // Owner location
        // --------------------------------------------------------

        final GeoPoint? ownerLocation =
            _getOwnerLocation(data);

        if (ownerLocation == null) {
          debugPrint(
            'Insta Walk $id skipped: '
            'Owner location missing.',
          );

          return false;
        }

        // --------------------------------------------------------
        // 3.5 KM distance check
        // --------------------------------------------------------

        final double distanceKm =
            _distanceKm(
          walkerPosition: walkerPosition,
          ownerLocation: ownerLocation,
        );

        if (distanceKm >
            _maxSearchRadiusKm) {
          return false;
        }

        // --------------------------------------------------------
        // Existing incoming claim
        // --------------------------------------------------------

        final String incomingWalkerUid =
            data['incomingWalkerUid']
                    ?.toString()
                    .trim() ??
                '';

        if (incomingWalkerUid == uid) {
          // ------------------------------------------------------
          // Same Walker already owns this offer.
          // ------------------------------------------------------

          if (_isOfferExpired(data)) {
            return false;
          }

          return true;
        }

        if (incomingWalkerUid.isNotEmpty &&
            incomingWalkerUid != uid) {
          // Another Walker currently owns this offer.
          return false;
        }

        // --------------------------------------------------------
        // Fresh claim
        // --------------------------------------------------------

        transaction.update(
          walkRef,
          <String, dynamic>{
            'incomingWalkerUid':
                uid,
            'incomingWalkerId':
                wid,
            'incomingClaimedAt':
                FieldValue.serverTimestamp(),
            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );

        return true;
      },
    );
  }

  // ============================================================
  // PENDING REQUEST STREAM
  // ============================================================

  Stream<List<InstaWalkRequest>>
      pendingRequestsStream() {
    return Stream.multi(
      (
        MultiStreamController<
                List<InstaWalkRequest>>
            controller,
      ) {
        StreamSubscription<User?>?
            authSubscription;

        StreamSubscription<
                QuerySnapshot<
                    Map<String, dynamic>>>?
            requestSubscription;

        bool disposed = false;
        bool startingListener = false;
        int generation = 0;

        // --------------------------------------------------------
        // STOP FIRESTORE LISTENER
        // --------------------------------------------------------

        Future<void> stopRequestListener() async {
          final StreamSubscription<
                  QuerySnapshot<
                      Map<String, dynamic>>>?
              subscription =
              requestSubscription;

          requestSubscription = null;

          if (subscription != null) {
            await subscription.cancel();
          }
        }

        // --------------------------------------------------------
        // EMPTY
        // --------------------------------------------------------

        void emitEmpty() {
          if (disposed) {
            return;
          }

          controller.add(
            <InstaWalkRequest>[],
          );
        }

        // --------------------------------------------------------
        // START FIRESTORE LISTENER
        // --------------------------------------------------------

        Future<void> startRequestListener(
          User user,
        ) async {
          if (disposed ||
              startingListener) {
            return;
          }

          startingListener = true;

          final int currentGeneration =
              ++generation;

          try {
            await stopRequestListener();

            if (disposed ||
                currentGeneration !=
                    generation) {
              return;
            }

            // ----------------------------------------------------
            // Wait for availability restoration.
            // ----------------------------------------------------

            await _availabilityService.ready;

            if (disposed ||
                currentGeneration !=
                    generation) {
              return;
            }

            if (!_canReceiveInstaWalkRequests()) {
              emitEmpty();
              return;
            }

            final String walkerUid =
                user.uid.trim();

            if (walkerUid.isEmpty) {
              emitEmpty();
              return;
            }

            final String? walkerId =
                await getCurrentWalkerId();

            if (disposed ||
                currentGeneration !=
                    generation) {
              return;
            }

            if (!_canReceiveInstaWalkRequests()) {
              emitEmpty();
              return;
            }

            if (walkerId == null ||
                walkerId.trim().isEmpty) {
              emitEmpty();
              return;
            }

            final String cleanWalkerId =
                walkerId.trim();

            // ----------------------------------------------------
            // SEARCHING REQUESTS
            // ----------------------------------------------------

            requestSubscription =
                _walkRequests
                    .where(
                      'status',
                      isEqualTo:
                          'searching',
                    )
                    .snapshots()
                    .listen(
                  (
                    QuerySnapshot<
                            Map<String, dynamic>>
                        snapshot,
                  ) async {
                    if (disposed ||
                        currentGeneration !=
                            generation) {
                      return;
                    }

                    if (!_canReceiveInstaWalkRequests()) {
                      emitEmpty();
                      return;
                    }

                    final List<
                            InstaWalkRequest>
                        availableRequests =
                        <InstaWalkRequest>[];

                    for (
                      final QueryDocumentSnapshot<
                              Map<String, dynamic>>
                          doc
                          in snapshot.docs
                    ) {
                      if (disposed ||
                          currentGeneration !=
                              generation) {
                        return;
                      }

                      if (!_canReceiveInstaWalkRequests()) {
                        emitEmpty();
                        return;
                      }

                      final Map<String, dynamic>
                          data =
                          doc.data();

                      // ------------------------------------------------
                      // Existing claim by this Walker
                      // ------------------------------------------------

                      final String incomingWalkerUid =
                          data['incomingWalkerUid']
                                  ?.toString()
                                  .trim() ??
                              '';

                      if (incomingWalkerUid ==
                          walkerUid) {
                        final DateTime? claimedAt =
                            _getOfferStartedAt(
                          data,
                        );

                        // ------------------------------------------------
                        // Already expired
                        // ------------------------------------------------

                        if (_isOfferExpired(
                          data,
                        )) {
                          await _markTimeout(
                            walkId: doc.id,
                            walkerId:
                                cleanWalkerId,
                            walkerUid:
                                walkerUid,
                          );

                          _cancelOfferTimer(
                            doc.id,
                          );

                          continue;
                        }

                        // ------------------------------------------------
                        // Restore timer from Firestore timestamp.
                        // ------------------------------------------------

                        _scheduleOfferTimeout(
                          walkId: doc.id,
                          walkerId:
                              cleanWalkerId,
                          walkerUid:
                              walkerUid,
                          claimedAt:
                              claimedAt,
                        );
                      }

                      // ------------------------------------------------
                      // Distance filter
                      // ------------------------------------------------

                      if (!_isWithinSearchRadius(
                        data,
                      )) {
                        continue;
                      }

                      // ------------------------------------------------
                      // Claim
                      // ------------------------------------------------

                      final bool claimed =
                          await _claimIncomingRequest(
                        walkId: doc.id,
                        walkerUid:
                            walkerUid,
                        walkerId:
                            cleanWalkerId,
                      );

                      if (disposed ||
                          currentGeneration !=
                              generation) {
                        return;
                      }

                      if (!_canReceiveInstaWalkRequests()) {
                        emitEmpty();
                        return;
                      }

                      if (!claimed) {
                        continue;
                      }

                      // ------------------------------------------------
                      // Read server timestamp written by Firestore.
                      // ------------------------------------------------

                      final DocumentSnapshot<
                              Map<String, dynamic>>
                          latestSnapshot =
                          await _walkRequests
                              .doc(doc.id)
                              .get();

                      if (disposed ||
                          currentGeneration !=
                              generation) {
                        return;
                      }

                      if (!_canReceiveInstaWalkRequests()) {
                        emitEmpty();
                        return;
                      }

                      if (!latestSnapshot.exists) {
                        continue;
                      }

                      final Map<String, dynamic>?
                          latestData =
                          latestSnapshot.data();

                      if (latestData == null) {
                        continue;
                      }

                      final String latestStatus =
                          latestData['status']
                                  ?.toString()
                                  .trim()
                                  .toLowerCase() ??
                              '';

                      final String latestWalkerUid =
                          latestData[
                                      'incomingWalkerUid']
                                  ?.toString()
                                  .trim() ??
                              '';

                      if (latestStatus !=
                              'searching' ||
                          latestWalkerUid !=
                              walkerUid) {
                        continue;
                      }

                      // ------------------------------------------------
                      // Start exact remaining timer using the
                      // server timestamp if available.
                      // ------------------------------------------------

                      final DateTime? latestClaimedAt =
                          _getOfferStartedAt(
                        latestData,
                      );

                      _scheduleOfferTimeout(
                        walkId: doc.id,
                        walkerId:
                            cleanWalkerId,
                        walkerUid:
                            walkerUid,
                        claimedAt:
                            latestClaimedAt,
                      );

                      availableRequests.add(
                        InstaWalkRequest.fromFirestore(
                          latestSnapshot,
                        ),
                      );

                      // One request at a time.
                      break;
                    }

                    if (disposed ||
                        currentGeneration !=
                            generation) {
                      return;
                    }

                    if (!_canReceiveInstaWalkRequests()) {
                      emitEmpty();
                      return;
                    }

                    if (availableRequests
                        .isEmpty) {
                      emitEmpty();
                      return;
                    }

                    controller.add(
                      <InstaWalkRequest>[
                        availableRequests.first,
                      ],
                    );
                  },
                  onError: (
                    Object error,
                    StackTrace stackTrace,
                  ) {
                    if (disposed ||
                        currentGeneration !=
                            generation) {
                      return;
                    }

                    debugPrint(
                      'Incoming Walk Firestore stream error: '
                      '$error',
                    );

                    debugPrintStack(
                      stackTrace: stackTrace,
                    );
                  },
                );
          } finally {
            startingListener = false;
          }
        }

        // --------------------------------------------------------
        // AVAILABILITY CHANGE
        // --------------------------------------------------------

        void onAvailabilityChanged() {
          if (disposed) {
            return;
          }

          final User? user =
              _auth.currentUser;

          if (!_canReceiveInstaWalkRequests()) {
            generation++;

            unawaited(
              stopRequestListener(),
            );

            emitEmpty();
            return;
          }

          if (user == null) {
            generation++;

            unawaited(
              stopRequestListener(),
            );

            emitEmpty();
            return;
          }

          unawaited(
            startRequestListener(user),
          );
        }

        // --------------------------------------------------------
        // AUTH CHANGE
        // --------------------------------------------------------

        authSubscription =
            _auth.authStateChanges().listen(
          (User? user) {
            if (disposed) {
              return;
            }

            generation++;

            unawaited(
              stopRequestListener(),
            );

            if (user == null) {
              emitEmpty();
              return;
            }

            unawaited(
              startRequestListener(user),
            );
          },
        );

        // --------------------------------------------------------
        // AVAILABILITY LISTENER
        // --------------------------------------------------------

        _availabilityService.addListener(
          onAvailabilityChanged,
        );

        // --------------------------------------------------------
        // INITIAL START
        // --------------------------------------------------------

        unawaited(
          () async {
            await _availabilityService.ready;

            if (disposed) {
              return;
            }

            final User? user =
                _auth.currentUser;

            if (user == null) {
              emitEmpty();
              return;
            }

            if (!_canReceiveInstaWalkRequests()) {
              emitEmpty();
              return;
            }

            await startRequestListener(user);
          }(),
        );

        // --------------------------------------------------------
        // CLEANUP
        // --------------------------------------------------------

        controller.onCancel = () async {
          if (disposed) {
            return;
          }

          disposed = true;
          generation++;

          // Cancel every active 3-minute offer timer.
          for (final Timer timer
              in _offerTimers.values) {
            timer.cancel();
          }

          _offerTimers.clear();

          _availabilityService
              .removeListener(
            onAvailabilityChanged,
          );

          await authSubscription?.cancel();

          await stopRequestListener();
        };
      },
      isBroadcast: true,
    );
  }

  // ============================================================
  // GET SINGLE WALK REQUEST
  // ============================================================

  Future<InstaWalkRequest?>
      getWalkRequest(
    String walkId,
  ) async {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return null;
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _walkRequests.doc(id).get();

    if (!snapshot.exists) {
      return null;
    }

    return InstaWalkRequest.fromFirestore(
      snapshot,
    );
  }

  // ============================================================
  // NUMBER HELPER
  // ============================================================

  double? _toDouble(
    dynamic value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString().trim(),
    );
  }

  // ============================================================
  // PUBLIC CONFIGURATION
  // ============================================================

  double get maxSearchRadiusKm {
    return _maxSearchRadiusKm;
  }

  Duration get offerDuration {
    return _offerDuration;
  }
}
