// File:
// lib/features/insta_walk/services/insta_walk_accept_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../services/walker_location_service.dart';
import '../../walks/services/walk_request_sound_service.dart';

/// ============================================================
/// INSTA WALK ACCEPT SERVICE
///
/// Firestore:
///
///   walk_request/{walkId}
///
/// Accept flow:
///
///   searching → accepted
///
/// After successful accept:
///
///   1. Walker GPS tracking starts.
///   2. Current GPS position is written to walk_request.
///   3. Continuous GPS updates are written to walk_request.
///
/// Location fields:
///
///   walkerLocation
///   walkerHeading
///   walkerSpeed
///   locationUpdatedAt
///   updatedAt
///
/// Rejection:
///
///   walk_request/{walkId}/rejections/{walkerId}
///
/// ============================================================

class InstaWalkAcceptService {
  InstaWalkAcceptService._();

  static final InstaWalkAcceptService instance =
      InstaWalkAcceptService._();

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final WalkerLocationService _locationService =
      WalkerLocationService.instance;

  StreamSubscription<Position>? _locationSubscription;

  String? _trackingWalkId;

  // ============================================================
  // COLLECTION
  // ============================================================

  CollectionReference<Map<String, dynamic>>
      get _walkRequests {
    return _firestore.collection('walk_request');
  }

  // ============================================================
  // CURRENT USER
  // ============================================================

  User? get _currentUser {
    return _auth.currentUser;
  }

  // ============================================================
  // CURRENT WALKER ID
  // ============================================================

  Future<String> getCurrentWalkerId() async {
    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    final DocumentSnapshot<
            Map<String, dynamic>>
        snapshot =
        await _firestore
            .collection('walkers')
            .doc(walkerUid)
            .get();

    if (!snapshot.exists) {
      throw Exception(
        'Walker profile not found.',
      );
    }

    final Map<String, dynamic>? data =
        snapshot.data();

    if (data == null) {
      throw Exception(
        'Walker profile data is empty.',
      );
    }

    final String walkerId =
        data['walkerId']
                ?.toString()
                .trim() ??
            '';

    if (walkerId.isEmpty) {
      throw Exception(
        'Walker ID not found in walkers collection.',
      );
    }

    return walkerId;
  }

  // ============================================================
  // ACCEPT WALK
  //
  // searching → accepted
  // ============================================================

  Future<void> acceptWalk(
    String walkId,
  ) async {
    // ==========================================================
    // AUTH
    // ==========================================================

    final User? user = _currentUser;

    if (user == null) {
      throw Exception(
        'Walker is not logged in.',
      );
    }

    final String walkerUid =
        user.uid.trim();

    if (walkerUid.isEmpty) {
      throw Exception(
        'Walker UID is missing.',
      );
    }

    // ==========================================================
    // WALKER BUSINESS ID
    // ==========================================================

    final String walkerId =
        await getCurrentWalkerId();

    // ==========================================================
    // WALK ID
    // ==========================================================

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    // ==========================================================
    // MAIN WALK DOCUMENT
    // ==========================================================

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

    // ==========================================================
    // REJECTION DOCUMENT
    // ==========================================================

    final DocumentReference<
            Map<String, dynamic>>
        rejectionRef =
        walkRef
            .collection('rejections')
            .doc(walkerId);

    // ==========================================================
    // ACCEPT TRANSACTION
    // ==========================================================

    await _firestore.runTransaction(
      (
        Transaction transaction,
      ) async {
        // ------------------------------------------------------
        // READ REQUEST
        // ------------------------------------------------------

        final DocumentSnapshot<
                Map<String, dynamic>>
            walkSnapshot =
            await transaction.get(
          walkRef,
        );

        if (!walkSnapshot.exists) {
          throw Exception(
            'Walk request no longer exists.',
          );
        }

        final Map<String, dynamic>? data =
            walkSnapshot.data();

        if (data == null) {
          throw Exception(
            'Walk request data is empty.',
          );
        }

        // ------------------------------------------------------
        // STATUS
        // ------------------------------------------------------

        final String status =
            data['status']
                    ?.toString()
                    .trim()
                    .toLowerCase() ??
                '';

        if (status != 'searching') {
          throw Exception(
            'This walk is no longer available.',
          );
        }

        // ------------------------------------------------------
        // CHECK PREVIOUS REJECTION
        // ------------------------------------------------------

        final DocumentSnapshot<
                Map<String, dynamic>>
            rejectionSnapshot =
            await transaction.get(
          rejectionRef,
        );

        if (rejectionSnapshot.exists) {
          throw Exception(
            'You already rejected this walk.',
          );
        }

        // ------------------------------------------------------
        // ACCEPT
        // ------------------------------------------------------

        transaction.update(
          walkRef,
          <String, dynamic>{
            'status': 'accepted',

            'walkerId': walkerId,

            'walkerUid': walkerUid,

            'acceptedBy': walkerId,

            'acceptedByUid': walkerUid,

            'acceptedAt':
                FieldValue.serverTimestamp(),

            'updatedAt':
                FieldValue.serverTimestamp(),
          },
        );
      },
    );

    // ==========================================================
    // ACCEPT SUCCESS
    // ==========================================================
    //
    // Firestore accept transaction is complete.
    //
    // Now start GPS.
    // ==========================================================

    try {
      await _startLocationTracking(
        walkId: id,
      );
    } catch (e) {
      // Accept already succeeded.
      //
      // GPS failure must not turn a successful accept
      // into a failed accept.

      // ignore: avoid_print
      print(
        'Unable to start walker location tracking: $e',
      );
    }

    // ==========================================================
    // STOP REQUEST SOUND
    // ==========================================================

    try {
      await WalkRequestSoundService
          .instance
          .stopRequest(id);
    } catch (e) {
      // Sound failure must not affect accepted walk.

      // ignore: avoid_print
      print(
        'Unable to stop walk request sound: $e',
      );
    }
  }

  // ============================================================
  // START LOCATION TRACKING
  // ============================================================

  Future<void> _startLocationTracking({
    required String walkId,
  }) async {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // STOP PREVIOUS FIRESTORE LOCATION LISTENER
    // ----------------------------------------------------------

    await _locationSubscription?.cancel();

    _locationSubscription = null;

    _trackingWalkId = id;

    // ----------------------------------------------------------
    // START GPS SERVICE
    // ----------------------------------------------------------

    final bool started =
        await _locationService.startTracking();

    if (!started) {
      throw Exception(
        _locationService.lastError ??
            'Unable to start walker GPS tracking.',
      );
    }

    // ----------------------------------------------------------
    // GET FIRST CURRENT LOCATION
    // ----------------------------------------------------------

    final Position? currentPosition =
        _locationService.currentPosition ??
            await _locationService.getCurrentLocation();

    if (currentPosition != null) {
      await _updateWalkerLocation(
        walkId: id,
        position: currentPosition,
      );
    }

    // ----------------------------------------------------------
    // LISTEN TO CONTINUOUS GPS UPDATES
    // ----------------------------------------------------------

    _locationSubscription =
        _locationService.locationStream.listen(
      (Position position) {
        unawaited(
          _updateWalkerLocation(
            walkId: id,
            position: position,
          ),
        );
      },
      onError: (Object error) {
        // ignore: avoid_print
        print(
          'Walker GPS stream error: $error',
        );
      },
      cancelOnError: false,
    );
  }

  // ============================================================
  // WRITE WALKER LOCATION TO FIRESTORE
  // ============================================================

  Future<void> _updateWalkerLocation({
    required String walkId,
    required Position position,
  }) async {
    final String id =
        walkId.trim();

    if (id.isEmpty) {
      return;
    }

    // ----------------------------------------------------------
    // PREVENT OLD WALK UPDATES
    // ----------------------------------------------------------

    if (_trackingWalkId != id) {
      return;
    }

    try {
      final DocumentReference<
              Map<String, dynamic>>
          walkRef =
          _walkRequests.doc(id);

      await walkRef.update(
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
    } catch (e) {
      // Do not crash GPS stream because one Firestore update
      // failed.

      // ignore: avoid_print
      print(
        'Unable to update walker location: $e',
      );
    }
  }

  // ============================================================
  // STOP FIRESTORE LOCATION LISTENER
  //
  // This does NOT change the walk status.
  //
  // It is only used when the GPS ownership is transferred
  // to LiveWalk.
  // ============================================================

  Future<void> stopLocationTracking() async {
    await _locationSubscription?.cancel();

    _locationSubscription = null;

    _trackingWalkId = null;

    await _locationService.stopTracking();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  Future<void> dispose() async {
    await stopLocationTracking();
  }
}
