// File:
// lib/features/insta_walk/services/insta_walk_accept_service.dart

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

import '../../../services/walker_location_service.dart';
import '../../walks/services/walk_request_sound_service.dart';

/// ============================================================
/// INSTA WALK ACCEPT SERVICE
///
/// Firestore:
///
///   walk_request/{walkId}
///
/// Accept:
///
///   searching → accepted
///
/// After successful accept:
///
///   GPS tracking starts
///   walkerLocation is continuously written to Firestore
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
  // ============================================================

  Future<void> acceptWalk(
    String walkId,
  ) async {
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

    final String walkerId =
        await getCurrentWalkerId();

    final String id =
        walkId.trim();

    if (id.isEmpty) {
      throw Exception(
        'Walk ID is missing.',
      );
    }

    final DocumentReference<
            Map<String, dynamic>>
        walkRef =
        _walkRequests.doc(id);

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
    // START WALKER GPS
    // ==========================================================

    try {
      await _startLocationTracking(
        walkId: id,
      );
    } catch (e) {
      // Accept already succeeded.
      // GPS failure must not undo the accept.

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
    // CANCEL PREVIOUS FIRESTORE LOCATION LISTENER
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
    // GET FIRST LOCATION
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
    // CONTINUOUS LOCATION
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
  // WRITE WALKER LOCATION
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

    if (_trackingWalkId != id) {
      return;
    }

    try {
      await _walkRequests
          .doc(id)
          .update(
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
      // GPS stream should continue even if one
      // Firestore update fails.

      // ignore: avoid_print
      print(
        'Unable to update walker location: $e',
      );
    }
  }

  // ============================================================
  // STOP LOCATION TRACKING
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
